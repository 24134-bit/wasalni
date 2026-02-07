<?php
include 'db.php';
$result = $conn->query("SELECT * FROM settings ORDER BY id DESC LIMIT 1");
if ($result->num_rows > 0) {
    echo json_encode($result->fetch_assoc());
} else {
    echo json_encode(["price_km" => 10, "price_min" => 1, "base_fare" => 5]);
}
?>
