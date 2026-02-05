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

echo json_encode(["success" => true]);
?>
