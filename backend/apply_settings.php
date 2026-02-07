<?php
include 'db.php';
$sql = file_get_contents('settings_migration.sql');
if ($conn->multi_query($sql)) {
    echo "Settings table created successfully.";
} else {
    echo "Error: " . $conn->error;
}
?>
