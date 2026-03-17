const h3Redis = require('../lib/h3Redis');
const kafka = require('../lib/kafka');
const db = require('../config/db');

class MatchingService {
    constructor() {
        this.logs = [];
    }

    addLog(msg) {
        console.log(msg);
        this.logs.push(`[${new Date().toISOString()}] ${msg}`);
        if (this.logs.length > 100) this.logs.shift();
    }

    /**
     * Find and Offer Job to Technicians
     * 1. Get user location
     * 2. Find techs in nearby H3 cells
     * 3. Filter/Rank
     * 4. Offer job (Push to Redis queue/list for this job)
     * 5. Emit Event
     */
    async findMatches(jobRequest) {
        const { jobId, pickupLat, pickupLng } = jobRequest;
        const radius = process.env.NODE_ENV === 'development' ? 50 : 5;

        this.addLog(`[Matching] STARTING MATCH: Job ${jobId} | Loc: ${pickupLat},${pickupLng} | Radius: ${radius}`);

        // 1. Find nearby technicians in Redis
        const nearbyTechs = await h3Redis.findNearbyTechnicians(pickupLat, pickupLng, radius);
        this.addLog(`[Matching] STEP 1 (Geo): Found ${nearbyTechs.length} total online techs in Redis.`);

        if (nearbyTechs.length === 0) {
            const h3Index = h3Redis.getH3Index(pickupLat, pickupLng);
            this.addLog(`[Matching] STEP 1 FAIL: No techs in Redis. H3 Center: ${h3Index}`);
            return [];
        }

        // 2. Verification Filter
        const verifiedTechs = nearbyTechs.filter(t => {
            const isVerified = t.isVerified === 'true' || t.isVerified === true;
            const allowUnverified = process.env.NODE_ENV === 'development';
            const isEligible = isVerified || allowUnverified;
            this.addLog(`[Matching] STEP 2 (Eligible): Tech ${t.id} | Verified: ${isVerified} | Eligible: ${isEligible}`);
            return isEligible;
        });

        this.addLog(`[Matching] STEP 2 RESULT: ${verifiedTechs.length} eligible techs.`);

        if (verifiedTechs.length === 0) return [];

        // 3. Service Filter
        const techIds = verifiedTechs.map(t => t.id);
        const { serviceId, serviceName } = jobRequest;

        this.addLog(`[Matching] STEP 3 (Capability): Target: ${serviceName} (${serviceId})`);

        // Try Matching by ID
        let serviceMatchRes = await db.query(
            "SELECT technician_id FROM technician_services WHERE technician_id = ANY($1) AND service_id = $2",
            [techIds, serviceId]
        );
        let matchedTechIds = serviceMatchRes.rows.map(r => r.technician_id);
        this.addLog(`[Matching] STEP 3a (ID Match): Count: ${matchedTechIds.length}`);

        // Fallback: Try Matching by NAME
        if (matchedTechIds.length === 0 && serviceName) {
            this.addLog(`[Matching] STEP 3b (Name Fallback): Searching for "${serviceName}"`);
            serviceMatchRes = await db.query(
                `SELECT ts.technician_id 
                 FROM technician_services ts
                 JOIN services s ON ts.service_id = s.id
                 WHERE ts.technician_id = ANY($1) 
                 AND (s.name ILIKE $2 OR s.category ILIKE $2 OR s.name ILIKE $3)`,
                [techIds, `%${serviceName}%`, `%${serviceName.split(' ')[0]}%`]
            );
            matchedTechIds = serviceMatchRes.rows.map(r => r.technician_id);
            this.addLog(`[Matching] STEP 3b RESULT: Count: ${matchedTechIds.length}`);
        }

        const capableTechs = verifiedTechs.filter(t => matchedTechIds.includes(t.id));

        if (capableTechs.length === 0) {
            this.addLog(`[Matching] STEP 3 FAIL: No capable techs found.`);

            if (process.env.NODE_ENV === 'development') {
                this.addLog(`[Matching] STEP 3 RECOVERY (DEV): Notifying all nearby verified techs.`);
                capableTechs.push(...verifiedTechs); // Fill for notify
            } else {
                return [];
            }
        }

        // Centralized Offer Storage
        const allMatchIds = capableTechs.map(t => t.id);
        this.addLog(`[Matching] FINAL CAPABLE IDS: ${allMatchIds}`);
        await h3Redis.client.set(`job:${jobId}:offers`, JSON.stringify(allMatchIds));

        // 4. Publish to Kafka (Optional)
        try {
            await kafka.publish('job.matched', jobId, {
                jobId, techIds: allMatchIds, pickupLat, pickupLng,
                serviceName: jobRequest.serviceName,
                amount: jobRequest.amount,
                orderId: jobRequest.orderId
            });
        } catch (e) { this.addLog(`[Matching] Kafka skip: ${e.message}`); }

        // 5. Direct Socket Emission
        const { notifyTechnician } = require('../lib/socket');
        capableTechs.forEach(tech => {
            this.addLog(`[Matching] EMITTING TO: ${tech.id}`);
            notifyTechnician(tech.id, 'job:new', {
                jobId, pickupLat, pickupLng,
                serviceName: jobRequest.serviceName,
                orderId: jobRequest.orderId,
                amount: jobRequest.amount || '0',
                pickupAddress: jobRequest.pickupAddress || null,
                userPhone: jobRequest.userPhone || null,
                userName: jobRequest.userName || null,
                userId: jobRequest.userId,
                message: 'New Service Request Nearby!'
            });
        });

        return capableTechs;
    }
}

module.exports = new MatchingService();
