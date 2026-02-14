<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
include 'db.php';

try {
    $stmt = $conn->query("SELECT id, name, phone, car_number, photo_path, balance, is_online, last_lat, last_lng FROM users WHERE role = 'driver'");
    $drivers = $stmt->fetchAll();
    echo json_encode($drivers);
} catch (PDOException $e) {
    echo json_encode([]);
}
?>
