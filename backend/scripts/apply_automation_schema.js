const fs = require('fs');
const path = require('path');
const db = require('../src/config/db');

async function applySchema() {
    try {
        console.log('Connecting to database...');
        const client = await db.getClient();

        console.log('Reading schema file...');
        const schemaPath = path.join(__dirname, '../src/models/automation_schema.sql');
        const schemaSql = fs.readFileSync(schemaPath, 'utf8');

        console.log('Applying schema...');
        await client.query('BEGIN');
        await client.query(schemaSql);
        await client.query('COMMIT');

        console.log('Schema applied successfully!');
        client.release();
        process.exit(0);
    } catch (error) {
        console.error('Error applying schema:', error);
        process.exit(1);
    }
}

applySchema();
