<?php
// Headers are handled in db.php
include 'db.php';

$driver_id = $_GET['driver_id'] ?? 0;

if (!$driver_id) {
    echo json_encode(["success" => false, "error" => "Missing ID"]);
    exit;
}

try {
    // 1. Get User Info
    $stmt = $conn->prepare("SELECT name, balance, photo_path FROM users WHERE id = :driver_id");
    $stmt->execute([':driver_id' => $driver_id]);
    $user = $stmt->fetch();

    if (!$user) {
        echo json_encode(["success" => false, "error" => "Captain ID ($driver_id) not found in database."]);
        exit;
    }

    $balance = (float)$user['balance'];

    // 2. Fetch Settings for display
    $setQ = $conn->query("SELECT commission_percent FROM settings LIMIT 1");
    $settings = $setQ->fetch();
    $commRate = (float)($settings['commission_percent'] ?? 10);

    // 3. Transactions
    $transactions = [];

    // Deposits
    $d_stmt = $conn->prepare("SELECT id, amount, reference_number, method, status, created_at FROM deposits WHERE driver_id = :driver_id ORDER BY created_at DESC");
    $d_stmt->execute([':driver_id' => $driver_id]);
    $deposits = $d_stmt->fetchAll();
    foreach($deposits as $d) {
        $transactions[] = [
            "type" => "deposit",
            "description" => $d['method'] . " (Ref: " . ($d['reference_number'] ?? 'N/A') . ")",
            "amount" => (float)$d['amount'],
            "status" => $d['status'],
            "date" => $d['created_at']
        ];
    }

    // Rides
    $r_stmt = $conn->prepare("SELECT id, total_price, pickup_address, dropoff_address, created_at FROM rides WHERE driver_id = :driver_id AND status = 'delivered' ORDER BY created_at DESC");
    $r_stmt->execute([':driver_id' => $driver_id]);
    $rides = $r_stmt->fetchAll();
    foreach($rides as $r) {
        $commission = (float)$r['total_price'] * ($commRate / 100); 
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
        "name" => $user['name'],
        "balance" => $balance,
        "photo_path" => $user['photo_path'],
        "transactions" => $transactions
    ]);

} catch (Exception $e) {
    echo json_encode(["success" => false, "error" => "Wallet Error: " . $e->getMessage()]);
}
?>
