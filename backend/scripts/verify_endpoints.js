const jwt = require('jsonwebtoken');

// Config
const BASE_URL = 'http://localhost:5000/api'; // Assuming 5000 based on conversation history
const JWT_SECRET = 'dev-secret'; // Using default dev secret

// Helpers
async function runVerification() {
    try {
        console.log('Starting Verification...');

        // 1. Create a Technician Token (Mock)
        // We need a valid technician ID. I'll pick a random UUID or insert one if I could, 
        // but for now let's hope I can access a technician.
        // Actually, let's just make a mock token with a random UUID.
        const techId = '123e4567-e89b-12d3-a456-426614174000';
        const token = jwt.sign({ id: techId, role: 'technician' }, JWT_SECRET);

        const headers = { Authorization: `Bearer ${token}` };

        // 2. Book a Skill Session
        console.log('Booking Session...');
        const bookRes = await fetch(`${BASE_URL}/technician/skill-session`, {
            method: 'POST',
            headers: { ...headers, 'Content-Type': 'application/json' },
            body: JSON.stringify({ scheduledAt: new Date().toISOString() })
        });
        const bookData = await bookRes.json();
        console.log('Booking Response:', bookData);

        if (!bookData.meeting_link) throw new Error('Meeting Link missing!');
        if (bookData.status !== 'scheduled') throw new Error('Status not scheduled!');
        console.log('✅ Booking Passed');
        const sessionId = bookData.id;

        // 3. Admin List Sessions
        console.log('Listing Sessions (Admin)...');
        const listRes = await fetch(`${BASE_URL}/technician/skill-sessions`);
        const listData = await listRes.json();
        // console.log('List Data:', listData);
        const sessionInList = listData.find(s => s.id === sessionId);
        if (!sessionInList) throw new Error('Session not found in list!');
        console.log('✅ Listing Passed');

        // 4. Admin Approve Session
        console.log('Approving Session...');
        const approveRes = await fetch(`${BASE_URL}/technician/skill-session/${sessionId}/approve`, {
            method: 'POST'
        });
        const approveData = await approveRes.json();
        console.log('Approve Response:', approveData);
        if (!approveData.success) throw new Error('Approval failed');
        console.log('✅ Approval Passed');

        // 5. Verify Status (by fetching again)
        const recheckRes = await fetch(`${BASE_URL}/technician/skill-session`, { headers });
        const recheckData = await recheckRes.json();
        if (recheckData.status !== 'approved') throw new Error('Status not updated to approved');
        console.log('✅ Status Verification Passed');

        console.log('🎉 ALL BACKEND TESTS PASSED');

    } catch (e) {
        console.error('❌ Verification Failed:', e);
    }
}

runVerification();
