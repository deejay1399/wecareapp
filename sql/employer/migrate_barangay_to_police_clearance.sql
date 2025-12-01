-- Migration: Rename barangay_clearance to police_clearance and add expiry date column
-- This migration updates the employers table to support police clearance with expiration date

-- Step 1: Add new columns for police clearance and expiry date
ALTER TABLE employers
ADD COLUMN IF NOT EXISTS police_clearance_base64 TEXT,
ADD COLUMN IF NOT EXISTS police_clearance_expiry_date VARCHAR(50);

-- Step 2: Migrate existing data from barangay_clearance to police_clearance
UPDATE employers 
SET police_clearance_base64 = barangay_clearance_base64
WHERE barangay_clearance_base64 IS NOT NULL;

-- Step 3: Add comments to new columns
COMMENT ON COLUMN employers.police_clearance_base64 IS 'Base64 encoded police clearance image data';
COMMENT ON COLUMN employers.police_clearance_expiry_date IS 'Expiration date of the police clearance (extracted from image during verification)';

-- Step 4: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_employers_police_clearance_expiry ON employers(police_clearance_expiry_date);

-- NOTE: Keep barangay_clearance_base64 for backward compatibility
-- It can be deprecated and removed in a future migration after confirming all clients are updated
