const db = require('../src/config/db');
const bcrypt = require('bcryptjs');

async function seedAdmin() {
    try {
        console.log('Seeding admin user...');

        const email = 'admin@zeyo.com';
        const password = 'password123';
        const hashedPassword = await bcrypt.hash(password, 10);
        const phone = '+919999999999';

        // Check if admin exists
        const res = await db.query('SELECT * FROM users WHERE email = $1', [email]);
        if (res.rows.length > 0) {
            console.log('Admin user already exists.');
            process.exit(0);
        }

        // Insert admin
        await db.query(
            'INSERT INTO users (name, email, phone, password, role) VALUES ($1, $2, $3, $4, $5)',
            ['Admin User', email, phone, hashedPassword, 'admin']
        );

        console.log(`Admin user created: ${email} / ${password}`);
        process.exit(0);
    } catch (e) {
        console.error('Failed to seed admin:', e);
        process.exit(1);
    }
}

seedAdmin();
