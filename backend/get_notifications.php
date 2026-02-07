<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Content-Type: application/json");
include 'db.php';

$user_id = $_GET['user_id'] ?? null;
$role = $_GET['role'] ?? 'driver'; // 'admin' or 'driver'
$last_id = $_GET['last_id'] ?? 0;

if (!$user_id && $role !== 'admin') {
    echo json_encode([]);
    exit;
}

// Fetch notifications that possess an ID greater than last_id
// targeted at: 
// 1. My specific user ID
// 2. OR my role (e.g. 'driver' or 'admin')
// 3. OR 'all'

$sql = "SELECT * FROM notifications WHERE id > ? AND (
            (target_role = 'all') 
            OR (target_role = ? AND target_user_id IS NULL) 
            OR (target_user_id = ?)
        ) ORDER BY id ASC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("isi", $last_id, $role, $user_id);
$stmt->execute();
$result = $stmt->get_result();

$notifs = [];
while ($row = $result->fetch_assoc()) {
    $notifs[] = $row;
}

echo json_encode($notifs);
?>
