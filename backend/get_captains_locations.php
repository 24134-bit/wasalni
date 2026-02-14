<?php
header("Content-Type: application/json");
include 'db.php';

// Get online captains for the map (Team View)
$sql = "SELECT id, name, car_number, last_lat, last_lng FROM users WHERE role = 'driver' AND is_online = 1";
try {
    $stmt = $conn->query($sql);
    $captains = $stmt->fetchAll();
    echo json_encode($captains);
} catch (PDOException $e) {
    echo json_encode([]);
}
?>
