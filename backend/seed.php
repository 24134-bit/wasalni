<?php
include 'db.php';

echo "<h1>Database Seeding...</h1>";

$tables = [
    "users" => "CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        phone VARCHAR(20) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        name VARCHAR(100),
        role VARCHAR(20) CHECK (role IN ('driver', 'admin')) DEFAULT 'driver',
        balance DECIMAL(10, 2) DEFAULT 0.00,
        car_number VARCHAR(50),
        photo_path VARCHAR(255),
        last_lat DECIMAL(10, 8) DEFAULT 0.00000000,
        last_lng DECIMAL(11, 8) DEFAULT 0.00000000,
        is_online BOOLEAN DEFAULT FALSE
    )",
    "rides" => "CREATE TABLE IF NOT EXISTS rides (
        id SERIAL PRIMARY KEY,
        pickup_address VARCHAR(255) NOT NULL,
        dropoff_address VARCHAR(255) NOT NULL,
        pickup_lat DECIMAL(10, 8) DEFAULT 0.00000000,
        pickup_lng DECIMAL(11, 8) DEFAULT 0.00000000,
        dropoff_lat DECIMAL(10, 8) DEFAULT 0.00000000,
        dropoff_lng DECIMAL(11, 8) DEFAULT 0.00000000,
        total_price DECIMAL(10, 2) NOT NULL,
        customer_phone VARCHAR(20),
        status VARCHAR(20) CHECK (status IN ('pending', 'accepted', 'arrived', 'on_trip', 'delivered', 'cancelled')) DEFAULT 'pending',
        type VARCHAR(20) CHECK (type IN ('open', 'closed')) DEFAULT 'closed',
        driver_id INT DEFAULT NULL,
        start_time TIMESTAMP NULL DEFAULT NULL,
        end_time TIMESTAMP NULL DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (driver_id) REFERENCES users(id)
    )",
    "deposits" => "CREATE TABLE IF NOT EXISTS deposits (
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
    )",
    "settings" => "CREATE TABLE IF NOT EXISTS settings (
        id SERIAL PRIMARY KEY,
        price_km DECIMAL(10,2) DEFAULT 10.00,
        price_min DECIMAL(10,2) DEFAULT 1.00,
        base_fare DECIMAL(10,2) DEFAULT 5.00,
        commission_percent DECIMAL(5,2) DEFAULT 10.00
    )",
    "notifications" => "CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        target_role VARCHAR(20) CHECK (target_role IN ('admin', 'driver', 'all')) NOT NULL,
        target_user_id INT DEFAULT NULL,
        title VARCHAR(100) NOT NULL,
        body TEXT NOT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )"
];

foreach ($tables as $name => $sql) {
    try {
        $conn->exec($sql);
        echo "<p style='color:green'>Table '$name' created/verified.</p>";
    } catch (PDOException $e) {
        echo "<p style='color:red'>Error creating table '$name': " . $e->getMessage() . "</p>";
    }
}

// Seed Initial Data
try {
    $conn->exec("INSERT INTO settings (id, price_km, price_min, base_fare, commission_percent) 
                 VALUES (1, 10.00, 1.00, 5.00, 10.00) ON CONFLICT (id) DO NOTHING");
    $conn->exec("INSERT INTO users (phone, password, name, role, balance) VALUES 
                 ('055555555', '123', 'Driver Ahmed', 'driver', 0.00),
                 ('066666666', 'admin', 'Admin User', 'admin', 0.00) ON CONFLICT (phone) DO NOTHING");
    echo "<p style='color:green'>Initial data seeded!</p>";
} catch (PDOException $e) {
    echo "<p style='color:red'>Error seeding data: " . $e->getMessage() . "</p>";
}

echo "<h2>Seeding Completed!</h2>";
?>
