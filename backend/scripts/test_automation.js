const db = require('../src/config/db');
const { checkAndAutoApprove } = require('../src/services/decisionEngine');
const jwt = require('jsonwebtoken');

// Mock Data
const PHONE = '9999999999';
const SERVICE_ID = 'uuid-placeholder'; // Will fetch dynamically

async function runTest() {
    const client = await db.getClient();
    try {
        console.log('--- STARTING AUTOMATION TEST ---');

        // 1. Setup: Clean up previous test
        await client.query("DELETE FROM technicians WHERE phone = $1", [PHONE]);

        // 2. Register new Technician
        console.log('1. Registering Technician...');
        const regRes = await client.query(
            "INSERT INTO technicians (phone, name) VALUES ($1, 'Test Bot') RETURNING id",
            [PHONE]
        );
        const techId = regRes.rows[0].id;
        console.log(`   Created Tech: ${techId}`);

        // Get Service ID
        const srvRes = await client.query("SELECT id FROM services LIMIT 1");
        const serviceId = srvRes.rows[0].id;

        // 3. Submit Quiz (Pass)
        console.log('2. Submitting Quiz (Score: 90%)...');
        await client.query(
            "INSERT INTO provider_assessments (technician_id, service_id, score, total_questions, correct_answers, status) VALUES ($1, $2, 90, 10, 9, 'pass')",
            [techId, serviceId]
        );

        // 4. Upload Video
        console.log('3. Uploading Video...');
        await client.query(
            "INSERT INTO verification_videos (technician_id, video_url, duration_seconds, status) VALUES ($1, 'http://test.com/video.mp4', 45, 'valid')",
            [techId]
        );

        // 5. Upload Docs (Trigger Mock OCR)
        console.log('4. Uploading Docs (Mock OCR)...');
        await client.query(
            "UPDATE technicians SET verification_step = 'documents_submitted', ocr_confidence = 95.0, face_match_confidence = 98.0 WHERE id = $1",
            [techId]
        );

        // 6. Run Decision Engine
        console.log('5. Running Decision Engine...');
        const status = await checkAndAutoApprove(techId);
        console.log('   Status:', status);

        // 7. Verify Final State
        const finalRes = await client.query("SELECT is_verified, verification_step, auto_verification_status FROM technicians WHERE id = $1", [techId]);
        const finalTech = finalRes.rows[0];

        console.log('--- RESULT ---');
        console.log('Is Verified:', finalTech.is_verified);
        console.log('Step:', finalTech.verification_step);
        console.log('Auto Status:', finalTech.auto_verification_status);

        if (finalTech.is_verified && finalTech.verification_step === 'verified') {
            console.log('SUCCESS: Technician automatically verified!');
        } else {
            console.error('FAILURE: Technician NOT verified.');
            process.exit(1);
        }

    } catch (e) {
        console.error('Test Failed:', e);
        process.exit(1);
    } finally {
        client.release();
        process.exit(0);
    }
}

runTest();
