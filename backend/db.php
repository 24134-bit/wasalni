<?php
error_reporting(0);
ini_set('display_errors', 0);

// Set headers for JSON and CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// InfinityFree Database Credentials
$servername = "sql113.infinityfree.com";
$username   = "if0_41078173";
$password   = "P01fN536AEooU";
$dbname     = "if0_41078173_wasalni";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die(json_encode(["success" => false, "error" => "DB Connection Failed"]));
}
?>
