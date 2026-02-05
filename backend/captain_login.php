<?php
ob_start();
error_reporting(0);
ini_set('display_errors', 0);
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8"); // Ensure UTF-8

include 'db.php';

// Check if inputs exist
$phone = isset($_POST['phone']) ? $_POST['phone'] : '';
$password = isset($_POST['password']) ? $_POST['password'] : '';

if(empty($phone) || empty($password)){
    echo json_encode(["success" => false, "error" => "Empty fields"]);
    exit();
}

$stmt = $conn->prepare("SELECT id, name, role, balance, phone FROM users WHERE phone = ? AND password = ?");
$stmt->bind_param("ss", $phone, $password);
$stmt->execute();
$result = $stmt->get_result();

ob_end_clean(); // Clean buffer

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    // Force types to be safe
    $user['id'] = (int)$user['id'];
    $user['balance'] = (float)$user['balance'];
    
    echo json_encode([
        "success" => true,
        "user" => $user
    ]);
} else {
    echo json_encode([
        "success" => false,
        "error" => "Invalid credentials"
    ]);
}
?>
