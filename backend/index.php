echo "<h1>Tariki Backend is Running (v1.0.6)</h1>";
echo "<p>Available Drivers: <b>" . implode(", ", PDO::getAvailableDrivers()) . "</b></p>";
echo "<p>Diagnostic: <a href='diag.php'>View Server Details</a></p>";
echo "<p>Status: <a href='test.php'>Check Connection</a></p>";
echo "<p>Setup: <a href='migrate_db.php'>Initialize Database (Run once)</a></p>";
?>
