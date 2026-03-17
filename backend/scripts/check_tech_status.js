const db = require('../src/config/db');

async function checkTechStatus() {
    try {
        console.log('Checking Technicians...');
        const result = await db.query('SELECT id, phone, verification_step, is_verified, is_banned FROM technicians ORDER BY created_at DESC');
        console.table(result.rows);
        process.exit(0);
    } catch (error) {
        console.error('Check failed:', error);
        process.exit(1);
    }
}

checkTechStatus();
