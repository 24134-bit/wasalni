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

    // 4. Notify Drivers that the ride is gone
    include_once 'send_notification_func.php';
    send_notification($conn, 'driver', null, 'إلغاء رحلة من المسؤول', "الرحلة رقم #$ride_id تم إلغاؤها من قبل الإدارة.");

    $conn->commit();
    echo json_encode(["success" => true]);

} catch (Exception $e) {
    $conn->rollBack();
    echo json_encode(["success" => false, "error" => $e->getMessage()]);
}
?>
