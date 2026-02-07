<?php
header("Content-Type: application/json");
include 'db.php';

$pickup = $_POST['pickup'] ?? '';
$dropoff = $_POST['dropoff'] ?? '';
$p_lat = $_POST['p_lat'] ?? 0;
$p_lng = $_POST['p_lng'] ?? 0;
$d_lat = $_POST['d_lat'] ?? 0;
$d_lng = $_POST['d_lng'] ?? 0;
$price = $_POST['price'] ?? 0;
$customer_phone = $_POST['customer_phone'] ?? '';

$type = $_POST['type'] ?? 'closed'; // 'open' or 'closed'

if ($type == 'closed') {
    if (!$pickup || !$dropoff || !$price) {
        echo json_encode(["success" => false, "error" => "Missing info for closed ride"]);
        exit;
    }
} else {
    // Open ride
    if (!$pickup) {
        echo json_encode(["success" => false, "error" => "Pickup required for open ride"]);
        exit;
    }
    $dropoff = "Open Destination"; // Placeholder
    $price = 0; // To be calculated
}

$sql = "INSERT INTO rides (pickup_address, dropoff_address, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, total_price, customer_phone, status, type) 
        VALUES (:pickup, :dropoff, :p_lat, :p_lng, :d_lat, :d_lng, :price, :customer_phone, 'pending', :type)";
$stmt = $conn->prepare($sql);

try {
    $stmt->execute([
        'pickup' => $pickup,
        'dropoff' => $dropoff,
        'p_lat' => $p_lat,
        'p_lng' => $p_lng,
        'd_lat' => $d_lat,
        'd_lng' => $d_lng,
        'price' => $price,
        'customer_phone' => $customer_phone,
        'type' => $type
    ]);

    include_once 'send_notification_func.php';
    // Notify Admins
    send_notification($conn, 'admin', null, 'رحلة جديدة', 'تم إنشاء رحلة جديدة من قبل المسؤول.');
    // Notify All Drivers (Broadcast)
    $notifTitle = ($type == 'open') ? 'رحلة مفتوحة جديدة' : 'رحلة جديدة متاحة';
    send_notification($conn, 'driver', null, $notifTitle, 'تحقق من القائمة!');
    
    echo json_encode(["success" => true]);
} catch (PDOException $e) {
    echo json_encode(["success" => false, "error" => "Failed: " . $e->getMessage()]);
}
?>
