const db = require('../src/config/db');

async function setupSimpleTable() {
    try {
        console.log('Creating skill_sessions table...');

        // Simple query
        await db.query(`
            CREATE TABLE IF NOT EXISTS skill_sessions (
                id SERIAL PRIMARY KEY,
                technician_id UUID REFERENCES technicians(id),
                scheduled_at TIMESTAMP NOT NULL,
                status VARCHAR(50) DEFAULT 'scheduled',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);

        console.log('Table created successfully');
        process.exit(0);
    } catch (err) {
        console.error('Error:', err);
        process.exit(1);
    }
}

setupSimpleTable();
