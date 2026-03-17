const { Kafka, logLevel } = require('kafkajs');

const KAFKA_BROKERS = (process.env.KAFKA_BROKERS || 'localhost:9092').split(',');
const CLIENT_ID = process.env.KAFKA_CLIENT_ID || 'zeyo-backend';

class KafkaService {
    constructor() {
        this.kafka = new Kafka({
            clientId: CLIENT_ID,
            brokers: KAFKA_BROKERS,
            logLevel: logLevel.ERROR
        });

        this.producer = this.kafka.producer();
        this.consumer = this.kafka.consumer({ groupId: 'zeyo-backend-group' });
        this.isConnected = false;
    }

    async connect() {
        if (!this.isConnected) {
            await this.producer.connect();
            await this.consumer.connect();
            this.isConnected = true;
            console.log('Connected to Kafka');
        }
    }

    /**
     * Publish an event to a topic
     */
    async publish(topic, messageKey, messageValue) {
        try {
            await this.producer.send({
                topic,
                messages: [
                    { key: messageKey, value: JSON.stringify(messageValue) }
                ],
            });
            // console.log(`[Kafka] Published to ${topic}: ${messageKey}`);
        } catch (error) {
            console.error(`[Kafka] Error publishing to ${topic}:`, error);
        }
    }

    /**
     * Subscribe to a topic with a handler
     */
    async subscribe(topic, handler) {
        await this.consumer.subscribe({ topic, fromBeginning: false });

        await this.consumer.run({
            eachMessage: async ({ topic, partition, message }) => {
                const key = message.key.toString();
                const value = JSON.parse(message.value.toString());
                // console.log(`[Kafka] Received ${topic}:`, key);
                await handler(key, value);
            },
        });
    }
}

module.exports = new KafkaService();
