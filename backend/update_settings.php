<?php
include 'db.php';

$price_km = $_POST['price_km'];
$price_min = $_POST['price_min'];
$base_fare = $_POST['base_fare'];
$commission_percent = $_POST['commission_percent'] ?? 10;

try {
    $stmt = $conn->prepare("UPDATE settings SET price_km = :price_km, price_min = :price_min, base_fare = :base_fare, commission_percent = :commission WHERE id = 1");
    $stmt->execute([
        ':price_km' => $price_km,
        ':price_min' => $price_min,
        ':base_fare' => $base_fare,
        ':commission' => $commission_percent
    ]);
    echo json_encode(["success" => true]);
} catch (PDOException $e) {
    echo json_encode(["success" => false, "error" => "Update failed: " . $e->getMessage()]);
}
?>
