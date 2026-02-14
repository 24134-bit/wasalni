<?php
// wasalni/backend/fix_database.php
include 'db.php';
header("Content-Type: text/html; charset=UTF-8");

echo "<h1>Wasalni Database Fixer</h1>";

$tables = [
    "users" => "CREATE TABLE IF NOT EXISTS `users` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `phone` varchar(20) NOT NULL UNIQUE,
      `password` varchar(255) NOT NULL,
      `name` varchar(100) DEFAULT NULL,
      `car_number` varchar(50) DEFAULT NULL,
      `photo_path` varchar(255) DEFAULT NULL,
      `role` enum('admin','driver','user') NOT NULL DEFAULT 'user',
      `balance` decimal(10,2) DEFAULT '0.00',
      `last_lat` decimal(10, 8) DEFAULT 0.00000000,
      `last_lng` decimal(11, 8) DEFAULT 0.00000000,
      `is_online` tinyint(1) DEFAULT '0',
      `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",

    "settings" => "CREATE TABLE IF NOT EXISTS `settings` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `price_km` decimal(10,2) DEFAULT '10.00',
      `price_min` decimal(10,2) DEFAULT '1.00',
      `base_fare` decimal(10,2) DEFAULT '5.00',
      `commission_percent` decimal(10,2) DEFAULT '10.00',
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",

    "rides" => "CREATE TABLE IF NOT EXISTS `rides` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `driver_id` int(11) DEFAULT NULL,
      `pickup_address` varchar(255) NOT NULL,
      `dropoff_address` varchar(255) NOT NULL,
      `type` enum('fixed','open') NOT NULL DEFAULT 'fixed',
      `pickup_lat` decimal(10, 8) DEFAULT 0.00000000,
      `pickup_lng` decimal(11, 8) DEFAULT 0.00000000,
      `dropoff_lat` decimal(10, 8) DEFAULT 0.00000000,
      `dropoff_lng` decimal(11, 8) DEFAULT 0.00000000,
      `total_price` decimal(10,2) DEFAULT '0.00',
      `customer_phone` varchar(20) DEFAULT NULL,
      `status` enum('pending','accepted','arrived','on_trip','delivered','cancelled') DEFAULT 'pending',
      `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `start_time` timestamp NULL DEFAULT NULL,
      `end_time` timestamp NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX (`status`),
      INDEX (`driver_id`),
      FOREIGN KEY (`driver_id`) REFERENCES `users` (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",

    "deposits" => "CREATE TABLE IF NOT EXISTS `deposits` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `driver_id` int(11) NOT NULL,
      `amount` decimal(10,2) NOT NULL,
      `reference_number` varchar(100) DEFAULT NULL,
      `method` varchar(50) DEFAULT NULL,
      `sender_phone` varchar(20) DEFAULT NULL,
      `image_path` varchar(255) DEFAULT NULL,
      `status` enum('pending','approved','rejected') DEFAULT 'pending',
      `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      FOREIGN KEY (`driver_id`) REFERENCES `users` (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",

    "notifications" => "CREATE TABLE IF NOT EXISTS `notifications` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `target_role` enum('all','admin','driver','user') NOT NULL,
      `target_user_id` int(11) DEFAULT NULL,
      `title` varchar(255) NOT NULL,
      `body` text NOT NULL,
      `is_read` tinyint(1) DEFAULT '0',
      `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      INDEX (`target_role`),
      INDEX (`target_user_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;"
];

try {
    foreach ($tables as $name => $sql) {
        if ($conn->exec($sql) !== false) {
            echo "<p style='color:green;'>Table <b>$name</b> is ready.</p>";
        } else {
            echo "<p style='color:red;'>Error creating table $name.</p>";
        }
    }

    // Check for specific columns if tables existed but were missing columns
    echo "<h3>Checking Columns...</h3>";
    
    // Check settings.commission_percent
    $check = $conn->query("SHOW COLUMNS FROM settings LIKE 'commission_percent'");
    if (!$check->fetch()) {
        $conn->exec("ALTER TABLE settings ADD COLUMN commission_percent decimal(10,2) DEFAULT '10.00'");
        echo "<p style='color:blue;'>Added 'commission_percent' to settings.</p>";
    }

    // Ensure at least one setting row exists
    $count = $conn->query("SELECT COUNT(*) FROM settings")->fetchColumn();
    if ($count == 0) {
        $conn->exec("INSERT INTO settings (id, price_km, price_min, base_fare, commission_percent) VALUES (1, 10.00, 1.00, 5.00, 10.00)");
        echo "<p style='color:blue;'>Seeded default settings.</p>";
    }

    echo "<h2>Database is now in Sync!</h2>";

} catch (Exception $e) {
    echo "<p style='color:red;'>FATAL ERROR: " . $e->getMessage() . "</p>";
}
?>
