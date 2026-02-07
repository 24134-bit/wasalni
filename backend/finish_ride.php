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

// Get Ride Info
$q = $conn->prepare("SELECT type, pickup_lat, pickup_lng, start_time FROM rides WHERE id = ?");
$q->bind_param("i", $ride_id);
$q->execute();
$ride = $q->get_result()->fetch_assoc();

if ($ride['type'] == 'open') {
    // Calculate Price
    include 'price_helper.php'; // ensure this has helper functions or fetch settings manually
    
    // Fetch Settings
    $sQuery = $conn->query("SELECT * FROM settings WHERE id = 1");
    $settings = $sQuery->fetch_assoc();
    
    $startTime = strtotime($ride['start_time']);
    $endTime = time();
    $duration_min = round(($endTime - $startTime) / 60, 2);
    if($duration_min < 0) $duration_min = 0;

    // Calculate Distance (Haversine)
    function distance($lat1, $lon1, $lat2, $lon2) {
        if (($lat1 == $lat2) && ($lon1 == $lon2)) return 0;
        $theta = $lon1 - $lon2;
        $dist = sin(deg2rad($lat1)) * sin(deg2rad($lat2)) +  cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
        $dist = acos($dist);
        $dist = rad2deg($dist);
        $miles = $dist * 60 * 1.1515;
        return $miles * 1.609344;
    }

    $dist_km = distance($ride['pickup_lat'], $ride['pickup_lng'], $d_lat, $d_lng);
    
    $final_price = $settings['base_fare'] + ($dist_km * $settings['price_km']) + ($duration_min * $settings['price_min']);
    $final_price = round($final_price, 2);

    // Start Transaction for updating ride and deducting balance
    $conn->begin_transaction();
    try {
        // Update Ride with Price, Location, End Time
        $stmt = $conn->prepare("UPDATE rides SET status = 'delivered', dropoff_lat = ?, dropoff_lng = ?, total_price = ?, end_time = CURRENT_TIMESTAMP WHERE id = ?");
        $stmt->bind_param("dddi", $d_lat, $d_lng, $final_price, $ride_id);
        $stmt->execute();

        // Get Driver ID
        $dQuery = $conn->prepare("SELECT driver_id FROM rides WHERE id = ?");
        $dQuery->bind_param("i", $ride_id);
        $dQuery->execute();
        $driver_id = $dQuery->get_result()->fetch_assoc()['driver_id'];

        if($driver_id) {
            $commRate = $settings['commission_percent'] ?? 10;
            $commission = $final_price * ($commRate / 100);
            
            // Deduct from balance
            $uBal = $conn->prepare("UPDATE users SET balance = balance - ? WHERE id = ?");
            $uBal->bind_param("di", $commission, $driver_id);
            $uBal->execute();
        }

        $conn->commit();
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(["success" => false, "error" => $e->getMessage()]);
        exit;
    }
} else {
    // Closed ride, price already set. Just mark delivered.
    // NOTE: For closed rides, commission is ALREADY deducted in take_ride.php
    $stmt = $conn->prepare("UPDATE rides SET status = 'delivered', end_time = CURRENT_TIMESTAMP WHERE id = ?");
    $stmt->bind_param("i", $ride_id);
    $stmt->execute();
}

if($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "error" => "Update failed: " . $conn->error]);
}
?>
