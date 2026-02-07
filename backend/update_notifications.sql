CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    target_role ENUM('admin', 'driver', 'all') NOT NULL,
    target_user_id INT DEFAULT NULL,
    title VARCHAR(100) NOT NULL,
    body TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (target_role),
    INDEX (target_user_id)
);
