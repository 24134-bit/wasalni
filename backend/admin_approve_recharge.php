<?php
header("Content-Type: application/json");
include 'db.php';

$id = $_POST['id'];
$action = $_POST['action']; // 'approve' or 'reject'

if(!$id || !$action) {
    echo json_encode(["success" => false, "error" => "Missing data"]);
    exit;
}

$status = ($action == 'approve') ? 'approved' : 'rejected';

$stmt = $conn->prepare("UPDATE deposits SET status = ? WHERE id = ?");
$stmt->bind_param("si", $status, $id);
$stmt->execute();

if ($action == 'approve') {
    // Get amount and driver_id
    $res = $conn->query("SELECT amount, driver_id FROM deposits WHERE id = $id");
    $row = $res->fetch_assoc();
    $amount = $row['amount'];
    $driver_id = $row['driver_id'];

    $conn->query("UPDATE users SET balance = balance + $amount WHERE id = $driver_id");
}

// Notify the driver
include_once 'send_notification_func.php';
$notifTitle = ($action == 'approve') ? "Depot Approuve" : "Depot Rejete";
$notifBody = ($action == 'approve') ? "Votre recharge de $amount MRU a ete approuvee." : "Votre recharge a ete rejetee. Veuillez contacter le support.";
send_notification($conn, 'driver', $driver_id, $notifTitle, $notifBody);

echo json_encode(["success" => true]);
?>
