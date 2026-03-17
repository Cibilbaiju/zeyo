const db = require('../src/config/db');

const services = [
    { name: 'Plumbing', category: 'Home', base_price: 50.00 },
    { name: 'Electrician', category: 'Home', base_price: 50.00 },
    { name: 'Painting', category: 'Home', base_price: 200.00 },
    { name: 'Tree Cutting', category: 'Garden', base_price: 150.00 },
    { name: 'Scanning', category: 'Office', base_price: 30.00 },
    { name: 'Carpentry', category: 'Home', base_price: 80.00 },
];

async function seed() {
    try {
        console.log('Seeding services...');

        // Clear existing services? Or just upsert?
        // For development syncing, let's truncate (be careful in prod, but this is dev)
        await db.query('TRUNCATE TABLE services CASCADE');
        console.log('Cleared existing services.');

        for (const s of services) {
            await db.query(
                'INSERT INTO services (name, category, base_price) VALUES ($1, $2, $3)',
                [s.name, s.category, s.base_price]
            );
            console.log(`Added ${s.name}`);
        }

        console.log('Seeding complete.');
        process.exit(0);
    } catch (e) {
        console.error('Seeding failed:', e);
        process.exit(1);
    }
}

seed();
