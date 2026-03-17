const db = require('../src/config/db');

async function migrate() {
    try {
        console.log('Starting migration v3...');

        // Add was_previously_rejected column
        await db.query(`
            ALTER TABLE technicians 
            ADD COLUMN IF NOT EXISTS was_previously_rejected BOOLEAN DEFAULT FALSE;
        `);
        console.log('Added was_previously_rejected column');

        console.log('Migration v3 complete!');
        process.exit(0);
    } catch (error) {
        console.error('Migration failed:', error);
        process.exit(1);
    }
}

migrate();
