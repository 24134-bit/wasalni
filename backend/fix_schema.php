<?php
header("Content-Type: application/json");
include 'db.php';

echo "<h1>Tariki Schema Fix (PostgreSQL)</h1>";

try {
    // 1. Rides Type Constraint
    $conn->exec("ALTER TABLE rides DROP CONSTRAINT IF EXISTS rides_type_check");
    $conn->exec("ALTER TABLE rides ADD CONSTRAINT rides_type_check CHECK (type IN ('open', 'fixed', 'closed'))");
    echo "<p>✅ Constraint 'rides_type_check' updated (open, fixed, closed).</p>";

    // 2. Rides Status Constraint
    $conn->exec("ALTER TABLE rides DROP CONSTRAINT IF EXISTS rides_status_check");
    $conn->exec("ALTER TABLE rides ADD CONSTRAINT rides_status_check CHECK (status IN ('pending', 'accepted', 'arrived', 'on_trip', 'delivered', 'cancelled'))");
    echo "<p>✅ Constraint 'rides_status_check' updated (pending...cancelled).</p>";

    // 3. User Role Constraint
    $conn->exec("ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check");
    $conn->exec("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('driver', 'admin', 'user'))");
    echo "<p>✅ Constraint 'users_role_check' updated (driver, admin, user).</p>";

    // 4. Notification Target Role Constraint
    $conn->exec("ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_target_role_check");
    $conn->exec("ALTER TABLE notifications ADD CONSTRAINT notifications_target_role_check CHECK (target_role IN ('admin', 'driver', 'user', 'all'))");
    echo "<p>✅ Constraint 'notifications_target_role_check' updated (admin...all).</p>";

    echo "<h2>✅ All PostgreSQL Constraints Fixed Successfully</h2>";
    echo "<p>Please visit this page in your browser to apply the fixes, then test the Cancellation button again.</p>";

} catch (Exception $e) {
    echo "<p style='color:red;'>Error: " . $e->getMessage() . "</p>";
}
?>
