<?php
header("Content-Type: text/plain");
echo "Tariki Render Debug Info\n";
echo "========================\n\n";

$dbUrl = getenv('DATABASE_URL');
if ($dbUrl) {
    echo "DATABASE_URL is SET.\n";
    $p = parse_url($dbUrl);
    echo "Scheme: " . ($p['scheme'] ?? 'N/A') . "\n";
    echo "Host: " . ($p['host'] ?? 'N/A') . "\n";
    echo "Port: " . ($p['port'] ?? '5432') . "\n";
    echo "Path: " . ($p['path'] ?? 'N/A') . "\n";
} else {
    echo "DATABASE_URL is NOT SET.\n";
}

echo "\nPDO Drivers Available:\n";
print_r(PDO::getAvailableDrivers());

echo "\nPHP Version: " . phpversion() . "\n";
?>
