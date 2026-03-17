const db = require('../src/config/db');

const TARGET_PHONES = ['8289876643', '8089485895'];

async function wipeData() {
    const client = await db.getClient();
    try {
        console.log(`Starting data wipe for phones: ${TARGET_PHONES.join(', ')}`);
        await client.query('BEGIN');

        // 1. Find User IDs
        const userRes = await client.query('SELECT id FROM users WHERE phone = ANY($1)', [TARGET_PHONES]);
        const userIds = userRes.rows.map(r => r.id);
        console.log(`Found ${userIds.length} users:`, userIds);

        // 2. Find Technician IDs
        const techRes = await client.query('SELECT id FROM technicians WHERE phone = ANY($1)', [TARGET_PHONES]);
        const techIds = techRes.rows.map(r => r.id);
        console.log(`Found ${techIds.length} technicians:`, techIds);

        if (userIds.length === 0 && techIds.length === 0) {
            console.log('No users or technicians found with these phone numbers.');
            await client.query('ROLLBACK');
            return;
        }

        // 3. Delete from Dependent Tables

        // Ratings (from user OR to tech)
        if (userIds.length > 0 || techIds.length > 0) {
            console.log('Deleting ratings...');
            await client.query(`
                DELETE FROM ratings 
                WHERE from_user_id = ANY($1) 
                   OR to_tech_id = ANY($2)
            `, [userIds, techIds]);
        }

        // Jobs (created by user OR assigned to tech)
        if (userIds.length > 0 || techIds.length > 0) {
            console.log('Deleting jobs...');
            // Note: If jobs reference services, that's fine. 
            // We need to delete references in reviews/ratings first (depend on jobs?).
            // Schema: ratings has job_id REFERENCES jobs(id).
            // So we must delete ratings first. (Done above)

            // Wait, ratings references jobs. 
            // If I delete jobs first, ratings might be deleted cascade? 
            // Schema didn't specify ON DELETE CASCADE for ratings->jobs.
            // So we must delete ratings referring to these jobs even if the rating wasn't FROM/TO our target users?
            // Actually, if we delete a job, we need to delete ALL ratings associated with that job.
            // My previous query only deleted ratings where user/tech was involved.
            // Proper order:
            // 1. Find all jobs involving these users/techs.
            // 2. Delete all ratings for those jobs.
            // 3. Delete the jobs.

            const jobsRes = await client.query(`
                SELECT id FROM jobs 
                WHERE user_id = ANY($1) OR technician_id = ANY($2)
            `, [userIds, techIds]);
            const jobIds = jobsRes.rows.map(r => r.id);
            console.log(`Found ${jobIds.length} jobs related to these accounts.`);

            if (jobIds.length > 0) {
                console.log('Deleting ratings and other job dependencies...');
                await client.query('DELETE FROM ratings WHERE job_id = ANY($1)', [jobIds]);
                // Any other table referencing jobs? None in the viewed schema.

                console.log('Deleting jobs...');
                await client.query('DELETE FROM jobs WHERE id = ANY($1)', [jobIds]);
            }
        }

        // Skill Sessions (tech only)
        if (techIds.length > 0) {
            console.log('Deleting skill sessions...');
            await client.query('DELETE FROM skill_sessions WHERE technician_id = ANY($1)', [techIds]);

            console.log('Deleting technician services...');
            await client.query('DELETE FROM technician_services WHERE technician_id = ANY($1)', [techIds]);
        }

        // 4. Delete Main Records
        if (userIds.length > 0) {
            console.log('Deleting users...');
            await client.query('DELETE FROM users WHERE id = ANY($1)', [userIds]);
        }

        if (techIds.length > 0) {
            console.log('Deleting technicians...');
            await client.query('DELETE FROM technicians WHERE id = ANY($1)', [techIds]);
        }

        await client.query('COMMIT');
        console.log('Data wipe completed successfully.');

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Data wipe failed:', error);
    } finally {
        client.release();
        process.exit();
    }
}

wipeData();
