const db = require('../config/db');

async function createTable() {
    try {
        await db.query(`
            CREATE TABLE IF NOT EXISTS addresses (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                label VARCHAR(50), 
                address_line TEXT NOT NULL,
                house_floor VARCHAR(100),
                apartment_area VARCHAR(100),
                directions TEXT,
                latitude DOUBLE PRECISION,
                longitude DOUBLE PRECISION,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log("Addresses table created successfully!");
    } catch (e) {
        console.error("Error creating table:", e);
    } finally {
        process.exit();
    }
}

createTable();
