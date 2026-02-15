<?php
header("Content-Type: application/json");
error_reporting(E_ALL);
ini_set('display_errors', 1);
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

    // 3. Mark Ride as cancelled
    $updateRide = $conn->prepare("UPDATE rides SET status = 'cancelled' WHERE id = :id");
    $updateRide->execute([':id' => $ride_id]);

    if ($updateRide->rowCount() === 0) {
        // Did it fail or was it already cancelled?
        $check = $conn->prepare("SELECT status FROM rides WHERE id = :id");
        $check->execute([':id' => $ride_id]);
        $curr = $check->fetch();
        if (!$curr) throw new Exception("Ride record vanished during update");
        if ($curr['status'] === 'cancelled') throw new Exception("Ride is already cancelled");
        throw new Exception("Status update failed for unknown reason (check constraints)");
    }

    // 4. Notify Drivers that the ride is gone
    include_once 'send_notification_func.php';
    send_notification($conn, 'driver', null, 'إلغاء رحلة من المسؤول', "الرحلة رقم #$ride_id تم إلغاؤها من قبل الإدارة.");

    $conn->commit();
    echo json_encode(["success" => true, "ride_id" => $ride_id]);

} catch (Exception $e) {
    $conn->rollBack();
    echo json_encode(["success" => false, "error" => $e->getMessage()]);
}
?>
