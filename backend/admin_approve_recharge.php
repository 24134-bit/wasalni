<?php
// wasalni/backend/admin_approve_recharge.php
ob_start();
header("Content-Type: application/json; charset=UTF-8");
include 'db.php';

// Clear any accidental output
ob_clean();

$input = json_decode(file_get_contents('php://input'), true);
$id = $_POST['id'] ?? $input['id'] ?? null;
$action = $_POST['action'] ?? $input['action'] ?? null;

if(!$id || !$action) {
    echo json_encode(["success" => false, "error" => "No ID or Action detected. Data received: " . json_encode($_POST)]);
    exit;
}

try {
    // 1. Fetch deposit info
    $select = $conn->prepare("SELECT amount, driver_id, status FROM deposits WHERE id = :id");
    $select->execute([':id' => $id]);
    $deposit = $select->fetch();

    if (!$deposit) {
        throw new Exception("Deposit order #$id not found in table 'deposits'.");
    }

    if ($deposit['status'] !== 'pending') {
        throw new Exception("This deposit is already " . $deposit['status']);
    }

    $amount = (float)$deposit['amount'];
    $driver_id = (int)$deposit['driver_id'];

    $conn->beginTransaction();
    
    $status = ($action == 'approve') ? 'approved' : 'rejected';
    
    // STEP 1: Update Deposit Status
    $stmtStatus = $conn->prepare("UPDATE deposits SET status = :status WHERE id = :id");
    $stmtStatus->execute([':status' => $status, ':id' => $id]);

    $final_balance = 0;
    if ($action == 'approve') {
        // STEP 2: Update User Balance (The Critical Part)
        // We use COALESCE and ensure the user actually exists
        $updateSql = "UPDATE users SET balance = COALESCE(balance, 0) + :amount WHERE id = :driver_id";
        $updateBal = $conn->prepare($updateSql);
        $updateBal->execute([':amount' => $amount, ':driver_id' => $driver_id]);
        
        $affected = $updateBal->rowCount();
        if ($affected === 0) {
            // Check if user exists at all
            $checkUser = $conn->prepare("SELECT role FROM users WHERE id = :id");
            $checkUser->execute(['id' => $driver_id]);
            $userExists = $checkUser->fetch();
            
            if (!$userExists) {
                throw new Exception("USER NOT FOUND: Driver ID $driver_id does not exist in the 'users' table. Please check verify_integrity.php.");
            } else {
                throw new Exception("UPDATE FAILED: User exists but balance didn't change. This might happen if amount is 0 or database locked.");
            }
        }

        // STEP 3: Verify and get new balance
        $checkBal = $conn->prepare("SELECT balance FROM users WHERE id = :driver_id");
        $checkBal->execute([':driver_id' => $driver_id]);
        $row = $checkBal->fetch();
        $final_balance = $row ? (float)$row['balance'] : 0;
    }

    // STEP 4: Notify the driver
    include_once 'send_notification_func.php';
    $notifTitle = ($status == 'approved') ? "Solde Mis à Jour" : "Recharge Refusée";
    $notifBody = ($status == 'approved') 
        ? "Votre recharge de $amount MRU a été acceptée. Nouveau solde: $final_balance MRU." 
        : "Votre recharge a été refusée.";
    
    send_notification($conn, 'driver', $driver_id, $notifTitle, $notifBody);

    $conn->commit();
    
    if (ob_get_length()) ob_clean();
    echo json_encode([
        "success" => true, 
        "new_balance" => $final_balance,
        "amount_processed" => $amount,
        "status" => $status
    ]);

} catch (Exception $e) {
    if ($conn->inTransaction()) $conn->rollBack();
    if (ob_get_length()) ob_clean();
    echo json_encode(["success" => false, "error" => $e->getMessage()]);
}
?>
