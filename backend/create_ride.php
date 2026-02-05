<?php
header("Content-Type: application/json");
include 'db.php';

$pickup = $_POST['pickup'] ?? '';
$dropoff = $_POST['dropoff'] ?? '';
$p_lat = $_POST['p_lat'] ?? 0;
$p_lng = $_POST['p_lng'] ?? 0;
$d_lat = $_POST['d_lat'] ?? 0;
$d_lng = $_POST['d_lng'] ?? 0;
$price = $_POST['price'] ?? 0;
$customer_phone = $_POST['customer_phone'] ?? '';

if (!$pickup || !$dropoff || !$price) {
    echo json_encode(["success" => false, "error" => "Missing info"]);
    exit;
}

$stmt = $conn->prepare("INSERT INTO rides (pickup_address, dropoff_address, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, total_price, customer_phone, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')");
$stmt->bind_param("ssddddds", $pickup, $dropoff, $p_lat, $p_lng, $d_lat, $d_lng, $price, $customer_phone);

if ($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "error" => "Failed"]);
}
?>
