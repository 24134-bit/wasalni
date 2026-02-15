echo "<h1>Tariki Backend is Running (v1.1.0) ✨</h1>";
echo "<p>Available Drivers: <b>" . implode(", ", PDO::getAvailableDrivers()) . "</b></p>";
echo "<p>Diagnostic: <a href='diag.php'>View Server Details</a></p>";
echo "<p>Status: <a href='test.php'>Check Connection</a></p>";
echo "<p>Data Check: <a href='debug_users.php'>Inspect Captains</a></p>";
echo "<p>Step 1: <a href='setup_admins.php'>Setup Admin Accounts</a></p>";
echo "<p>Step 2: <a href='fix_schema.php'>Fix SQL Constraints (Postgres)</a></p>";
?>
