<?php
include 'db.php';
$response = ["status" => "OK", "message" => "Server is reachable!"];

if ($conn->connect_error) {
    $response["db_status"] = "Error";
    $response["db_error"] = $conn->connect_error;
} else {
    $response["db_status"] = "Connected Successfully!";
}

echo json_encode($response);
?>
