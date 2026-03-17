const db = require('../src/config/db');

const TARGET_PHONES = ['8289876643', '8089485895'];

async function verifyWipe() {
    const client = await db.getClient();
    try {
        console.log(`Verifying wipe for phones: ${TARGET_PHONES.join(', ')}`);

        // Check Users
        const userRes = await client.query('SELECT * FROM users WHERE phone = ANY($1)', [TARGET_PHONES]);
        if (userRes.rows.length > 0) {
            console.error('FAILURE: Found users still existing:', userRes.rows);
        } else {
            console.log('SUCCESS: No users found.');
        }

        // Check Technicians
        const techRes = await client.query('SELECT * FROM technicians WHERE phone = ANY($1)', [TARGET_PHONES]);
        if (techRes.rows.length > 0) {
            console.error('FAILURE: Found technicians still existing:', techRes.rows);
        } else {
            console.log('SUCCESS: No technicians found.');
        }

    } catch (error) {
        console.error('Verification failed:', error);
    } finally {
        client.release();
        process.exit();
    }
}

verifyWipe();
