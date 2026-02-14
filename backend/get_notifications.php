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

$sql = "SELECT * FROM notifications WHERE id > :last_id AND (
            (target_role = 'all') 
            OR (target_role = :role AND target_user_id IS NULL) 
            OR (target_user_id = :user_id)
        ) ORDER BY id ASC";

try {
    $stmt = $conn->prepare($sql);
    $stmt->execute([
        ':last_id' => $last_id,
        ':role' => $role,
        ':user_id' => $user_id
    ]);
    $notifs = $stmt->fetchAll();
    echo json_encode($notifs);
} catch (PDOException $e) {
    echo json_encode([]);
}
?>
