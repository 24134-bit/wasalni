<?php
header("Content-Type: application/json");
include 'db.php';

$ride_id = $_POST['ride_id'];

if(!$ride_id) {
    echo json_encode(["success" => false, "error" => "Missing ID"]);
    exit;
}

// Mark as delivered
// Since commission was already deducted (frozen) in take_ride.php, 
// we just complete the status here.
$stmt = $conn->prepare("UPDATE rides SET status = 'delivered' WHERE id = ?");
$stmt->bind_param("i", $ride_id);

if($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "error" => "Update failed"]);
}
?>
