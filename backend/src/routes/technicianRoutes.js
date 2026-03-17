const express = require('express');
const router = express.Router();
const db = require('../config/db');
const jwt = require('jsonwebtoken');
const { notifyTechnician } = require('../lib/socket');

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

// Middleware to verify token
const authenticate = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader) return res.status(401).json({ error: 'No token provided' });

    const token = authHeader.split(' ')[1];
    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) return res.status(401).json({ error: 'Invalid token' });
        req.user = decoded;
        next();
    });
};

// POST /api/technician/services
// Body: { serviceIds: ['uuid1', 'uuid2'] }
router.post('/services', authenticate, async (req, res) => {
    const { serviceIds } = req.body;
    const techId = req.user.id;

    if (!Array.isArray(serviceIds) || serviceIds.length === 0) {
        return res.status(400).json({ error: 'Please select at least one service' });
    }

    const client = await db.getClient();

    try {
        await client.query('BEGIN');

        // 1. Clear existing services (optional: or merge?) -> Decided to replace
        await client.query('DELETE FROM technician_services WHERE technician_id = $1', [techId]);

        // 2. Insert new services
        for (const serviceId of serviceIds) {
            await client.query(
                'INSERT INTO technician_services (technician_id, service_id) VALUES ($1, $2)',
                [techId, serviceId]
            );
        }

        await client.query('COMMIT');
        res.json({ success: true, message: 'Services updated successfully' });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error updating services:', error);
        res.status(500).json({ error: 'Failed to update services' });
    } finally {
        client.release();
    }
});

// GET /api/technician/skill-session (Current user's session)
router.get('/skill-session', authenticate, async (req, res) => {
    const techId = req.user.id;
    try {
        const result = await db.query(
            'SELECT * FROM skill_sessions WHERE technician_id = $1 ORDER BY scheduled_at DESC LIMIT 1',
            [techId]
        );
        res.json(result.rows[0] || null); // Return object or null
    } catch (error) {
        console.error('Error fetching my session:', error);
        res.status(500).json({ error: 'Failed to fetch session' });
    }
});

