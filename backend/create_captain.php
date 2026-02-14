<?php
ob_start();
error_reporting(0);
header("Content-Type: application/json");
include 'db.php';

$phone = $_POST['phone'];
$password = $_POST['password'];
$name = $_POST['name'];
$car_number = $_POST['car_number'] ?? '';

if(!$phone || !$password || !$name) {
    echo json_encode(["success" => false, "error" => "Missing data"]);
    exit;
}

$photo_path = "";
if(isset($_FILES['photo'])) {
    $target_dir = __DIR__ . "/uploads/captains/";
    if(!is_dir($target_dir)) mkdir($target_dir, 0777, true);
    $filename = time() . "_" . basename($_FILES["photo"]["name"]);
    $target_file = $target_dir . $filename;
    if(move_uploaded_file($_FILES["photo"]["tmp_name"], $target_file)) {
        $photo_path = "uploads/captains/" . $filename;
    }
}

try {
    $sql = "INSERT INTO users (phone, password, name, car_number, photo_path, role, balance) VALUES (:phone, :password, :name, :car_number, :photo_path, 'driver', 0.00)";
    $stmt = $conn->prepare($sql);
    
    $stmt->execute([
        ':phone' => $phone,
        ':password' => $password,
        ':name' => $name,
        ':car_number' => $car_number,
        ':photo_path' => $photo_path
    ]);

    ob_end_clean();
    echo json_encode(["success" => true]);
} catch (PDOException $e) {
    ob_end_clean();
    echo json_encode(["success" => false, "error" => "Phone number already exists or DB error: " . $e->getMessage()]);
}
?>
