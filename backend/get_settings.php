<?php
include 'db.php';
try {
    $stmt = $conn->query("SELECT * FROM settings ORDER BY id DESC LIMIT 1");
    $settings = $stmt->fetch();
    if ($settings) {
        echo json_encode($settings);
    } else {
        echo json_encode(["price_km" => 10, "price_min" => 1, "base_fare" => 5]);
    }
} catch (PDOException $e) {
    echo json_encode(["price_km" => 10, "price_min" => 1, "base_fare" => 5]);
}
?>
