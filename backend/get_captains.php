<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
include 'db.php';

$result = $conn->query("SELECT id, name, phone, car_number, photo_path, balance, is_online, last_lat, last_lng FROM users WHERE role = 'driver'");
$drivers = [];
while($row = $result->fetch_assoc()) {
    $drivers[] = $row;
}
echo json_encode($drivers);
?>
