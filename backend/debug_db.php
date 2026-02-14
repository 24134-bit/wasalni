<?php
// wasalni/backend/debug_db.php
include 'db.php';
header("Content-Type: text/html; charset=UTF-8");

echo "<h1>Wasalni Database Debugger</h1>";

try {
    // 1. Connection check
    echo "<h3>1. Connection Status: <span style='color:green;'>Connected</span></h3>";
    
    // 2. Table check
    $tables = ['users', 'deposits', 'settings', 'notifications'];
    echo "<h3>2. Tables Check:</h3><ul>";
    foreach ($tables as $table) {
        try {
            $stmt = $conn->query("SELECT COUNT(*) FROM $table");
            $count = $stmt->fetchColumn();
            echo "<li>Table <b>$table</b> exists. Rows: $count</li>";
        } catch (Exception $e) {
            echo "<li style='color:red;'>Table <b>$table</b> is MISSING! Error: " . $e->getMessage() . "</li>";
        }
    }
    echo "</ul>";

    // 3. Captains List
    echo "<h3>3. Captains (Drivers) Data:</h3><table border='1' cellpadding='5'>
    <tr><th>ID</th><th>Phone</th><th>Name</th><th>Balance</th><th>Role</th></tr>";
    $stmt = $conn->query("SELECT id, phone, name, balance, role FROM users WHERE role = 'driver' OR role = 'admin'");
    while ($row = $stmt->fetch()) {
        echo "<tr><td>{$row['id']}</td><td>{$row['phone']}</td><td>{$row['name']}</td><td><b>{$row['balance']}</b></td><td>{$row['role']}</td></tr>";
    }
    echo "</table>";

    // 4. Pending Deposits
    echo "<h3>4. Pending Deposits:</h3><table border='1' cellpadding='5'>
    <tr><th>ID</th><th>Driver ID</th><th>Amount</th><th>Ref</th><th>Status</th></tr>";
    $stmt = $conn->query("SELECT id, driver_id, amount, reference_number, status FROM deposits WHERE status = 'pending'");
    while ($row = $stmt->fetch()) {
        echo "<tr><td>{$row['id']}</td><td>{$row['driver_id']}</td><td>{$row['amount']}</td><td>{$row['reference_number']}</td><td>{$row['status']}</td></tr>";
    }
    echo "</table>";

} catch (Exception $e) {
    echo "<h2><span style='color:red;'>FAILED:</span> " . $e->getMessage() . "</h2>";
}
?>
