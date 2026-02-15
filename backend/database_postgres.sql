-- Tariki Consolidated Database Schema for PostgreSQL
-- Compatible with Render.com Managed Postgres

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    phone VARCHAR(20) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    role VARCHAR(20) CHECK (role IN ('driver', 'admin', 'user')) DEFAULT 'user',
    balance DECIMAL(10, 2) DEFAULT 0.00,
    car_number VARCHAR(50),
    photo_path VARCHAR(255),
    last_lat DECIMAL(10, 8) DEFAULT 0.00000000,
    last_lng DECIMAL(11, 8) DEFAULT 0.00000000,
    is_online BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Rides Table
CREATE TABLE IF NOT EXISTS rides (
    id SERIAL PRIMARY KEY,
    pickup_address VARCHAR(255) NOT NULL,
    dropoff_address VARCHAR(255) NOT NULL,
    pickup_lat DECIMAL(10, 8) DEFAULT 0.00000000,
    pickup_lng DECIMAL(11, 8) DEFAULT 0.00000000,
    dropoff_lat DECIMAL(10, 8) DEFAULT 0.00000000,
    dropoff_lng DECIMAL(11, 8) DEFAULT 0.00000000,
    total_price DECIMAL(10, 2) DEFAULT 0.00,
    customer_phone VARCHAR(20),
    status VARCHAR(20) CHECK (status IN ('pending', 'accepted', 'arrived', 'on_trip', 'delivered', 'cancelled')) DEFAULT 'pending',
    type VARCHAR(20) CHECK (type IN ('open', 'fixed', 'closed')) DEFAULT 'fixed',
    driver_id INT DEFAULT NULL,
    start_time TIMESTAMP NULL DEFAULT NULL,
    end_time TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (driver_id) REFERENCES users(id)
);
CREATE INDEX idx_rides_status ON rides(status);
CREATE INDEX idx_rides_driver_id ON rides(driver_id);

-- 3. Deposits Table
CREATE TABLE IF NOT EXISTS deposits (
    id SERIAL PRIMARY KEY,
    driver_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    reference_number VARCHAR(100),
    method VARCHAR(50),
    sender_phone VARCHAR(20),
    image_path VARCHAR(255),
    status VARCHAR(20) CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (driver_id) REFERENCES users(id)
);

-- 4. Settings Table
CREATE TABLE IF NOT EXISTS settings (
    id SERIAL PRIMARY KEY,
    price_km DECIMAL(10,2) DEFAULT 10.00,
    price_min DECIMAL(10,2) DEFAULT 1.00,
    base_fare DECIMAL(10,2) DEFAULT 5.00,
    commission_percent DECIMAL(5,2) DEFAULT 10.00
);

-- 5. Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    target_role VARCHAR(20) CHECK (target_role IN ('admin', 'driver', 'user', 'all')) NOT NULL,
    target_user_id INT DEFAULT NULL,
    title VARCHAR(100) NOT NULL,
    body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_notif_role ON notifications(target_role);
CREATE INDEX idx_notif_user ON notifications(target_user_id);

-- Seed Initial Data
INSERT INTO settings (id, price_km, price_min, base_fare, commission_percent) 
VALUES (1, 10.00, 1.00, 5.00, 10.00)
ON CONFLICT (id) DO NOTHING;

-- Default Admin
INSERT INTO users (phone, password, name, role, balance) 
VALUES ('admin', 'admin', 'Super Admin', 'admin', 0.00)
ON CONFLICT (phone) DO NOTHING;
