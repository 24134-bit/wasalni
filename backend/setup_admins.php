<?php
header("Content-Type: application/json");
include 'db.php';

echo "<h1>Tariki Admin Setup</h1>";

try {
    // 1. Add Admin 1
    $stmt1 = $conn->prepare("INSERT INTO users (phone, password, name, role, balance) VALUES ('31003874', 'adminMah9090', 'Admin Mah', 'admin', 0.00) ON CONFLICT (phone) DO UPDATE SET password = EXCLUDED.password, role = 'admin'");
    $stmt1->execute();
    echo "<p>Admin 31003874: OK</p>";

    // 2. Add Admin 2
    $stmt2 = $conn->prepare("INSERT INTO users (phone, password, name, role, balance) VALUES ('47010944', 'adminAbd9090', 'Admin Abd', 'admin', 0.00) ON CONFLICT (phone) DO UPDATE SET password = EXCLUDED.password, role = 'admin'");
    $stmt2->execute();
    echo "<p>Admin 47010944: OK</p>";

    // 3. Remove Default Admin
    $stmt3 = $conn->prepare("DELETE FROM users WHERE phone = 'admin'");
    $stmt3->execute();
    echo "<p>Default 'admin' removed: OK</p>";

    echo "<h2>✅ Setup Complete</h2>";
    echo "<p>Please delete this file for security.</p>";

} catch (Exception $e) {
    echo "<p style='color:red;'>Error: " . $e->getMessage() . "</p>";
}
?>
