<?php
// Headers are handled in db.php

include 'db.php';

$driver_id = $_POST['driver_id'] ?? 0;
$lat = $_POST['lat'] ?? 0;
$lng = $_POST['lng'] ?? 0;
$is_online = $_POST['is_online'] ?? 1;

if (!$driver_id) {
    echo json_encode(["success" => false, "error" => "Missing driver ID"]);
    exit;
}

// Check if columns exist, if not we might fail. Assuming setup.sql was run.
try {
    $stmt = $conn->prepare("UPDATE users SET last_lat = :lat, last_lng = :lng, is_online = :is_online WHERE id = :id");
    $stmt->execute([
        ':lat' => $lat,
        ':lng' => $lng,
        ':is_online' => $is_online,
        ':id' => $driver_id
    ]);
    echo json_encode(["success" => true]);
} catch (PDOException $e) {
    echo json_encode(["success" => false, "error" => "Update failed: " . $e->getMessage()]);
}
?>
