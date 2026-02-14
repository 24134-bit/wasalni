<?php
header("Content-Type: application/json");
include 'db.php';

$driver_id = $_POST['driver_id'];
$amount = $_POST['amount'];
$method = $_POST['method'];
$sender_phone = $_POST['sender_phone'] ?? '';
$reference_number = $_POST['reference_number'] ?? '';

if(!$driver_id || !$amount || !$reference_number) {
    echo json_encode(["success" => false, "error" => "Missing fields: amount or reference number"]);
    exit;
}

$image_path = "";
if(isset($_FILES['receipt'])) {
    $target_dir = __DIR__ . "/uploads/";
    if(!is_dir($target_dir)) mkdir($target_dir, 0777, true);
    $filename = time() . "_" . basename($_FILES["receipt"]["name"]);
    $target_file = $target_dir . $filename;
    if(move_uploaded_file($_FILES["receipt"]["tmp_name"], $target_file)) {
        $image_path = "uploads/" . $filename;
    }
}

try {
    $stmt = $conn->prepare("INSERT INTO deposits (driver_id, amount, reference_number, method, sender_phone, image_path, status) VALUES (:driver_id, :amount, :ref, :method, :phone, :img, 'pending')");
    $stmt->execute([
        ':driver_id' => $driver_id,
        ':amount' => $amount,
        ':ref' => $reference_number,
        ':method' => $method,
        ':phone' => $sender_phone,
        ':img' => $image_path
    ]);

    include_once 'send_notification_func.php';
    send_notification($conn, 'admin', null, 'طلب شحن جديد', "السائق رقم $driver_id طلب شحن الرصيد بمبلغ $amount");
    echo json_encode(["success" => true]);
} catch (PDOException $e) {
    echo json_encode(["success" => false, "error" => "Failed: " . $e->getMessage()]);
}
?>
