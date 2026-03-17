const db = require('../src/config/db');

async function migrate() {
    try {
        console.log('Starting migration v4...');

        // Add is_banned column
        await db.query(`
            ALTER TABLE technicians 
            ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE;
        `);
        console.log('Added is_banned column');

        console.log('Migration v4 complete!');
        process.exit(0);
    } catch (error) {
        console.error('Migration failed:', error);
        process.exit(1);
    }
}

migrate();
