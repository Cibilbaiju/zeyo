-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    password VARCHAR(255),
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Technicians Table
CREATE TABLE IF NOT EXISTS technicians (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100),
    is_verified BOOLEAN DEFAULT FALSE,
    is_online BOOLEAN DEFAULT FALSE,
    current_lat DOUBLE PRECISION,
    current_lng DOUBLE PRECISION,
    rating NUMERIC(3, 2) DEFAULT 5.00,
    wallet_balance NUMERIC(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Services Table
CREATE TABLE IF NOT EXISTS services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    base_price NUMERIC(10, 2) DEFAULT 0.00,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

-- Jobs Table
CREATE TABLE IF NOT EXISTS jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    technician_id UUID REFERENCES technicians(id),
    service_id UUID REFERENCES services(id),
    status VARCHAR(50) DEFAULT 'pending' 
        CHECK (status IN ('pending', 'matched', 'accepted', 'started', 'completed', 'cancelled')),
    order_id VARCHAR(50) UNIQUE,
    pickup_lat DOUBLE PRECISION,
    pickup_lng DOUBLE PRECISION,
    pickup_address TEXT,
    price_estimated NUMERIC(10, 2),
    price_final NUMERIC(10, 2),
    otp VARCHAR(10),
    matched_at TIMESTAMP WITH TIME ZONE,
    accepted_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Ratings Table
CREATE TABLE IF NOT EXISTS ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID REFERENCES jobs(id),
    from_user_id UUID REFERENCES users(id),
    to_tech_id UUID REFERENCES technicians(id),
    rating INT CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Addresses Table
CREATE TABLE IF NOT EXISTS addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    label VARCHAR(50), -- Home, Work, etc.
    address_line TEXT NOT NULL,
    house_floor VARCHAR(100),
    apartment_area VARCHAR(100),
    directions TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Technician Services Mapping (Many-to-Many)
CREATE TABLE IF NOT EXISTS technician_services (
    technician_id UUID REFERENCES technicians(id) ON DELETE CASCADE,
    service_id UUID REFERENCES services(id) ON DELETE CASCADE,
    PRIMARY KEY (technician_id, service_id)
);

-- Seed Services (Idempotent with standard UUIDs from Flutter app)
INSERT INTO services (id, name, category, base_price) 
SELECT 'b0000001-0000-0000-0000-000000000000', 'Switch/Socket replacement', 'Home', 49.00 
WHERE NOT EXISTS (SELECT 1 FROM services WHERE id = 'b0000001-0000-0000-0000-000000000000');

INSERT INTO services (id, name, category, base_price) 
SELECT 'b0000002-0000-0000-0000-000000000000', 'Fan repair', 'Home', 119.00 
WHERE NOT EXISTS (SELECT 1 FROM services WHERE id = 'b0000002-0000-0000-0000-000000000000');

INSERT INTO services (id, name, category, base_price) 
SELECT 'a0000001-0000-0000-0000-000000000000', 'Cupboard repair', 'Home', 89.00 
WHERE NOT EXISTS (SELECT 1 FROM services WHERE id = 'a0000001-0000-0000-0000-000000000000');

-- Fallback seeds for categories
INSERT INTO services (name, category, base_price) 
SELECT 'Plumbing', 'Home', 50.00 WHERE NOT EXISTS (SELECT 1 FROM services WHERE name = 'Plumbing');
INSERT INTO services (name, category, base_price) 
SELECT 'Painting', 'Home', 200.00 WHERE NOT EXISTS (SELECT 1 FROM services WHERE name = 'Painting');
