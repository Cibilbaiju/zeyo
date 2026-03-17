const db = require('./src/config/db');

async function checkProvider() {
    console.log('Checking provider status...');
    try {
        const res = await db.query("SELECT id, phone, is_verified, verification_step, auto_verification_status FROM technicians WHERE phone = '+919000000001'");
        if (res.rows.length === 0) {
            console.log('Provider not found!');
        } else {
            console.log('Provider Data:', JSON.stringify(res.rows[0], null, 2));
        }
    } catch (e) {
        console.error('Error:', e);
    } finally {
        process.exit();
    }
}

checkProvider();
