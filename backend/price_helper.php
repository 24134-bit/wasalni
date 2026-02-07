<?php
function calculate_price($conn, $distance_km) {
    $result = $conn->query("SELECT * FROM settings WHERE id = 1");
    $settings = $result->fetch_assoc();
    
    $price = $settings['base_fare'] + ($distance_km * $settings['price_km']);
    return round($price, 2);
}
?>
