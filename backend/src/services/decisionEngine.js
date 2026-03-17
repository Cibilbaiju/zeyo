const db = require('../config/db');

/**
 * Checks all verification steps for a technician and attempts to auto-approve.
 * @param {string} technicianId 
 */
async function checkAndAutoApprove(technicianId) {
    const client = await db.getClient();

    try {
        await client.query('BEGIN');

        // 1. Fetch Technician Data
        const techRes = await client.query(
            'SELECT * FROM technicians WHERE id = $1',
            [technicianId]
        );

        if (techRes.rows.length === 0) throw new Error('Technician not found');
        const tech = techRes.rows[0];

        // 2. Fetch Latest Assessment Status
        const assessmentRes = await client.query(
            'SELECT * FROM provider_assessments WHERE technician_id = $1 ORDER BY created_at DESC LIMIT 1',
            [technicianId]
        );
        const assessment = assessmentRes.rows[0];

        // 3. Fetch Latest Video Proof Status
        const videoRes = await client.query(
            'SELECT * FROM verification_videos WHERE technician_id = $1 ORDER BY created_at DESC LIMIT 1',
            [technicianId]
        );
        const video = videoRes.rows[0];

        // 4. Evaluate Rules

        // Rule 1: Skill Assessment Passed (Partial or Full)
        // Check if ANY service is verified
        const servicesCheck = await client.query(
            "SELECT COUNT(*) as verified_count FROM technician_services WHERE technician_id = $1 AND is_verified = true",
            [technicianId]
        );
        const verifiedCount = parseInt(servicesCheck.rows[0].verified_count);
        const isSkillPassed = verifiedCount > 0;

        // Also update the JSON status to reflect reality if needed, but the router usually handles it.
        // We'll trust the router updated the JSON, or we can force update here.
        // Let's rely on isSkillPassed for the decision.

        // Rule 2: Video Proof Valid
        // For MVP, we might just check if it's uploaded (pending) or valid.
        // Let's assume 'pending' is NOT enough for auto-approval unless we have an AI video analyzer.
        // The prompt says: "Flag only missing, blank, or irrelevant videos".
        // If we don't have AI video analysis, we might need a manual step here OR we trust the upload for now/use a mock validator.
        // Let's assume we need at least one video uploaded.
        // If the status is 'invalid', fail. If 'pending' or 'valid', pass (if we trust upload).
        // Stricter: status MUST be 'valid' (which might be set by a separate async process or admin).
        // However, prompt OBJECTIVE 3: "Automatically approve providers ONLY when all checks pass".
        // And "Verify provider skills without live human video calls" -> "Video Skill Proof (Async)".
        // If we want FULL automation, we need to mock the video validation or just accept it if duration > 30s.
        const isVideoValid = video && video.status === 'valid';

        // Rule 3: Documents Verified (OCR & Face)
        // Check columns in technicians table
        const isDocsVerified = Number(tech.ocr_confidence) >= 80 && Number(tech.face_match_confidence) >= 80;

        // Construct Status Object
        const autoStatus = {
            skill: isSkillPassed ? 'passed' : 'pending',
            video: isVideoValid ? 'valid' : (video ? video.status : 'missing'),
            docs: isDocsVerified ? 'verified' : 'pending'
        };

        // Update Status JSON
        await client.query(
            'UPDATE technicians SET auto_verification_status = $1 WHERE id = $2',
            [JSON.stringify(autoStatus), technicianId]
        );

        // FINAL DECISION
        console.log(`[DecisionEngine] ${technicianId} -> Skill:${isSkillPassed} Video:${isVideoValid} Docs:${isDocsVerified}`);
        if (isSkillPassed && isVideoValid && isDocsVerified) {
            await client.query(
                "UPDATE technicians SET is_verified = true, verification_step = 'verified' WHERE id = $1",
                [technicianId]
            );
            console.log(`[DecisionEngine] Auto-approved technician ${technicianId}`);
        } else {
            // Move to Manual Review if all steps are completed but confidence is low?
            // Or just leave in current state?
            // Prompt: "Otherwise: Move provider to MANUAL_REVIEW queue"
            // We should only move to manual review if they HAVE submitted everything but failed the strict auto-rules.

            const hasSubmittedAll = assessment && video && tech.verification_step === 'documents_submitted';

            if (hasSubmittedAll) {
                await client.query(
                    "UPDATE technicians SET verification_step = 'manual_review' WHERE id = $1",
                    [technicianId]
                );
                console.log(`[DecisionEngine] Moved technician ${technicianId} to Manual Review`);
            }
        }

        await client.query('COMMIT');
        return autoStatus;

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Decision Engine Error:', error);
        throw error;
    } finally {
        client.release();
    }
}

module.exports = { checkAndAutoApprove };
