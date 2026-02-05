<?php
header("Content-Type: application/json");
include 'db.php';

$ride_id = $_POST['ride_id'] ?? '';

if(!$ride_id) {
    echo json_encode(["success" => false, "error" => "Missing Ride ID"]);
    exit;
}

$conn->begin_transaction();
try {
    // 1. Get Ride Details
    $stmt = $conn->prepare("SELECT total_price, driver_id, status FROM rides WHERE id = ?");
    $stmt->bind_param("i", $ride_id);
    $stmt->execute();
    $ride = $stmt->get_result()->fetch_assoc();

    if (!$ride) throw new Exception("Ride not found");

    $price = $ride['total_price'];
    $assigned_driver = $ride['driver_id'];
    $status = $ride['status'];

    // 2. Refund Commission if the ride was accepted
    if ($assigned_driver && ($status == 'accepted' || $status == 'arrived' || $status == 'on_trip')) {
        $commission = $price * 0.10;
        $refundObj = $conn->prepare("UPDATE users SET balance = balance + ? WHERE id = ?");
        $refundObj->bind_param("di", $commission, $assigned_driver);
        $refundObj->execute();
    }

    // 3. Mark Ride as cancelled
    $updateRide = $conn->prepare("UPDATE rides SET status = 'cancelled' WHERE id = ?");
    $updateRide->bind_param("i", $ride_id);
    $updateRide->execute();

    $conn->commit();
    echo json_encode(["success" => true]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "error" => $e->getMessage()]);
}
?>
