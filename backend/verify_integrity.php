<?php
// wasalni/backend/verify_integrity.php
include 'db.php';
header("Content-Type: text/html; charset=UTF-8");

echo "<h1>Wasalni Integrity Check</h1>";

try {
    // 1. Check for deposits with invalid driver_ids
    echo "<h3>Checking for Orphan Deposits (No matching User):</h3>";
    $stmt = $conn->query("SELECT d.id, d.driver_id, d.amount FROM deposits d LEFT JOIN users u ON d.driver_id = u.id WHERE u.id IS NULL");
    $orphans = $stmt->fetchAll();
    
    if (empty($orphans)) {
        echo "<p style='color:green;'>All deposits are linked to valid users.</p>";
    } else {
        echo "<p style='color:red;'>Found " . count($orphans) . " broken deposits!</p><ul>";
        foreach ($orphans as $o) {
            echo "<li>Deposit ID: {$o['id']} has Driver ID: <b>{$o['driver_id']}</b> (This ID does not exist in users table!)</li>";
        }
        echo "</ul>";
    }

    // 2. Check for balance types
    echo "<h3>Users Table Balance Column Status:</h3>";
    $stmt = $conn->query("DESCRIBE users");
    while ($row = $stmt->fetch()) {
        if ($row['Field'] == 'balance') {
            echo "<p>Balance column type: <b>{$row['Type']}</b>, Nullable: <b>{$row['Null']}</b>, Default: <b>{$row['Default']}</b></p>";
        }
    }

    // 3. Current State of Captains
    echo "<h3>Captains in Database:</h3><table border='1'>";
    echo "<tr><th>ID</th><th>Name</th><th>Phone</th><th>Balance</th></tr>";
    $stmt = $conn->query("SELECT id, name, phone, balance FROM users WHERE role='driver'");
    while ($row = $stmt->fetch()) {
        echo "<tr><td>{$row['id']}</td><td>{$row['name']}</td><td>{$row['phone']}</td><td>{$row['balance']}</td></tr>";
    }
    echo "</table>";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
