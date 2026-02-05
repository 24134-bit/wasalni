<?php
header("Content-Type: application/json");
include 'db.php';

$ride_id = $_POST['ride_id'];
$driver_id = $_POST['driver_id']; // Who is cancelling? (Assuming driver for now or admin)

if(!$ride_id) {
    echo json_encode(["success" => false, "error" => "Missing data"]);
    exit;
}

$conn->begin_transaction();
try {
    // 1. Get Ride Details (Price and Driver)
    $stmt = $conn->prepare("SELECT total_price, driver_id, status FROM rides WHERE id = ?");
    $stmt->bind_param("i", $ride_id);
    $stmt->execute();
    $ride = $stmt->get_result()->fetch_assoc();

    if ($ride['status'] != 'accepted' && $ride['status'] != 'arrived') {
        throw new Exception("Cannot cancel logic for this status");
    }

    $price = $ride['total_price'];
    $assigned_driver = $ride['driver_id'];
    $commission = $price * 0.10;

    // 2. Refund Commission to Driver
    $refundObj = $conn->prepare("UPDATE users SET balance = balance + ? WHERE id = ?");
    $refundObj->bind_param("di", $commission, $assigned_driver);
    $refundObj->execute();

    // 3. Mark Ride as Cancelled (or reset to pending depending on business logic)
    // User requested: "degeler" (unfreeze). If cancelled, we assume it's dead.
    $updateRide = $conn->prepare("UPDATE rides SET status = 'pending', driver_id = NULL WHERE id = ?");
    $updateRide->bind_param("i", $ride_id);
    $updateRide->execute();

    $conn->commit();
    echo json_encode(["success" => true]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "error" => $e->getMessage()]);
}
?>
