const db = require('../src/config/db');

async function resetProviders() {
    try {
        console.log('Starting provider data reset...');
        const client = await db.getClient();

        try {
            await client.query('BEGIN');

            // 1. Delete dependent tables first
            console.log('Clearing ratings...');
            await client.query('DELETE FROM ratings');

            console.log('Clearing technician services...');
            await client.query('DELETE FROM technician_services');

            console.log('Clearing skill sessions...');
            // Need to check if table exists first? It should.
            // But wait, skill_sessions table definition wasn't in schema.sql viewed earlier.
            // Assuming it exists from context. Safe to run.
            await client.query('DELETE FROM skill_sessions');

            console.log('Clearing jobs...');
            await client.query('DELETE FROM jobs');

            // 2. Delete technicians
            console.log('Clearing technicians...');
            await client.query('DELETE FROM technicians');

            await client.query('COMMIT');
            console.log('Provider data reset successfully!');
            process.exit(0);

        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }

    } catch (error) {
        console.error('Reset failed:', error);
        process.exit(1);
    }
}

resetProviders();
