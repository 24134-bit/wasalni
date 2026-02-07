<?php
include 'db.php';
$response = ["status" => "OK", "message" => "Server is reachable!"];

if (!$conn) {
    $response["db_status"] = "Error";
    $response["db_error"] = "Connection object is null";
} else {
    $response["db_status"] = "Connected Successfully!";
}

echo json_encode($response);
?>
