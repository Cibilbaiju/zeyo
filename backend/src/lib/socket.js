const { Server } = require('socket.io');
const h3Redis = require('./h3Redis');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

let io;

const initSocket = (httpServer) => {
    io = new Server(httpServer, {
        cors: {
            origin: "*",
            methods: ["GET", "POST"]
        }
    });

    const logs = [];
    const log = (msg) => {
        const entry = `[${new Date().toISOString()}] ${msg}`;
        console.log(entry);
        logs.push(entry);
        if (logs.length > 50) logs.shift();
    };

    // Explicitly Attach to IO for external access
    io.getSocketLogs = () => logs;

    // Auth Middleware
    io.use((socket, next) => {
        const token = socket.handshake.auth.token;
        if (!token) return next(new Error('Authentication error'));

        jwt.verify(token, JWT_SECRET, (err, decoded) => {
            if (err) return next(new Error('Authentication error'));
            socket.user = decoded; // { id, role, phone }
            next();
        });
    });

    io.on('connection', (socket) => {
        log(`[Socket] User connected: ${socket.user.id} (${socket.user.role})`);

        // Join room based on ID for direct messaging
        socket.join(socket.user.id);
        log(`[Socket] DEBUG: Socket ${socket.id} joined room ${socket.user.id}`);

        /**
         * Technician Location Update
         * Payload: { lat, lng, status }
         */
        // Fetch verification status on connect and store in socket session
        require('../config/db').query("SELECT is_verified FROM technicians WHERE id = $1", [socket.user.id])
            .then(res => {
                if (res.rows.length > 0) {
                    socket.user.isVerified = res.rows[0].is_verified;
                }
            })
            .catch(e => console.error('Socket Verified Fetch Error', e));

        socket.on('technician:location', async (data) => {
            if (socket.user.role !== 'technician') return;

            const { lat, lng, status } = data;

            // 1. Fetch current verification and service status
            const db = require('../config/db');
            try {
                const techRes = await db.query(
                    "SELECT is_verified, (SELECT COUNT(*) FROM technician_services WHERE technician_id = $1) as service_count FROM technicians WHERE id = $1",
                    [socket.user.id]
                );

                const isVerified = techRes.rows[0]?.is_verified || false;
                const serviceCount = parseInt(techRes.rows[0]?.service_count || 0);

                // 2. AUTO-LINK SERVICES (DEV ONLY)
                // If tech has no services and we are in dev, link them to all for testing
                if (serviceCount === 0 && process.env.NODE_ENV === 'development') {
                    log(`[Socket] [DEV] Auto-linking Tech ${socket.user.id} to all services...`);
                    await db.query(
                        "INSERT INTO technician_services (technician_id, service_id) SELECT $1, id FROM services ON CONFLICT DO NOTHING",
                        [socket.user.id]
                    );
                }

                log(`[Socket] Tech Location Match: ID=${socket.user.id}, Lat=${lat}, Lng=${lng}, Status=${status}, Verified=${isVerified}`);

                // 3. Update Redis (H3 + Hash)
                await h3Redis.updateTechnicianLocation(
                    socket.user.id,
                    lat,
                    lng,
                    status,
                    isVerified
                );

                // 4. Update Postgres Status (for Dashboard)
                if (status === 'online') {
                    await db.query("UPDATE technicians SET is_online = true WHERE id = $1", [socket.user.id]);
                } else if (status === 'offline') {
                    await db.query("UPDATE technicians SET is_online = false WHERE id = $1", [socket.user.id]);
                }

                // Broadcast to Admins
                io.to('admin').emit('technician:moved', { id: socket.user.id, lat, lng, status, isVerified });
            } catch (err) {
                console.error('[Socket] Location handle error:', err);
            }
        });

        socket.on('join', (data) => {
            if (socket.user.role === 'admin' || socket.user.role === 'super_admin') {
                if (data.room === 'admin') {
                    socket.join('admin');
                    log(`[Socket] Admin ${socket.user.id} joined admin room`);
                }
            }
        });

        socket.on('job:update', async (data) => {
            const { jobId, userId, status } = data;

            // 1. Update Database
            try {
                if (status === 'accepted' || status === 'matched') {
                    await require('../config/db').query(
                        'UPDATE jobs SET status = $1, technician_id = $2 WHERE id = $3',
                        [status, socket.user.id, jobId]
                    );
                } else if (status === 'completed') {
                    await require('../config/db').query(
                        `UPDATE jobs 
                         SET status = $1, 
                             completed_at = NOW(), 
                             price_final = (SELECT s.base_price FROM services s WHERE s.id = jobs.service_id)
                         WHERE id = $2`,
                        [status, jobId]
                    );
                } else {
                    await require('../config/db').query(
                        'UPDATE jobs SET status = $1 WHERE id = $2',
                        [status, jobId]
                    );
                }
            } catch (e) {
                console.error('Socket DB update error:', e);
            }

            // 2. Forward to user room
            io.to(userId).emit('job:status', { jobId, status, technicianId: socket.user.id });

            // 3. Notify Admin
            io.to('admin').emit('job:updated', { jobId, status, technicianId: socket.user.id });
        });

        socket.on('disconnect', async () => {
            log(`[Socket] Disconnected: ${socket.user.id} (${socket.user.role})`);
            if (socket.user && socket.user.role === 'technician') {
                try {
                    await require('../config/db').query("UPDATE technicians SET is_online = false WHERE id = $1", [socket.user.id]);
                } catch (e) {
                    console.error('Disconnect DB update error:', e);
                }
            }
        });
    });

    return io;
};

const getIO = () => {
    if (!io) throw new Error("Socket.io not initialized!");
    return io;
};

const notifyTechnician = (techId, event, data) => {
    if (!io) return;
    io.to(techId).emit(event, data);
};

module.exports = { initSocket, getIO, notifyTechnician };
