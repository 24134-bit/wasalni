<?php
include 'db.php';
$sql = file_get_contents('commission_migration.sql');
if($conn->query($sql)) {
    echo "Migration successful";
} else {
    echo "Error: " . $conn->error;
}
?>
