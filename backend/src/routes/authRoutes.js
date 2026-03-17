const express = require('express');
const router = express.Router();
const authService = require('../services/authService');

router.post('/login', async (req, res) => {
    const { phone } = req.body;
    try {
        const result = await authService.sendOTP(phone);
        if (result.error) {
            return res.status(400).json(result);
        }
        res.json(result);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

router.post('/verify', async (req, res) => {
    const { phone, code, role } = req.body;
    try {
        const result = await authService.verifyOTP(phone, code, role);
        if (result.error) {
            return res.status(400).json(result);
        }
        res.json(result);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Admin Login Route
router.post('/admin/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        const result = await authService.loginAdmin(email, password);
        if (result.error) {
            return res.status(401).json(result);
        }
        res.json(result);
    } catch (e) {
        console.error('Admin route error:', e);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Debug Route to Create Admin
router.get('/admin/create-debug', async (req, res) => {
    try {
        const result = await authService.createDebugAdmin();
        res.json(result);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

module.exports = router;
