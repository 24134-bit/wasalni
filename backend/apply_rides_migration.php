<?php
include 'db.php';
$sql = file_get_contents('rides_migration.sql');
// Split by semicolon since multi_query handles multiple statements
$queries = explode(';', $sql);
foreach($queries as $query) {
    if(trim($query) != "") {
        if($conn->query($query)) {
            echo "Query executed: " . substr($query, 0, 20) . "...\n";
        } else {
            echo "Error executing query: " . $conn->error . "\n";
        }
    }
}
echo "Migration finished.";
?>
