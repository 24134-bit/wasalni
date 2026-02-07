-- Wasalni Consolidated Database Schema
-- Includes all updates and migrations

CREATE DATABASE IF NOT EXISTS wasalni;
USE wasalni;

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    role ENUM('driver', 'admin') DEFAULT 'driver',
    balance DECIMAL(10, 2) DEFAULT 0.00,
    car_number VARCHAR(50),
    photo_path VARCHAR(255),
    last_lat DECIMAL(10, 8) DEFAULT 0.00000000,
    last_lng DECIMAL(11, 8) DEFAULT 0.00000000,
    is_online TINYINT(1) DEFAULT 0
);

-- 2. Rides Table
CREATE TABLE IF NOT EXISTS rides (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pickup_address VARCHAR(255) NOT NULL,
    dropoff_address VARCHAR(255) NOT NULL,
    pickup_lat DECIMAL(10, 8) DEFAULT 0.00000000,
    pickup_lng DECIMAL(11, 8) DEFAULT 0.00000000,
    dropoff_lat DECIMAL(10, 8) DEFAULT 0.00000000,
    dropoff_lng DECIMAL(11, 8) DEFAULT 0.00000000,
    total_price DECIMAL(10, 2) NOT NULL,
    customer_phone VARCHAR(20),
    status ENUM('pending', 'accepted', 'arrived', 'on_trip', 'delivered', 'cancelled') DEFAULT 'pending',
    type ENUM('open', 'closed') DEFAULT 'closed',
    driver_id INT DEFAULT NULL,
    start_time TIMESTAMP NULL DEFAULT NULL,
    end_time TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (status),
    INDEX (driver_id),
    FOREIGN KEY (driver_id) REFERENCES users(id)
);

-- 3. Deposits Table
CREATE TABLE IF NOT EXISTS deposits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    reference_number VARCHAR(100),
    method VARCHAR(50),
    sender_phone VARCHAR(20),
    image_path VARCHAR(255),
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (driver_id) REFERENCES users(id)
);

-- 4. Settings Table
CREATE TABLE IF NOT EXISTS settings (
    id INT PRIMARY KEY DEFAULT 1,
    price_km DECIMAL(10,2) DEFAULT 10.00,
    price_min DECIMAL(10,2) DEFAULT 1.00,
    base_fare DECIMAL(10,2) DEFAULT 5.00,
    commission_percent DECIMAL(5,2) DEFAULT 10.00
);

-- 5. Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    target_role ENUM('admin', 'driver', 'all') NOT NULL,
    target_user_id INT DEFAULT NULL,
    title VARCHAR(100) NOT NULL,
    body TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (target_role),
    INDEX (target_user_id)
);

-- Seed Initial Data
INSERT IGNORE INTO settings (id, price_km, price_min, base_fare, commission_percent) 
VALUES (1, 10.00, 1.00, 5.00, 10.00);

INSERT IGNORE INTO users (phone, password, name, role, balance) VALUES 
('055555555', '123', 'Driver Ahmed', 'driver', 0.00),
('066666666', 'admin', 'Admin User', 'admin', 0.00);
