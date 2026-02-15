<?php
header("Content-Type: text/plain");
echo "Tariki Diagnostic v1.0.6\n";
echo "======================\n\n";

echo "PHP Version: " . phpversion() . "\n";
echo "Server Software: " . $_SERVER['SERVER_SOFTWARE'] . "\n\n";

echo "PDO Drivers Found:\n";
print_r(PDO::getAvailableDrivers());

echo "\nExtension Loaded (pdo_pgsql): " . (extension_loaded('pdo_pgsql') ? "YES" : "NO") . "\n";
echo "Extension Loaded (pgsql):     " . (extension_loaded('pgsql') ? "YES" : "NO") . "\n";

echo "\nEnvironment Check:\n";
echo "DATABASE_URL exists: " . (getenv('DATABASE_URL') ? "YES" : "NO") . "\n";
if (getenv('DATABASE_URL')) {
    $p = parse_url(getenv('DATABASE_URL'));
    echo "DB Scheme: " . ($p['scheme'] ?? 'N/A') . "\n";
}
?>
