const db = require('../src/config/db');
const bcrypt = require('bcryptjs');

async function migrate() {
    try {
        console.log('Migrating users table...');

        // Add password column if not exists
        await db.query(`
            DO $$ 
            BEGIN 
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='password') THEN 
                    ALTER TABLE users ADD COLUMN password VARCHAR(255); 
                END IF; 
            END $$;
        `);
        console.log('Added password column.');

        // Seed Admin
        const email = 'cibilbaiju@gmail.com';
        const password = 'cibil@#24';
        const hashedPassword = await bcrypt.hash(password, 10);
        const phone = '+919999999999'; // Dummy admin phone

        // Check if exists by email OR phone
        const check = await db.query('SELECT * FROM users WHERE email = $1 OR phone = $2', [email, phone]);

        if (check.rows.length === 0) {
            await db.query(
                'INSERT INTO users (name, email, phone, password, role) VALUES ($1, $2, $3, $4, $5)',
                ['Zeyo Admin', email, phone, hashedPassword, 'admin']
            );
            console.log('Created admin user.');
        } else {
            // Update password if exists
            await db.query(
                'UPDATE users SET password = $1, role = $2, email = $3 WHERE email = $3 OR phone = $4',
                [hashedPassword, 'admin', email, phone]
            );
            console.log('Updated admin user password/role.');
        }

        process.exit(0);
    } catch (e) {
        console.error('Migration failed:', e);
        process.exit(1);
    }
}

migrate();
