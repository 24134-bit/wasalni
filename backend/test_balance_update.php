<?php
// wasalni/backend/test_balance_update.php
include 'db.php';

echo "<h2>Wasalni Balance Update Tester</h2>";

// 1. Get a random driver ID
$stmt = $conn->query("SELECT id, name, balance FROM users WHERE role = 'driver' LIMIT 1");
$driver = $stmt->fetch();

if (!$driver) {
    die("Error: No drivers (captains) found in database. Please add a captain first.");
}

$did = $driver['id'];
$old_bal = $driver['balance'];

echo "<p>Found Captain: <b>" . $driver['name'] . "</b> (ID: $did)</p>";
echo "<p>Current Balance: <b>" . $old_bal . "</b></p>";

// 2. Perform Update
$amount_to_add = 10.50;
echo "<p>Attempting to add <b>$amount_to_add</b>...</p>";

$update = $conn->prepare("UPDATE users SET balance = COALESCE(balance, 0) + :amt WHERE id = :id");
$update->execute(['amt' => $amount_to_add, 'id' => $did]);

if ($update->rowCount() > 0) {
    echo "<p style='color:green;'>SUCCESS: Row updated!</p>";
    
    // 3. Verify
    $verify = $conn->prepare("SELECT balance FROM users WHERE id = :id");
    $verify->execute(['id' => $did]);
    $new_bal = $verify->fetch()['balance'];
    echo "<p>New Balance in Database: <b>" . $new_bal . "</b></p>";
} else {
    echo "<p style='color:red;'>FAILED: Row not updated. Check if ID exists.</p>";
}
?>
