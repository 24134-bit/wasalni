<?php
// Simple test script to verify the endpoint works
header("Content-Type: text/plain");

echo "Testing captain_login.php endpoint...\n\n";

// Simulate a POST request
$_POST['phone'] = '1234567890';
$_POST['password'] = 'test123';

// Include the login script
include 'captain_login.php';
?>
