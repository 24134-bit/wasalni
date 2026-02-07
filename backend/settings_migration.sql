CREATE TABLE IF NOT EXISTS settings (
    id INT PRIMARY KEY DEFAULT 1,
    price_km DECIMAL(10,2) DEFAULT 10.00,
    price_min DECIMAL(10,2) DEFAULT 1.00,
    base_fare DECIMAL(10,2) DEFAULT 5.00
);
INSERT IGNORE INTO settings (id, price_km, price_min, base_fare) VALUES (1, 10.00, 1.00, 5.00);
