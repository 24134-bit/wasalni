<?php
include 'db.php';

$price_km = $_POST['price_km'];
$price_min = $_POST['price_min'];
$base_fare = $_POST['base_fare'];
$commission_percent = $_POST['commission_percent'] ?? 10;

$stmt = $conn->prepare("UPDATE settings SET price_km = ?, price_min = ?, base_fare = ?, commission_percent = ? WHERE id = 1");
$stmt->bind_param("dddd", $price_km, $price_min, $base_fare, $commission_percent);

if ($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "error" => $conn->error]);
}
?>
