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
$activeCheck = $conn->prepare("SELECT id FROM rides WHERE driver_id = :driver_id AND status IN ('accepted', 'arrived', 'on_trip')");
$activeCheck->execute([':driver_id' => $driver_id]);
if($activeCheck->fetch()) {
    echo json_encode(["success" => false, "error" => "You already have an active ride"]);
    exit;
}

// 1. Get Ride Details and Driver Balance
$rideQuery = $conn->prepare("SELECT total_price, type FROM rides WHERE id = :ride_id");
$rideQuery->execute([':ride_id' => $ride_id]);
$rideResult = $rideQuery->fetch();

if (!$rideResult) {
    echo json_encode(["success" => false, "error" => "Ride not found"]);
    exit;
}

$price = $rideResult['total_price'];
$type = $rideResult['type'];

$driverQuery = $conn->prepare("SELECT balance FROM users WHERE id = :driver_id");
$driverQuery->execute([':driver_id' => $driver_id]);
$driverResult = $driverQuery->fetch();
$balance = (float)$driverResult['balance'];

// 2. Fetch Settings for Commission
$setQ = $conn->query("SELECT commission_percent FROM settings LIMIT 1");
$settings = $setQ->fetch();
$commParams = (float)($settings['commission_percent'] ?? 10);
$commission = $price * ($commParams / 100);

// 3. ENFORCE BALANCE RULES
if ($type == 'open') {
    // New Rule: Open rides require at least 50 MRU
    if ($balance < 50) {
        echo json_encode(["success" => false, "error" => "Minimum balance of 50 MRU required for open rides."]);
        exit;
    }
} else {
    // Fixed rides: Require at least the commission amount
    if ($balance < $commission) {
        echo json_encode(["success" => false, "error" => "Insufficient balance to cover the commission."]);
        exit;
    }
}

// 4. Update Ride Status ONLY (Commission is deducted in finish_ride.php)
$conn->beginTransaction();
try {
    // Update Ride
    $stmt = $conn->prepare("UPDATE rides SET status = 'accepted', driver_id = :driver_id, start_time = CURRENT_TIMESTAMP WHERE id = :ride_id AND status = 'pending'");
    $stmt->execute([':driver_id' => $driver_id, ':ride_id' => $ride_id]);
    
    if ($stmt->rowCount() == 0) throw new Exception("Ride already accepted or no longer available.");

    $conn->commit();
    echo json_encode(["success" => true]);

} catch (Exception $e) {
    if ($conn->inTransaction()) $conn->rollBack();
    echo json_encode(["success" => false, "error" => $e->getMessage()]);
}
?>
