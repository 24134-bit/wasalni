<?php
header("Content-Type: application/json");
include 'db.php';

$result = $conn->query("SELECT * FROM deposits WHERE status = 'pending'");
$deposits = [];
while($row = $result->fetch_assoc()) {
    $deposits[] = $row;
}
echo json_encode($deposits);
?>
