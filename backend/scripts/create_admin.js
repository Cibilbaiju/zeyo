const db = require('../src/config/db');
const bcrypt = require('bcryptjs');

async function createAdmin() {
    console.log('[Admin Script] Starting Admin Creation Process...');
    console.log('[Admin Script] Database URL:', process.env.DATABASE_URL ? 'Set' : 'Missing');

    try {
        const email = 'admin@zeyo.com';
        const phone = '+919999999999';
        const password = 'password123';
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Check if exists by EMAIL
        const checkEmail = await db.query('SELECT * FROM users WHERE email = $1', [email]);

        if (checkEmail.rows.length > 0) {
            console.log('[Admin Script] User with email exists. Updating password & role...');
            await db.query(`
                UPDATE users 
                SET password = $1, role = 'admin', phone = $3
                WHERE email = $2
            `, [hashedPassword, email, phone]);
        } else {
            // Check if exists by PHONE
            const checkPhone = await db.query('SELECT * FROM users WHERE phone = $1', [phone]);
            if (checkPhone.rows.length > 0) {
                console.log('[Admin Script] User with phone exists. Updating password, role & email...');
                await db.query(`
                    UPDATE users 
                    SET password = $1, role = 'admin', email = $3
                    WHERE phone = $2
                `, [hashedPassword, phone, email]);
            } else {
                console.log('[Admin Script] Creating new admin user...');
                await db.query(`
                    INSERT INTO users (name, email, password, role, phone)
                    VALUES ('Admin User', $1, $2, 'admin', $3)
                `, [email, hashedPassword, phone]);
            }
        }

        console.log('✅ [Admin Script] COMPLETED: Admin user ready.');
        console.log('Email:', email);
        console.log('Password:', password);
        process.exit(0);
    } catch (e) {
        console.error('❌ [Admin Script] FAILED:', e);
        process.exit(1);
    }
}

// Add a small delay to allow connection pool to init
setTimeout(createAdmin, 2000);
