const db = require('../src/config/db');

async function migrate() {
    try {
        console.log('Starting migration v2...');

        // Add verification_step column
        await db.query(`
            ALTER TABLE technicians 
            ADD COLUMN IF NOT EXISTS verification_step VARCHAR(50) DEFAULT 'documents_pending';
        `);
        console.log('Added verification_step column');

        // Add is_verified column
        await db.query(`
            ALTER TABLE technicians 
            ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;
        `);
        console.log('Added is_verified column');

        console.log('Migration v2 complete!');
        process.exit(0);
    } catch (error) {
        console.error('Migration failed:', error);
        process.exit(1);
    }
}

migrate();
