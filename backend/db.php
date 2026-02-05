<?php
ob_start();
error_reporting(0); // Suppress all warnings/errors that break JSON
ini_set('display_errors', 0);
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Handle Preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servername = getenv('DB_HOST') ?: "sql311.infinityfree.com";
$username = getenv('DB_USER') ?: "if0_XXXXXXXX_root";
$password = getenv('DB_PASS') ?: "your_password";
$dbname = getenv('DB_NAME') ?: "if0_XXXXXXXX_wasalni";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
