<?php
/**
 * Tariki Database Migration Script
 * This script imports the database_postgres.sql file into your Render PostgreSQL database.
 * Run this by visiting: https://your-server-url.com/migrate_db.php
 */

include 'db.php';

echo "<h1>Tariki Database Migration</h1>";

try {
    $sqlFile = 'database_postgres.sql';
    if (!file_exists($sqlFile)) {
        throw new Exception("Schema file ($sqlFile) not found!");
    }

    $sql = file_get_contents($sqlFile);
    
    // Execute the SQL
    $conn->exec($sql);

    echo "<p style='color: green; font-weight: bold;'>✅ Database schema imported successfully!</p>";
    echo "<p>You can now use the application. Please <strong>delete this file</strong> (migrate_db.php) for security.</p>";

} catch (Exception $e) {
    echo "<p style='color: red; font-weight: bold;'>❌ Error: " . $e->getMessage() . "</p>";
}
?>
