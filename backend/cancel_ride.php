<?php
header("Content-Type: application/json");
include 'db.php';

$ride_id = $_POST['ride_id'];
$driver_id = $_POST['driver_id']; // Who is cancelling? (Assuming driver for now or admin)

if(!$ride_id) {
    echo json_encode(["success" => false, "error" => "Missing data"]);
    exit;
}

$conn->beginTransaction();
try {
    // 1. Get Ride Details (Price and Driver)
    $stmt = $conn->prepare("SELECT total_price, driver_id, status FROM rides WHERE id = :id");
    $stmt->execute([':id' => $ride_id]);
    $ride = $stmt->fetch();

    if (!$ride) throw new Exception("Ride not found");
    
    // Allowed statuses for Captain to "Release" a ride (reset to pending)
    $allowed = ['pending', 'accepted', 'arrived', 'on_trip'];
    if (!in_array($ride['status'], $allowed)) {
        throw new Exception("Cannot cancel/release from this status: " . $ride['status']);
    }

    $assigned_driver = $ride['driver_id'];

    // 3. Mark Ride as Pending again (Release)
    $updateRide = $conn->prepare("UPDATE rides SET status = 'pending', driver_id = NULL WHERE id = :id");
    $updateRide->execute([':id' => $ride_id]);

    // 4. Notify Admins
    include_once 'send_notification_func.php';
    // Fetch current captain info for the notification
    $dInfo = $conn->prepare("SELECT name, phone FROM users WHERE id = :driver_id");
    $dInfo->execute([':driver_id' => $driver_id]);
    $driver = $dInfo->fetch();
    $dName = $driver['name'] ?? 'Unknown';
    $dPhone = $driver['phone'] ?? 'Unknown';

    send_notification($conn, 'admin', null, 'إلغاء استلام رحلة', "الكابتن ($dName - $dPhone) قام بإلغاء استلام الرحلة رقم #$ride_id وباتت متاحة مجدداً.");

    $conn->commit();
    echo json_encode(["success" => true]);

} catch (Exception $e) {
    $conn->rollBack();
    echo json_encode(["success" => false, "error" => $e->getMessage()]);
}
?>
