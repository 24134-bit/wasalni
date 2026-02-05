<?php
header("Content-Type: application/json");
include 'db.php';

$action = $_GET['action'] ?? 'list';
$driver_id = $_GET['driver_id'] ?? 0;

if ($action == 'list') {
    // Show pending rides for drivers
    $sql = "SELECT * FROM rides WHERE status = 'pending'";
    $result = $conn->query($sql);
    $rides = [];
    while($row = $result->fetch_assoc()) {
        $rides[] = $row;
    }
    echo json_encode($rides);
} 
else if ($action == 'list_all') {
    // Show all active/pending/on_trip rides for Admin
    $sql = "SELECT * FROM rides WHERE status NOT IN ('delivered', 'cancelled') ORDER BY id DESC";
    $result = $conn->query($sql);
    $rides = [];
    while($row = $result->fetch_assoc()) {
        $rides[] = $row;
    }
    echo json_encode($rides);
}
?>
