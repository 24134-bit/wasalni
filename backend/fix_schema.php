<?php
header("Content-Type: application/json");
include 'db.php';

echo "<h1>Tariki Schema Fix (PostgreSQL)</h1>";

try {
    // 1. Drop existing check constraint if it exists (check name might vary, but usually it's as defined)
    // In our SQL: status CHECK (status IN (...)), type CHECK (type IN (...))
    // PostgreSQL usually names them: table_column_check
    
    // Safety: Try to drop and recreate the constraint to include 'closed'
    $conn->exec("ALTER TABLE rides DROP CONSTRAINT IF EXISTS rides_type_check");
    $conn->exec("ALTER TABLE rides ADD CONSTRAINT rides_type_check CHECK (type IN ('open', 'fixed', 'closed'))");
    echo "<p>✅ Constraint 'rides_type_check' updated to allow (open, fixed, closed).</p>";

    echo "<h2>✅ Global Fixes Applied Successfully</h2>";
    echo "<p>Test the app now. If everything works, delete this file.</p>";

} catch (Exception $e) {
    echo "<p style='color:red;'>Error: " . $e->getMessage() . "</p>";
}
?>
