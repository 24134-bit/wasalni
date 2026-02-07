<?php
// Include the centralized DB and Header file
include 'db.php';

// Start output buffer to capture any accidental output
ob_start();

$phone = $_POST['phone'] ?? '';
$password = $_POST['password'] ?? '';

if(empty($phone) || empty($password)){
    echo json_encode(["success" => false, "error" => "Empty fields"]);
    exit();
}

$stmt = $conn->prepare("SELECT id, name, role, balance, phone FROM users WHERE phone = :phone AND password = :password");
$stmt->execute(['phone' => $phone, 'password' => $password]);

// Clean any buffer before sending JSON
ob_clean();

if ($user = $stmt->fetch()) {
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
