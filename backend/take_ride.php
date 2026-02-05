<?php
header("Content-Type: application/json");
include 'db.php';

$ride_id = $_POST['ride_id'];
$driver_id = $_POST['driver_id'];

if(!$ride_id || !$driver_id) {
    echo json_encode(["success" => false, "error" => "Missing data"]);
    exit;
}

// 0. Check if driver already has an active ride
$activeCheck = $conn->prepare("SELECT id FROM rides WHERE driver_id = ? AND status IN ('accepted', 'arrived', 'on_trip')");
$activeCheck->bind_param("i", $driver_id);
$activeCheck->execute();
if($activeCheck->get_result()->num_rows > 0) {
    echo json_encode(["success" => false, "error" => "You already have an active ride"]);
    exit;
}

// 1. Get Ride Price and Driver Balance
$rideQuery = $conn->prepare("SELECT total_price FROM rides WHERE id = ?");
$rideQuery->bind_param("i", $ride_id);
$rideQuery->execute();
$rideResult = $rideQuery->get_result()->fetch_assoc();
$price = $rideResult['total_price'];

$driverQuery = $conn->prepare("SELECT balance FROM users WHERE id = ?");
$driverQuery->bind_param("i", $driver_id);
$driverQuery->execute();
$driverResult = $driverQuery->get_result()->fetch_assoc();
$balance = $driverResult['balance'];

// 2. Calculate Commission (10%)
$commission = $price * 0.10;

// 3. Check if driver has enough balance
if ($balance < $commission) {
    echo json_encode(["success" => false, "error" => "Insufficient balance for commission"]);
    exit;
}

// 4. Update Ride Status and Deduct Balance
$conn->begin_transaction();
try {
    // Update Ride
    $stmt = $conn->prepare("UPDATE rides SET status = 'accepted', driver_id = ? WHERE id = ? AND status = 'pending'");
    $stmt->bind_param("ii", $driver_id, $ride_id);
    $stmt->execute();
    
    if ($stmt->affected_rows == 0) throw new Exception("Ride not available");

    // Deduct Commission
    $updateBal = $conn->prepare("UPDATE users SET balance = balance - ? WHERE id = ?");
    $updateBal->bind_param("di", $commission, $driver_id);
    $updateBal->execute();

    // Record Transaction (Optional: keep track of freezes)
    // For simplicity, we just deduct. If cancelled, we add it back.

    $conn->commit();
    echo json_encode(["success" => true]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "error" => $e->getMessage()]);
}
?>
