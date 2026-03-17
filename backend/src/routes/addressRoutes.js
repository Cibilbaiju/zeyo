const express = require('express');
const router = express.Router();
const db = require('../config/db');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

// Middleware
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

// GET /api/addresses
router.get('/', authenticate, async (req, res) => {
    try {
        const result = await db.query(
            'SELECT * FROM addresses WHERE user_id = $1 ORDER BY created_at DESC',
            [req.user.id]
        );
        res.json(result.rows);
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to fetch addresses' });
    }
});

// POST /api/addresses
router.post('/', authenticate, async (req, res) => {
    const { label, address_line, house_floor, apartment_area, directions, latitude, longitude } = req.body;
    try {
        const result = await db.query(
            `INSERT INTO addresses 
            (user_id, label, address_line, house_floor, apartment_area, directions, latitude, longitude) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
            RETURNING *`,
            [req.user.id, label, address_line, house_floor, apartment_area, directions, latitude, longitude]
        );
        res.json(result.rows[0]);
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to add address', details: e.message });
    }
});

// PUT /api/addresses/:id
router.put('/:id', authenticate, async (req, res) => {
    const { label, address_line, house_floor, apartment_area, directions, latitude, longitude } = req.body;
    try {
        const result = await db.query(
            `UPDATE addresses 
            SET label = $1, address_line = $2, house_floor = $3, apartment_area = $4, directions = $5, latitude = $6, longitude = $7
            WHERE id = $8 AND user_id = $9
            RETURNING *`,
            [label, address_line, house_floor, apartment_area, directions, latitude, longitude, req.params.id, req.user.id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Address not found or unauthorized' });
        }
        res.json(result.rows[0]);
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to update address' });
    }
});

// DELETE /api/addresses/:id
router.delete('/:id', authenticate, async (req, res) => {
    try {
        await db.query('DELETE FROM addresses WHERE id = $1 AND user_id = $2', [req.params.id, req.user.id]);
        res.json({ success: true });
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to delete address' });
    }
});

module.exports = router;
