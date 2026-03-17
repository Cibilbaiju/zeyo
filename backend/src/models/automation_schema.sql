-- Skill Questions Table
CREATE TABLE IF NOT EXISTS skill_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID REFERENCES services(id),
    question_text TEXT NOT NULL,
    options JSONB NOT NULL, -- Array of strings
    correct_option_index INTEGER NOT NULL,
    question_type VARCHAR(20) DEFAULT 'mcq', -- mcq, scenario
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Provider Skill Assessments Table
CREATE TABLE IF NOT EXISTS provider_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technician_id UUID REFERENCES technicians(id),
    service_id UUID REFERENCES services(id),
    score INTEGER NOT NULL, -- Percentage 0-100
    total_questions INTEGER NOT NULL,
    correct_answers INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL, -- pass, fail
    details JSONB, -- Store full Q&A if needed for audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Verification Videos Table (Async Video Proof)
CREATE TABLE IF NOT EXISTS verification_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technician_id UUID REFERENCES technicians(id),
    video_url TEXT NOT NULL,
    duration_seconds INTEGER,
    status VARCHAR(20) DEFAULT 'pending', -- pending, valid, invalid
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add Columns to Technicians Table
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS ocr_confidence NUMERIC(5, 2);
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS face_match_confidence NUMERIC(5, 2);
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS auto_verification_status JSONB DEFAULT '{}'; 
-- Example status: { "skill": "passed", "video": "uploaded", "docs": "verified" }
