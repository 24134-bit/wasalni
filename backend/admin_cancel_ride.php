<?php
header("Content-Type: application/json");
include 'db.php';

$ride_id = $_POST['ride_id'] ?? '';

if(!$ride_id) {
    echo json_encode(["success" => false, "error" => "Missing Ride ID"]);
    exit;
}

$conn->beginTransaction();
try {
    // 1. Get Ride Details
    $stmt = $conn->prepare("SELECT total_price, driver_id, status FROM rides WHERE id = :id");
    $stmt->execute([':id' => $ride_id]);
    $ride = $stmt->fetch();

    if (!$ride) throw new Exception("Ride not found");

    $price = $ride['total_price'];
    $assigned_driver = $ride['driver_id'];
    $status = $ride['status'];

    // 2. Commission is NOT deducted until ride is finished, so no refund needed.

    // 3. Mark Ride as cancelled
    $updateRide = $conn->prepare("UPDATE rides SET status = 'cancelled' WHERE id = :id");
    $updateRide->execute([':id' => $ride_id]);

    $conn->commit();
    echo json_encode(["success" => true]);

} catch (Exception $e) {
    $conn->rollBack();
    echo json_encode(["success" => false, "error" => $e->getMessage()]);
}
?>
