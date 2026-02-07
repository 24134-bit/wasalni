<?php
function send_notification($conn, $role, $user_id, $title, $body) {
    // If user_id is null, it's a broadcast to role
    if ($user_id === null) {
        $stmt = $conn->prepare("INSERT INTO notifications (target_role, title, body) VALUES (:role, :title, :body)");
        $stmt->execute(['role' => $role, 'title' => $title, 'body' => $body]);
    } else {
        $stmt = $conn->prepare("INSERT INTO notifications (target_role, target_user_id, title, body) VALUES (:role, :user_id, :title, :body)");
        $stmt->execute(['role' => $role, 'user_id' => $user_id, 'title' => $title, 'body' => $body]);
    }
}
?>
