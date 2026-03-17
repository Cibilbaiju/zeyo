const fs = require('fs');
const path = require('path');
const db = require('../config/db');

async function runAutoMigration() {
    console.log('[Migration] Checking endpoint: Auto-migration started...');
    const client = await db.getClient();
    try {
        const schemaPath = path.join(__dirname, '../models/automation_schema.sql');
        if (!fs.existsSync(schemaPath)) {
            console.error('[Migration] Schema file not found:', schemaPath);
            return;
        }

        const schemaSql = fs.readFileSync(schemaPath, 'utf8');

        // Simple check: Try to query one of the new tables
        // Or just run the SQL since it uses IF NOT EXISTS

        await client.query('BEGIN');
        await client.query(schemaSql);
        await client.query('COMMIT');

        console.log('[Migration] Database schema applied successfully (if needed).');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('[Migration] Failed to apply schema:', error);
        // Don't kill the server, just log error, maybe it's already applied or permission issue
    } finally {
        client.release();
    }
}

module.exports = { runAutoMigration };
