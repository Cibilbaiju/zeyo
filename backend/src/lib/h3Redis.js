const { createClient } = require('redis');
const h3 = require('h3-js');

// Config
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const H3_RESOLUTION = 9; // ~174m edge length, good for street-level matching

class RedisService {
    constructor() {
        this.client = createClient({ url: REDIS_URL });
        this.client.on('error', (err) => console.error('Redis Client Error', err));
        this.isConnected = false;
    }

    async connect() {
        if (!this.isConnected) {
            await this.client.connect();
            this.isConnected = true;
            console.log('Connected to Redis');
        }
    }

    /**
     * Converts Lat/Lng to H3 Cell
     */
    getH3Index(lat, lng) {
        return h3.latLngToCell(lat, lng, H3_RESOLUTION);
    }

    /**
     * Get k-ring neighbors (cells within k distance)
     */
    getNearbyCells(h3Index, k = 1) {
        return h3.gridDisk(h3Index, k);
    }

    /**
     * Update Technician Location & Status
     */
    async updateTechnicianLocation(techId, lat, lng, status = 'online', isVerified = false) {
        const cell = this.getH3Index(lat, lng);
        const key = `tech:${techId}`;

        // 1. Store Tech Details (TTL 1 hour to auto-prune stale)
        await this.client.hSet(key, {
            lat,
            lng,
            cell,
            status,
            isVerified: isVerified.toString(), // Store as string
            lastUpdated: Date.now()
        });
        await this.client.expire(key, 3600);

        // 2. Add to H3 Bucket (if online)
        // We first remove from old buckets if we tracked them, complexity implies we just add to new 
        // and let TTL/logic handle cleanup or we explicitly track 'prevCell' in Hash.
        if (status === 'online') {
            await this.client.sAdd(`h3:${cell}`, techId);
        } else {
            await this.client.sRem(`h3:${cell}`, techId);
        }
    }

    /**
     * Find nearby technicians
     * 1. Calc user's cell
     * 2. Get k-ring neighbors
     * 3. Fetch all tech IDs from those cells
     * 4. Fetch details for those IDs
     */
    async findNearbyTechnicians(lat, lng, radiusK = 1) {
        const centerCell = this.getH3Index(lat, lng);
        const neighborCells = this.getNearbyCells(centerCell, radiusK);

        // Collect all Tech IDs from these cells in parallel
        const pipeline = this.client.multi();
        neighborCells.forEach(cell => pipeline.sMembers(`h3:${cell}`));
        const results = await pipeline.exec();

        // Flatten Tech IDs unique
        const techIds = [...new Set(results.flat())];

        if (techIds.length === 0) return [];

        // Fetch details
        const techPipeline = this.client.multi();
        techIds.forEach(id => techPipeline.hGetAll(`tech:${id}`));
        const techDetails = await techPipeline.exec();

        // Map back to ID and filter valid/online
        return techDetails
            .map((details, idx) => ({ id: techIds[idx], ...details }))
            .filter(t => t.status === 'online');
    }
}

module.exports = new RedisService();
