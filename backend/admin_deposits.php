<?php
header("Content-Type: application/json");
include 'db.php';

try {
    $stmt = $conn->query("SELECT d.*, u.name as driver_name FROM deposits d JOIN users u ON d.driver_id = u.id WHERE d.status = 'pending'");
    $deposits = $stmt->fetchAll();
    echo json_encode($deposits);
} catch (PDOException $e) {
    echo json_encode([]);
}
?>
