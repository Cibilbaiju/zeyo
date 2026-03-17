require('dotenv').config();
const http = require('http');
const app = require('./app');
const { initSocket } = require('./lib/socket');
const h3Redis = require('./lib/h3Redis');
const kafka = require('./lib/kafka');

const PORT = process.env.PORT || 3000;
const server = http.createServer(app);

// Initialize Services
async function startServer() {
    try {
        await h3Redis.connect();
        // Start WebSocket
        initSocket(server);
        const { notifyTechnician } = require('./lib/socket');

        // Start Kafka (Non-blocking)
        try {
            await kafka.connect();

            // Start Consumer
            await kafka.consumer.subscribe({ topic: 'job.matched', fromBeginning: false });
            await kafka.consumer.run({
                eachMessage: async ({ topic, partition, message }) => {
                    const matchingService = require('./services/matchingService');
                    const data = JSON.parse(message.value.toString());
                    matchingService.addLog(`[Kafka] Received ${topic}: ${JSON.stringify(data)}`);

                    if (topic === 'job.matched') {
                        const { techIds, jobId, pickupLat, pickupLng, serviceName, orderId, amount, message: msg } = data;
                        // Notify each matched tech
                        techIds.forEach(techId => {
                            notifyTechnician(techId, 'job:new', {
                                jobId,
                                pickupLat,
                                pickupLng,
                                serviceName,
                                orderId,
                                amount: amount || '0',
                                message: msg || 'New Service Request Nearby!'
                            });
                            matchingService.addLog(`[Socket] Notified Tech ${techId} of Job ${jobId}`);
                        });
                    }
                },
            });
            console.log('Kafka Connected & Consumer Running');
        } catch (kafkaError) {
            console.error('WARNING: Kafka failed to start. Job matching notifications may not work.', kafkaError.message);
            // Continue starting server even if Kafka fails
        }

        server.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
        });
    } catch (err) {
        console.error('Failed to start server:', err);
        process.exit(1);
    }
}

startServer();
