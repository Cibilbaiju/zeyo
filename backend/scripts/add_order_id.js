const db = require('../src/config/db');

async function migrate() {
    try {
        console.log('Adding order_id to jobs table...');
        await db.query(`
            ALTER TABLE jobs 
            ADD COLUMN IF NOT EXISTS order_id VARCHAR(50);
        `);
        console.log('Migration successful: order_id column added.');
        process.exit(0);
    } catch (e) {
        console.error('Migration failed:', e);
        process.exit(1);
    }
}

migrate();
