USE wasalni;

-- Add mandatory reference number to deposits
ALTER TABLE deposits ADD COLUMN IF NOT EXISTS reference_number VARCHAR(100) AFTER amount;

-- Ensure sender_phone exists (it was in the PHP but not in setup.sql)
ALTER TABLE deposits ADD COLUMN IF NOT EXISTS sender_phone VARCHAR(20) AFTER method;

-- Add photo path to users (captains)
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_path VARCHAR(255) AFTER car_number;
