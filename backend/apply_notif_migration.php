<?php
include 'db.php';
$sql = file_get_contents('update_notifications.sql');
if ($conn->multi_query($sql)) {
    echo "Notifications table created successfully.";
} else {
    echo "Error creating table: " . $conn->error;
}
?>
