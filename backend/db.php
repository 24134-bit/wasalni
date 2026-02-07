<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set headers for JSON and CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: *");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

header("Content-Type: application/json; charset=UTF-8");

// Database Credentials using PDO for PostgreSQL on Render
$dbUrl = getenv('DATABASE_URL');

try {
    if ($dbUrl) {
        // Parse DATABASE_URL (postgres://user:pass@host:port/dbname)
        $p = parse_url($dbUrl);
        $dsn = sprintf("pgsql:host=%s;port=%d;dbname=%s", 
            $p['host'], 
            $p['port'] ?? 5432, 
            ltrim($p['path'], '/')
        );
        $db_user = $p['user'];
        $db_pass = $p['pass'];
    } else {
        // Fallback to individual environment variables
        $host = getenv('DB_HOST') ?: "localhost";
        $port = getenv('DB_PORT') ?: "5432";
        $dbname = getenv('DB_NAME') ?: "wasalni";
        $db_user = getenv('DB_USER') ?: "root";
        $db_pass = getenv('DB_PASS') ?: "";

        $dsn = "pgsql:host=$host;port=$port;dbname=$dbname";
    }

    $conn = new PDO($dsn, $db_user, $db_pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);

} catch (PDOException $e) {
    die(json_encode(["success" => false, "error" => "DB Connection Failed: " . $e->getMessage()]));
}
?>
