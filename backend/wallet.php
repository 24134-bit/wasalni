<?php
// Headers are handled in db.php

include 'db.php';

$driver_id = $_GET['driver_id'] ?? 0;

if (!$driver_id) {
    echo json_encode(["success" => false, "error" => "Missing ID"]);
    exit;
}

// 1. Get User Info
$stmt = $conn->prepare("SELECT name, balance, photo_path FROM users WHERE id = ?");
$stmt->bind_param("i", $driver_id);
$stmt->execute();
$res = $stmt->get_result();
$user_info = ["name" => "Captain", "balance" => 0.00, "photo_path" => ""];
if($res->num_rows > 0) {
    $user_info = $res->fetch_assoc();
}
$balance = $user_info['balance'];

// 2. Fetch Settings for display
$setQ = $conn->query("SELECT commission_percent FROM settings LIMIT 1");
$settings = $setQ->fetch_assoc();
$commRate = $settings['commission_percent'] ?? 10;

// 3. Transactions
$transactions = [];

// Deposits
$d_stmt = $conn->prepare("SELECT id, amount, reference_number, method, status, created_at FROM deposits WHERE driver_id = ? ORDER BY created_at DESC");
$d_stmt->bind_param("i", $driver_id);
$d_stmt->execute();
$deposits = $d_stmt->get_result()->fetch_all(MYSQLI_ASSOC);
foreach($deposits as $d) {
    $transactions[] = [
        "type" => "deposit",
        "description" => "Recharge via " . $d['method'] . " (Ref: " . ($d['reference_number'] ?? 'N/A') . ")",
        "amount" => $d['amount'],
        "status" => $d['status'],
        "date" => $d['created_at']
    ];
}

// Rides
$r_stmt = $conn->prepare("SELECT id, total_price, pickup_address, dropoff_address, created_at FROM rides WHERE driver_id = ? AND status = 'delivered' ORDER BY created_at DESC");
$r_stmt->bind_param("i", $driver_id);
$r_stmt->execute();
$rides = $r_stmt->get_result()->fetch_all(MYSQLI_ASSOC);
foreach($rides as $r) {
    // Note: We use the rate from settings for display, 
    // but ideally the actual deduction amount should be stored in a transactions table.
    // For now, we calculate based on current rate or assume it was correct at the time.
    $commission = $r['total_price'] * ($commRate / 100); 
    $transactions[] = [
        "type" => "deduction",
        "description" => "Ride #" . $r['id'] . " Commission ($commRate%)",
        "amount" => -$commission,
        "status" => "completed",
        "date" => $r['created_at']
    ];
}

usort($transactions, function($a, $b) {
    return strtotime($b['date']) - strtotime($a['date']);
});

echo json_encode([
    "success" => true,
    "name" => $user_info['name'],
    "balance" => $balance,
    "photo_path" => $user_info['photo_path'],
    "transactions" => $transactions
]);
?>
