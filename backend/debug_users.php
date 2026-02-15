<?php
header("Content-Type: text/plain");
include 'db.php';

echo "Tariki User Debug\n";
echo "================\n\n";

try {
    $stmt = $conn->query("SELECT id, phone, name, role FROM users LIMIT 20");
    $users = $stmt->fetchAll();

    foreach ($users as $user) {
        echo "ID: " . $user['id'] . " | Phone: " . $user['phone'] . " | Name: " . $user['name'] . " | Role: " . $user['role'] . "\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
