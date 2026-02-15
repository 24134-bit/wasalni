<?php
header("Content-Type: application/json");
include 'db.php';

$ride_id = $_POST['ride_id'];

if(!$ride_id) {
    echo json_encode(["success" => false, "error" => "Missing ID"]);
    exit;
}

$d_lat = $_POST['d_lat'] ?? 0;
$d_lng = $_POST['d_lng'] ?? 0;

try {
    $conn->beginTransaction();

    // 1. Fetch Ride and Settings with locking to prevent race conditions
    // Use PostgreSQL specific extraction to get minutes (DB logic)
    $q = $conn->prepare("SELECT *, (EXTRACT(EPOCH FROM CURRENT_TIMESTAMP) - EXTRACT(EPOCH FROM start_time))/60 as duration_min FROM rides WHERE id = :ride_id FOR UPDATE");
    $q->execute([':ride_id' => $ride_id]);
    $ride = $q->fetch();

    if (!$ride) {
        throw new Exception("Ride not found");
    }

    if ($ride['status'] === 'delivered') {
        $conn->rollBack();
        echo json_encode(["success" => true, "message" => "Already finished"]);
        exit;
    }

    $sQuery = $conn->query("SELECT * FROM settings LIMIT 1");
    $settings = $sQuery->fetch();
    $commRate = (float)($settings['commission_percent'] ?? 10.0);
    $driver_id = (int)$ride['driver_id'];

    // 2. Determine Final Trip Price
    if ($ride['type'] == 'open') {
        // Calculate dynamic price for open rides: Base + Minutes
        $duration_min = (int)$ride['duration_min'];
        if($duration_min < 0) $duration_min = 0;

        $final_price = (float)$settings['base_fare'] + ($duration_min * (float)$settings['price_min']);
        $final_price = round($final_price, 2);

        // Update ride with calculated price
        $stmt = $conn->prepare("UPDATE rides SET status = 'delivered', dropoff_lat = :d_lat, dropoff_lng = :d_lng, total_price = :price, end_time = CURRENT_TIMESTAMP WHERE id = :ride_id");
        $stmt->execute([
            ':d_lat' => $d_lat,
            ':d_lng' => $d_lng,
            ':price' => $final_price,
            ':ride_id' => $ride_id
        ]);
    } else {
        // Fixed price ride
        $final_price = (float)$ride['total_price'];
        $stmt = $conn->prepare("UPDATE rides SET status = 'delivered', end_time = CURRENT_TIMESTAMP WHERE id = :ride_id");
        $stmt->execute([':ride_id' => $ride_id]);
    }

    // 3. Automated Commission Deduction (only if not already done)
    $commission = 0;
    if ($driver_id > 0) {
        // EXACT FORMULA: balance = balance - (ride_price * commission_percent / 100)
        $commission = $final_price * ($commRate / 100);
        $commission = round($commission, 2);
        
        $uBal = $conn->prepare("UPDATE users SET balance = COALESCE(balance, 0) - :commission WHERE id = :driver_id");
        $uBal->execute([':commission' => $commission, ':driver_id' => $driver_id]);
    }

    $conn->commit();
    echo json_encode(["success" => true, "final_price" => $final_price, "commission_deducted" => $commission ?? 0]);

} catch (Exception $e) {
    if ($conn->inTransaction()) $conn->rollBack();
    echo json_encode(["success" => false, "error" => $e->getMessage()]);
}
?>
