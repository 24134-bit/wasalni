<?php
header("Content-Type: application/json");
include 'db.php';

// Get online captains for the map (Team View)
$sql = "SELECT id, name, car_number, last_lat, last_lng FROM users WHERE role = 'driver' AND is_online = 1";
$result = $conn->query($sql);

$captains = [];
while($row = $result->fetch_assoc()) {
    $captains[] = $row;
}

echo json_encode($captains);
?>
