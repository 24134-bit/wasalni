<?php
// wasalni/backend/fix_balance.php
include 'db.php';

$phone = $_GET['phone'] ?? null;
$amount = $_GET['amount'] ?? null;

if (!$phone || !$amount) {
    die("Usage: fix_balance.php?phone=0123456789&amount=500");
}

try {
    $stmt = $conn->prepare("UPDATE users SET balance = COALESCE(balance, 0) + :amt WHERE phone = :phone");
    $stmt->execute(['amt' => (float)$amount, 'phone' => $phone]);
    
    if ($stmt->rowCount() > 0) {
        echo "Successfully added $amount to captain with phone $phone";
    } else {
        echo "No captain found with phone $phone";
    }
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
