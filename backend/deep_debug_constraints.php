<?php
header("Content-Type: text/plain");
include 'db.php';

echo "Tariki Deep Schema Debug\n";
echo "========================\n\n";

try {
    // 1. Get all constraints for the 'rides' table
    echo "--- Constraints on 'rides' table ---\n";
    $q = $conn->prepare("
        SELECT conname, pg_get_constraintdef(c.oid) 
        FROM pg_constraint c 
        JOIN pg_namespace n ON n.oid = c.connamespace 
        WHERE contype = 'c' 
        AND conrelid = 'rides'::regclass;
    ");
    $q->execute();
    $constraints = $q->fetchAll();
    foreach ($constraints as $row) {
        echo "Name: " . $row['conname'] . " | Definition: " . $row['pg_get_constraintdef'] . "\n";
    }

    echo "\n--- Columns in 'rides' table ---\n";
    $q = $conn->query("SELECT column_name, data_type, character_maximum_length, column_default 
                       FROM information_schema.columns 
                       WHERE table_name = 'rides'");
    $cols = $q->fetchAll();
    foreach ($cols as $col) {
        echo $col['column_name'] . " (" . $col['data_type'] . ") | Default: " . $col['column_default'] . "\n";
    }

    echo "\n--- Recent Rides Status Sample ---\n";
    $q = $conn->query("SELECT id, status, type FROM rides ORDER BY id DESC LIMIT 5");
    $rides = $q->fetchAll();
    foreach ($rides as $ride) {
        echo "ID: " . $ride['id'] . " | Status: " . $ride['status'] . " | Type: " . $ride['type'] . "\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
