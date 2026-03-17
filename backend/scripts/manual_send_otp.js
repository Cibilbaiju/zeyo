require('dotenv').config(); // Load .env from backend root
const authService = require('../src/services/authService');

const PHONE_NUMBER = process.argv[2];

if (!PHONE_NUMBER) {
    console.error('Usage: node scripts/manual_send_otp.js <phone_number>');
    process.exit(1);
}

async function sendOtp() {
    console.log(`Attempting to send OTP to ${PHONE_NUMBER}...`);
    try {
        const result = await authService.sendOTP(PHONE_NUMBER);
        console.log('Result:', result);
    } catch (error) {
        console.error('Failed:', error);
    }
    process.exit(0);
}

sendOtp();
