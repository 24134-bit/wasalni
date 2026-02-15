<?php
include 'db.php';
header("Content-Type: text/plain");

try {
    echo "Starting migration...\n";
    
    // Check if table exists (PostgreSQL way)
    $check = $conn->query("SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications'")->fetch();
    
    if (!$check) {
        echo "Creating notifications table...\n";
        $sql = "CREATE TABLE notifications (
            id SERIAL PRIMARY KEY,
            target_role VARCHAR(20) CHECK (target_role IN ('admin', 'driver', 'user', 'all')) NOT NULL,
            target_user_id INT DEFAULT NULL,
            title VARCHAR(100) NOT NULL,
            body TEXT NOT NULL,
            is_read BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX idx_notif_role ON notifications(target_role);
        CREATE INDEX idx_notif_user ON notifications(target_user_id);";
        
        $conn->exec($sql);
        echo "Table 'notifications' created successfully.\n";
    } else {
        echo "Table 'notifications' already exists.\n";
    }
    
    echo "Migration completed successfully.";
} catch (Exception $e) {
    echo "FATAL ERROR: " . $e->getMessage();
}
?>