// POST /skill-session (Technician books session)
router.post('/skill-session', authenticate, async (req, res) => {
    const { scheduledAt } = req.body;
    const techId = req.user.id;

    if (!scheduledAt) {
        return res.status(400).json({ error: 'Scheduled time is required' });
    }

    // Generate Jitsi Meet Link
    // Format: https://meet.jit.si/ZeyoSkillSession_{UserUUID}_{Timestamp}
    const meetingLink = `https://meet.jit.si/ZeyoSkillSession_${techId}_${Date.now()}`;

    try {
        // Check if session exists
        const existing = await db.query(
            'SELECT * FROM skill_sessions WHERE technician_id = $1',
            [techId]
        );

        let result;
        if (existing.rows.length > 0) {
            // Update existing
            result = await db.query(
                `UPDATE skill_sessions 
                 SET scheduled_at = $1, status = 'scheduled', meeting_link = $3 
                 WHERE technician_id = $2 RETURNING *`,
                [scheduledAt, techId, meetingLink]
            );
        } else {
            // Insert new
            result = await db.query(
                `INSERT INTO skill_sessions (technician_id, scheduled_at, meeting_link, status) 
                 VALUES ($1, $2, $3, 'scheduled') RETURNING *`,
                [techId, scheduledAt, meetingLink]
            );
        }

        // Also update technician verification step
        await db.query(
            "UPDATE technicians SET verification_step = 'interview_scheduled' WHERE id = $1",
            [techId]
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error booking skill session:', error);
        res.status(500).json({ error: 'Failed to book session' });
    }
});

// GET /skill-sessions (Admin list)
router.get('/skill-sessions', async (req, res) => {
    try {
        const result = await db.query(`
            SELECT ss.*, t.name as technician_name, t.phone as technician_phone, t.verification_step, t.was_previously_rejected,
                   STRING_AGG(s.name, ', ') as service_names
            FROM skill_sessions ss
            JOIN technicians t ON ss.technician_id = t.id
            LEFT JOIN technician_services ts ON t.id = ts.technician_id
            LEFT JOIN services s ON ts.service_id = s.id
            GROUP BY ss.id, t.id
            ORDER BY ss.scheduled_at ASC
        `);
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching skill sessions:', error);
        res.status(500).json({ error: 'Failed to fetch sessions' });
    }
});

// POST /skill-session/:id/approve (Admin approves)
// Start a skill session (Admin)
router.post('/skill-session/:id/start', async (req, res) => {
    const { id } = req.params;
    try {
        const result = await db.query(
            "UPDATE skill_sessions SET status = 'ongoing' WHERE id = $1 RETURNING *",
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Session not found' });
        }

        const session = result.rows[0];

        // Notify Technician
        if (session.technician_id && session.meeting_link) {
            notifyTechnician(session.technician_id, 'call:incoming', {
                meetingLink: session.meeting_link,
                sessionId: session.id
            });
            console.log(`[Socket] Notified Tech ${session.technician_id} of Call Start`);
        }

        res.json(session);
    } catch (error) {
        console.error('Error starting session:', error);
        res.status(500).json({ error: 'Failed to start session' });
    }
});

router.post('/skill-session/:id/approve', async (req, res) => {
    const { id } = req.params;
    const client = await db.getClient();

    try {
        await client.query('BEGIN');

        // 1. Update Session Status
        const sessionRes = await client.query(
            "UPDATE skill_sessions SET status = 'approved' WHERE id = $1 RETURNING technician_id",
            [id]
        );

        if (sessionRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Session not found' });
        }

        const techId = sessionRes.rows[0].technician_id;

        // 2. Update Technician Verification Step and Official Status
        await client.query(
            "UPDATE technicians SET verification_step = 'interview_passed', is_verified = true WHERE id = $1",
            [techId]
        );

        await client.query('COMMIT');
        res.json({ success: true, message: 'Session approved' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error approving session:', error);
        res.status(500).json({ error: 'Failed to approve session' });
    } finally {
        client.release();
    }
});

// POST /skill-session/:id/waitlist (Admin puts on waitlist)
router.post('/skill-session/:id/waitlist', async (req, res) => {
    const { id } = req.params;
    const client = await db.getClient();

    try {
        await client.query('BEGIN');

        // 1. Update Session Status
        const sessionRes = await client.query(
            "UPDATE skill_sessions SET status = 'waitlist' WHERE id = $1 RETURNING technician_id",
            [id]
        );

        if (sessionRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Session not found' });
        }

        const techId = sessionRes.rows[0].technician_id;

        // 2. Update Technician Verification Step
        await client.query(
            "UPDATE technicians SET verification_step = 'waitlist' WHERE id = $1",
            [techId]
        );

        await client.query('COMMIT');
        res.json({ success: true, message: 'Session put on waitlist' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error updating session to waitlist:', error);
        res.status(500).json({ error: 'Failed to put session on waitlist' });
    } finally {
        client.release();
    }
});

// POST /skill-session/:id/reject (Admin rejects)
router.post('/skill-session/:id/reject', async (req, res) => {
    const { id } = req.params;
    const client = await db.getClient();

    try {
        await client.query('BEGIN');

        // 1. Update Session Status
        const sessionRes = await client.query(
            "UPDATE skill_sessions SET status = 'rejected' WHERE id = $1 RETURNING technician_id",
            [id]
        );

        if (sessionRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Session not found' });
        }

        const techId = sessionRes.rows[0].technician_id;

        // 2. Update Technician Verification Step
        await client.query(
            "UPDATE technicians SET verification_step = 'rejected' WHERE id = $1",
            [techId]
        );

        await client.query('COMMIT');
        res.json({ success: true, message: 'Session rejected' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error rejecting session:', error);
        res.status(500).json({ error: 'Failed to reject session' });
    } finally {
        client.release();
    }
});

// GET / (List all technicians - Admin)
router.get('/', async (req, res) => {
    try {
        const { limit = 50, offset = 0 } = req.query;
        const result = await db.query(`
            SELECT 
                t.*, 
                (SELECT COUNT(*) FROM technician_services ts WHERE ts.technician_id = t.id) as service_count 
            FROM technicians t 
            ORDER BY t.created_at DESC 
            LIMIT $1 OFFSET $2
        `, [limit, offset]);
        res.json(result.rows);
    } catch (e) {
        console.error('List technicians error:', e);
        res.status(500).json({ error: 'Failed to fetch technicians' });
    }
});

// Configure Multer
const multer = require('multer');
const path = require('path');
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });

// POST /upload-documents (Provider uploads docs)
router.post('/upload-documents', authenticate, upload.fields([
    { name: 'aadhaar', maxCount: 1 },
    { name: 'license', maxCount: 1 },
    { name: 'pan', maxCount: 1 },
    { name: 'photo', maxCount: 1 },
    { name: 'addressProof', maxCount: 1 }
]), async (req, res) => {
    const techId = req.user.id;
    const files = req.files; // Object with keys as fieldnames

    try {
        // Build update query dynamically
        let updateFields = [];
        let values = [];
        let index = 1;

        if (files.aadhaar) {
            updateFields.push(`document_aadhaar = $${index++}`);
            values.push(files.aadhaar[0].path);
        }
        if (files.license) {
            updateFields.push(`document_license = $${index++}`);
            values.push(files.license[0].path);
        }
        if (files.pan) {
            updateFields.push(`document_pan = $${index++}`);
            values.push(files.pan[0].path);
        }
        if (files.photo) {
            updateFields.push(`document_photo = $${index++}`);
            values.push(files.photo[0].path);
        }
        if (files.addressProof) {
            updateFields.push(`document_address_proof = $${index++}`);
            values.push(files.addressProof[0].path);
        }

        if (updateFields.length === 0) {
            return res.status(400).json({ error: 'No files uploaded' });
        }

        // Add verification step update
        updateFields.push(`verification_step = $${index++}`);
        values.push('documents_submitted');

        // Add technician_id
        values.push(techId);

        const query = `UPDATE technicians SET ${updateFields.join(', ')} WHERE id = $${index}`;

        await db.query(query, values);

        res.json({ success: true, message: 'Documents uploaded successfully' });

    } catch (error) {
        console.error('Error uploading documents:', error);
        res.status(500).json({ error: 'Failed to upload documents' });
    }
});

// GET /onboarding-candidates (Admin - Unverified)
router.get('/onboarding-candidates', async (req, res) => {
    try {
        const result = await db.query(`
            SELECT t.* 
            FROM technicians t 
            WHERE t.verification_step = 'documents_submitted' 
               OR t.verification_step = 'interview_passed'
            ORDER BY t.created_at DESC
        `);
        res.json(result.rows);
    } catch (e) {
        console.error('List onboarding candidates error:', e);
        res.status(500).json({ error: 'Failed to fetch candidates' });
    }
});

// GET /waitlist (Admin - Waitlisted)
router.get('/waitlist', async (req, res) => {
    try {
        // Fetch technicians who are explicitly on the waitlist
        const result = await db.query(`
            SELECT t.* 
            FROM technicians t 
            WHERE t.verification_step = 'waitlist'
            ORDER BY t.created_at DESC
        `);
        res.json(result.rows);
    } catch (e) {
        console.error('List waitlist error:', e);
        res.status(500).json({ error: 'Failed to fetch waitlist' });
    }
});

// GET /verified (Admin - Verified)
router.get('/verified', async (req, res) => {
    try {
        const result = await db.query(`
            SELECT t.*, 
                (SELECT COUNT(*) FROM technician_services ts WHERE ts.technician_id = t.id) as service_count 
            FROM technicians t 
            WHERE t.is_verified = true
            ORDER BY t.created_at DESC
        `);
        res.json(result.rows);
    } catch (e) {
        console.error('List verified technicians error:', e);
        res.status(500).json({ error: 'Failed to fetch verified technicians' });
    }
});

// POST /verify-documents/:id/approve
router.post('/verify-documents/:id/approve', async (req, res) => {
    const { id } = req.params;
    try {
        await db.query(
            "UPDATE technicians SET verification_step = 'verified', is_verified = true WHERE id = $1",
            [id]
        );
        res.json({ success: true, message: 'Technician verified successfully' });
    } catch (e) {
        console.error('Verify technician error:', e);
        res.status(500).json({ error: 'Failed to verify technician' });
    }
});

// POST /verify-documents/:id/reject
router.post('/verify-documents/:id/reject', async (req, res) => {
    const { id } = req.params;
    try {
        await db.query(
            "UPDATE technicians SET verification_step = 'rejected', is_verified = false, was_previously_rejected = true WHERE id = $1",
            [id]
        );
        // Also reject any active skill session just in case? Or assume skill session was already approved.
        // If we reject documents, we probably want to reset the whole flow or just ask for re-upload?
        // User said: "if it reject in the zeyosrv app it should be shown better luck next tile and automatically log out"
        // So sending back to rejected state (which triggers logout in app) is correct.

        res.json({ success: true, message: 'Technician rejected' });
    } catch (e) {
        console.error('Reject technician error:', e);
        res.status(500).json({ error: 'Failed to reject technician' });
    }
});

module.exports = router;
