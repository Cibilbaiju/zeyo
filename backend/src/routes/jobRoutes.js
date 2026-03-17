const express = require('express');
const router = express.Router();
const matchingService = require('../services/matchingService');
const db = require('../config/db');

// Middleware to check JWT would go here

router.post('/request', async (req, res) => {
    const { userId, serviceId, pickupLat, pickupLng, pickupAddress } = req.body;

    try {
        // Generate Order ID (e.g. #ORD-123456)
        const orderId = '#ORD-' + Math.floor(100000 + Math.random() * 900000);

        // 1. Create Job Entry
        const result = await db.query(
            `INSERT INTO jobs (user_id, service_id, pickup_lat, pickup_lng, pickup_address, status, order_id) 
             VALUES ($1, $2, $3, $4, $5, 'pending', $6) RETURNING *`,
            [userId, serviceId, pickupLat, pickupLng, pickupAddress || null, orderId]
        );

        const job = result.rows[0];

        // Fetch Service Details
        const serviceRes = await db.query('SELECT name, base_price FROM services WHERE id = $1', [serviceId]);
        const service = serviceRes.rows[0];

        // Fetch User Details (phone for provider call)
        const userRes = await db.query('SELECT phone, name FROM users WHERE id = $1', [userId]);
        const user = userRes.rows[0] || {};

        console.log('[Job Request] Payload:', req.body);

        // 2. Trigger Matching
        matchingService.findMatches({
            jobId: job.id,
            userId,
            serviceId, // Added missing serviceId
            pickupLat,
            pickupLng,
            pickupAddress: pickupAddress || null,
            serviceName: service ? service.name : 'Unknown Service',
            amount: service ? service.base_price : '0',
            orderId: job.order_id,
            userPhone: user.phone || null,
            userName: user.name || null,
        }).catch(err => console.error('Matching Error:', err));

        // 3. Notify Admin Dashboard
        try {
            const io = require('../lib/socket').getIO();
            io.to('admin').emit('job:created', job);
        } catch (e) {
            console.error('Socket emit error:', e.message);
        }

        res.json(job);
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to create job', details: e.message });
    }
});

