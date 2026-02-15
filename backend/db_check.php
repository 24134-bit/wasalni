<?php
include 'db.php';
try {
    $q = $conn->query("SELECT 1 FROM notifications LIMIT 1");
    echo json_encode(["success" => true, "table_exists" => true]);
} catch (Exception $e) {
    echo json_encode(["success" => false, "table_exists" => false, "error" => $e->getMessage()]);
}
?>
