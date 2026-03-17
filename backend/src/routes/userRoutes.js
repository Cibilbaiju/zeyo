const express = require('express');
const router = express.Router();
const db = require('../config/db');

// List all users
const auth = require('../middleware/auth');

// Get Current User (Me)
router.get('/me', auth, async (req, res) => {
    try {
        // Fetch fresh details from DB to ensure allow/ban status etc.
        const result = await db.query('SELECT id, name, phone, email, role, created_at FROM users WHERE id = $1', [req.user.id]);

        if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });

        res.json(result.rows[0]);
    } catch (e) {
        console.error('Me error:', e);
        res.status(500).json({ error: 'Failed to fetch profile' });
    }
});

router.get('/', async (req, res) => {
    try {
        const { limit = 50, offset = 0 } = req.query;
        // Basic list
        const result = await db.query('SELECT id, name, phone, email, role, created_at FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2', [limit, offset]);
        res.json(result.rows);
    } catch (e) {
        console.error('List users error:', e);
        res.status(500).json({ error: 'Failed to fetch users' });
    }
});

// Get user details
router.get('/:id', async (req, res) => {
    try {
        const result = await db.query('SELECT id, name, phone, email, role, created_at FROM users WHERE id = $1', [req.params.id]);
        if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
        res.json(result.rows[0]);
    } catch (e) {
        res.status(500).json({ error: 'Failed to fetch user' });
    }
});

module.exports = router;