// POST /api/jobs/accept
// Provider accepts a job - Generates 4-digit OTP
router.post('/accept', async (req, res) => {
    const { jobId, technicianId } = req.body;

    if (!jobId || !technicianId) {
        return res.status(400).json({ error: 'jobId and technicianId are required' });
    }

    try {
        // 1. Generate 4-digit OTP
        const otp = Math.floor(1000 + Math.random() * 9000).toString();

        // 2. Update job with technician, OTP, and status
        const result = await db.query(
            `UPDATE jobs 
             SET status = 'accepted', 
                 technician_id = $1, 
                 otp = $2,
                 accepted_at = NOW()
             WHERE id = $3 
             RETURNING *`,
            [technicianId, otp, jobId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }

        const job = result.rows[0];

        // 3. Get technician details
        const techResult = await db.query(
            'SELECT id, phone, name, rating, current_lat, current_lng FROM technicians WHERE id = $1',
            [technicianId]
        );
        const technician = techResult.rows[0] || {};

        // 4. Notify Customer via Socket
        try {
            const io = require('../lib/socket').getIO();

            // Emit to the user's room (userId)
            io.to(job.user_id).emit('job:update', {
                jobId: job.id,
                status: 'accepted',
                otp: otp,
                pin: otp, // Alias for frontend compatibility
                orderId: job.order_id,
                pickupLat: job.pickup_lat,
                pickupLng: job.pickup_lng,
                pickupAddress: job.pickup_address,
                technician: {
                    id: technician.id,
                    phone: technician.phone,
                    name: technician.name || 'Service Expert',
                    rating: parseFloat(technician.rating) || 5.0,
                    lat: technician.current_lat,
                    lng: technician.current_lng,
                    driverName: technician.name || 'Service Expert',
                    driverPhone: technician.phone,
                    driverRating: parseFloat(technician.rating) || 5.0,
                    vehicleNumber: 'ZEYO-001',
                    vehicleModel: 'Service Partner',
                }
            });

            // Notify Admin Dashboard
            io.to('admin').emit('job:updated', {
                jobId: job.id,
                status: 'accepted',
                technicianId
            });

            console.log(`[Job Accept] Job ${jobId} accepted by ${technicianId}, OTP: ${otp}`);
        } catch (socketErr) {
            console.error('Socket emit error:', socketErr.message);
        }

        // 5. Return success with OTP
        res.json({
            success: true,
            job: job,
            otp: otp,
            message: 'Job accepted successfully'
        });
    } catch (e) {
        console.error('Job accept error:', e);
        res.status(500).json({ error: 'Failed to accept job', details: e.message });
    }
});

// POST /api/jobs/verify-otp
// Provider verifies OTP on arrival -> start job
router.post('/verify-otp', async (req, res) => {
    const { jobId, technicianId, otp } = req.body;

    if (!jobId || !technicianId || !otp) {
        return res.status(400).json({ error: 'jobId, technicianId, and otp are required' });
    }

    try {
        const result = await db.query(
            'SELECT id, user_id, technician_id, otp FROM jobs WHERE id = $1',
            [jobId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }

        const job = result.rows[0];

        if (job.technician_id && job.technician_id !== technicianId) {
            return res.status(403).json({ error: 'Technician mismatch' });
        }

        if ((job.otp || '').toString() !== otp.toString()) {
            return res.status(400).json({ error: 'Invalid OTP' });
        }

        const updated = await db.query(
            `UPDATE jobs 
             SET status = 'started', started_at = NOW()
             WHERE id = $1 RETURNING *`,
            [jobId]
        );

        const updatedJob = updated.rows[0];

        // Notify customer via socket
        try {
            const io = require('../lib/socket').getIO();
            io.to(updatedJob.user_id).emit('job:status', {
                jobId: updatedJob.id,
                status: 'started',
                technicianId: technicianId,
            });
            io.to('admin').emit('job:updated', {
                jobId: updatedJob.id,
                status: 'started',
                technicianId: technicianId,
            });
        } catch (socketErr) {
            console.error('Socket emit error:', socketErr.message);
        }

        res.json({ success: true, job: updatedJob });
    } catch (e) {
        console.error('OTP verify error:', e);
        res.status(500).json({ error: 'Failed to verify OTP', details: e.message });
    }
});

// POST /api/jobs/cancel
// Provider cancels a job
router.post('/cancel', async (req, res) => {
    const { jobId, technicianId, reason } = req.body;

    if (!jobId || !technicianId) {
        return res.status(400).json({ error: 'jobId and technicianId are required' });
    }

    try {
        const result = await db.query(
            'UPDATE jobs SET status = $1 WHERE id = $2 RETURNING *',
            ['cancelled', jobId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }

        const job = result.rows[0];

        // Notify customer via socket
        try {
            const io = require('../lib/socket').getIO();
            io.to(job.user_id).emit('job:status', {
                jobId: job.id,
                status: 'cancelled',
                technicianId: technicianId,
                reason: reason || 'cancelled_by_provider'
            });
            io.to('admin').emit('job:updated', {
                jobId: job.id,
                status: 'cancelled',
                technicianId: technicianId,
            });
        } catch (socketErr) {
            console.error('Socket emit error:', socketErr.message);
        }

        res.json({ success: true, job });
    } catch (e) {
        console.error('Job cancel error:', e);
        res.status(500).json({ error: 'Failed to cancel job', details: e.message });
    }
});

// POST /api/jobs/cancel-user
// User cancels a job
router.post('/cancel-user', async (req, res) => {
    const { jobId, userId, reason } = req.body;

    if (!jobId || !userId) {
        return res.status(400).json({ error: 'jobId and userId are required' });
    }

    try {
        const result = await db.query(
            'UPDATE jobs SET status = $1 WHERE id = $2 AND user_id = $3 RETURNING *',
            ['cancelled', jobId, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Job not found' });
        }

        const job = result.rows[0];

        // Notify provider if assigned
        try {
            const io = require('../lib/socket').getIO();
            if (job.technician_id) {
                io.to(job.technician_id).emit('job:status', {
                    jobId: job.id,
                    status: 'cancelled',
                    userId: userId,
                    reason: reason || 'cancelled_by_user'
                });
            }
            io.to('admin').emit('job:updated', {
                jobId: job.id,
                status: 'cancelled',
                userId: userId,
            });
        } catch (socketErr) {
            console.error('Socket emit error:', socketErr.message);
        }

        res.json({ success: true, job });
    } catch (e) {
        console.error('User cancel error:', e);
        res.status(500).json({ error: 'Failed to cancel job', details: e.message });
    }
});

// GET /api/jobs/stats
// Aggregate dashboard stats
router.get('/stats', async (req, res) => {
    try {
        const [revenue, activeUsers, activeJobs, activeProviders, recentSales] = await Promise.all([
            // Revenue: Sum of price_final for completed jobs
            db.query("SELECT SUM(price_final) as total FROM jobs WHERE status = 'completed'"),
            // Active Users
            db.query("SELECT COUNT(*) as count FROM users"),
            // Active Jobs (pending, matched, accepted, started)
            db.query("SELECT COUNT(*) as count FROM jobs WHERE status IN ('pending', 'matched', 'accepted', 'started')"),
            // Active Providers (technicians)
            db.query("SELECT COUNT(*) as count FROM technicians"),
            // Recent Sales (Last 5 completed jobs)
            db.query(`
                SELECT j.price_final as amount, u.name, u.email 
                FROM jobs j 
                JOIN users u ON j.user_id = u.id 
                WHERE j.status = 'completed' 
                ORDER BY j.completed_at DESC 
                LIMIT 5
             `)
        ]);

        res.json({
            revenue: revenue.rows[0].total || 0,
            activeUsers: parseInt(activeUsers.rows[0].count),
            activeJobs: parseInt(activeJobs.rows[0].count),
            activeProviders: parseInt(activeProviders.rows[0].count),
            recentSales: recentSales.rows
        });
    } catch (e) {
        console.error('Stats error:', e);
        res.status(500).json({ error: 'Failed to fetch stats' });
    }
});

// GET /api/jobs
// List all jobs (Admin)
router.get('/', async (req, res) => {
    try {
        const { limit = 50, offset = 0 } = req.query;
        const result = await db.query(`
            SELECT j.*, u.name as user_name, s.name as service_name 
            FROM jobs j
            LEFT JOIN users u ON j.user_id = u.id
            LEFT JOIN services s ON j.service_id = s.id
            ORDER BY j.created_at DESC
            LIMIT $1 OFFSET $2
        `, [limit, offset]);
        res.json(result.rows);
    } catch (e) {
        console.error('List jobs error:', e);
        res.status(500).json({ error: 'Failed to fetch jobs' });
    }
});

module.exports = router;
