const express = require('express');
const router = express.Router();
const db = require('../config/db');

// GET /api/services
router.get('/', async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM services WHERE is_active = TRUE ORDER BY name ASC');
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching services:', error);
        res.status(500).json({ error: 'Failed to fetch services' });
    }
});

module.exports = router;
