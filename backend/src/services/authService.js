const twilio = require('twilio');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const bcrypt = require('bcryptjs');

const TWILIO_SID = process.env.TWILIO_SID;
const TWILIO_TOKEN = process.env.TWILIO_TOKEN;
const TWILIO_SERVICE_SID = process.env.TWILIO_SERVICE_SID;
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

let client;
try {
    if (TWILIO_SID && TWILIO_TOKEN) {
        // Log masked credentials for verification
        console.log(`[Auth] Initializing Twilio with SID starting: ${TWILIO_SID.substring(0, 4)}...`);
        console.log(`[Auth] Using Service SID starting: ${TWILIO_SERVICE_SID ? TWILIO_SERVICE_SID.substring(0, 4) : 'UNDEFINED'}...`);
        client = twilio(TWILIO_SID, TWILIO_TOKEN);
    } else {
        console.warn('[Auth] Twilio credentials missing. Running in mock mode.');
    }
} catch (err) {
    console.error('[Auth] Failed to initialize Twilio:', err.message);
}

class AuthService {
    /**
     * Send OTP to phone
     */
    async sendOTP(phone) {
        console.log(`[Auth] Received OTP request for: ${phone}`);
        // Strict Mock for specific test numbers
        const demoNumbers = ['8289876643', '+918289876643', '7510115195', '+917510115195', '9000000001', '+919000000001'];
        const isDemo = demoNumbers.some(num => phone.replace(/\s+/g, '').includes(num));

        if (isDemo) {
            console.log('MOCK OTP sent to:', phone);
            return { status: 'pending', sid: 'mock-sid-' + Date.now() };
        }

        // Must have Twilio client
        if (!client) {
            console.warn('[Auth] Twilio credentials missing. Cannot send real OTP.');
            return { error: 'SMS Service Unavailable' };
        }

        try {
            const verification = await client.verify.v2.services(TWILIO_SERVICE_SID)
                .verifications
                .create({ to: phone, channel: 'sms' });

            return verification;
        } catch (error) {
            console.error('[Twilio Error] Send OTP failed:', JSON.stringify(error, Object.getOwnPropertyNames(error)));
            return { error: error.message || 'Failed to send OTP', details: error };
        }
    }

    /**
     * Verify OTP and Login/Register
     */
    async verifyOTP(phone, code, role = 'user') {
        let isValid = false;

        // Mock verification for test numbers
        const demoNumbers = ['8289876643', '+918289876643', '7510115195', '+917510115195', '9000000001', '+919000000001'];
        const isDemo = demoNumbers.some(num => phone.replace(/\s+/g, '').includes(num));

        if (isDemo) {
            if (phone.includes('7510115195')) {
                isValid = (code === '678900');
            } else {
                isValid = (code === '123456');
            }
        } else {
            // Real Twilio verification
            if (!client) {
                return { error: 'SMS Service Unavailable' };
            }
            try {
                const verificationCheck = await client.verify.v2.services(TWILIO_SERVICE_SID)
                    .verificationChecks
                    .create({ to: phone, code });
                isValid = verificationCheck.status === 'approved';
            } catch (e) {
                console.error('Twilio Error:', e);
                return { error: 'Invalid Code' };
            }
        }

        if (!isValid) return { error: 'Invalid OTP' };


        // Check if user exists, else create
        let user;
        const table = role === 'technician' ? 'technicians' : 'users';

        const res = await db.query(`SELECT * FROM ${table} WHERE phone = $1`, [phone]);

        if (res.rows.length > 0) {
            user = res.rows[0];

            if (user.is_banned) {
                return { error: 'Your account has been banned.' };
            }


            // Re-application Logic: If previously rejected, reset status to allow fresh start
            if (role === 'technician' && user.verification_step === 'rejected') {
                console.log(`[Auth] Rejected technician ${user.id} re-logging. Resetting status.`);
                await db.query(`
                    UPDATE technicians 
                    SET verification_step = 'pending', was_previously_rejected = true 
                    WHERE id = $1
                `, [user.id]);
                // Update local user object
                user.verification_step = 'pending';
                user.was_previously_rejected = true;
            }

        } else {
            // Register new
            const insert = await db.query(
                `INSERT INTO ${table} (phone) VALUES ($1) RETURNING *`,
                [phone]
            );
            user = insert.rows[0];
        }

        // Generate JWT
        const token = jwt.sign(
            { id: user.id, role, phone: user.phone },
            JWT_SECRET,
            { expiresIn: '30d' }
        );

        // Check for services if role is technician
        let has_services = false;
        if (role === 'technician') {
            const servicesRes = await db.query(
                `SELECT 1 FROM technician_services WHERE technician_id = $1 LIMIT 1`,
                [user.id]
            );
            has_services = servicesRes.rows.length > 0;
        }

        return { user, token, has_services };
    }

    /**
     * Admin Login with Email & Password
     */
    async loginAdmin(email, password) {
        try {
            console.log(`[Admin Login Attempt] Email: ${email}`);
            const res = await db.query('SELECT * FROM users WHERE email = $1', [email]);

            if (res.rows.length === 0) {
                console.log('[Admin Login] User not found');
                return { error: 'Invalid credentials' };
            }

            const user = res.rows[0];

            if (!user.password) {
                console.log('[Admin Login] Password not set');
                return { error: 'Password not set for this user' };
            }

            if (user.role !== 'admin' && user.role !== 'super_admin') {
                console.log(`[Admin Login] Invalid role: ${user.role}`);
                return { error: 'Unauthorized access' };
            }

            const isMatch = await bcrypt.compare(password, user.password);
            console.log(`[Admin Login] Password match result: ${isMatch}`);

            if (!isMatch) {
                return { error: 'Invalid credentials' };
            }

            // Generate JWT for admin
            const token = jwt.sign(
                { id: user.id, role: user.role, email: user.email },
                JWT_SECRET,
                { expiresIn: '1d' }
            );

            // Remove password from response
            delete user.password;

            return { user, token };
        } catch (error) {
            console.error('Admin Login Error:', error);
            return { error: 'Server error' };
        }
    }

    /**
     * Debug: Create Admin User manually
     */
    async createDebugAdmin() {
        const email = 'admin@zeyo.com';
        const phone = '+919999999999';
        const password = 'password123';

        try {
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(password, salt);

            // Check if exists by EMAIL
            const checkEmail = await db.query('SELECT * FROM users WHERE email = $1', [email]);

            let action = '';

            if (checkEmail.rows.length > 0) {
                action = 'Updated existing user (by email)';
                await db.query(`
                    UPDATE users 
                    SET password = $1, role = 'admin', phone = $3
                    WHERE email = $2
                `, [hashedPassword, email, phone]);
            } else {
                const checkPhone = await db.query('SELECT * FROM users WHERE phone = $1', [phone]);
                if (checkPhone.rows.length > 0) {
                    action = 'Updated existing user (by phone)';
                    await db.query(`
                        UPDATE users 
                        SET password = $1, role = 'admin', email = $3
                        WHERE phone = $2
                    `, [hashedPassword, phone, email]);
                } else {
                    action = 'Created new user';
                    await db.query(`
                        INSERT INTO users (name, email, password, role, phone)
                        VALUES ('Admin User', $1, $2, 'admin', $3)
                    `, [email, hashedPassword, phone]);
                }
            }
            return { success: true, action, email, password };
        } catch (e) {
            console.error('Debug Admin Creation Failed:', e);
            throw e;
        }
    }
}

module.exports = new AuthService();
