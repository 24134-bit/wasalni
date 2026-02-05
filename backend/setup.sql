CREATE DATABASE IF NOT EXISTS wasalni;
USE wasalni;

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
    driver_id INT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (status),
    INDEX (driver_id),
    FOREIGN KEY (driver_id) REFERENCES users(id)
);

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

-- Seed Data
INSERT INTO users (phone, password, name, role, balance) VALUES 
('055555555', '123', 'Driver Ahmed', 'driver', 0.00),
('066666666', 'admin', 'Admin User', 'admin', 0.00)
ON DUPLICATE KEY UPDATE id=id;

-- Seed Rides
INSERT INTO rides (pickup_address, dropoff_address, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, total_price, status) VALUES
('Riyadh Park', 'King Saud University', 24.7578, 46.6306, 24.7162, 46.6191, 45.00, 'pending'),
('Airport Terminal 3', 'Hilton Riyadh', 24.9658, 46.6977, 24.7793, 46.7380, 120.00, 'pending'),
('Kingdom Centre', 'Olaya Street', 24.7112, 46.6744, 24.6967, 46.6806, 30.00, 'pending');
