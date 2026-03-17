const db = require('../src/config/db');

async function checkData() {
    try {
        console.log('Checking Skill Sessions...');
        const sessions = await db.query('SELECT * FROM skill_sessions');
        console.table(sessions.rows);

        console.log('\nChecking Technicians...');
        const techs = await db.query('SELECT id, phone, verification_step, is_banned FROM technicians');
        console.table(techs.rows);

        process.exit(0);
    } catch (error) {
        console.error('Check failed:', error);
        process.exit(1);
    }
}

checkData();
