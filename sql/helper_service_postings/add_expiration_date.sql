-- Add expiration date field to helper_service_postings table
-- This allows service postings to automatically expire after a set date

-- Add the expires_at column
ALTER TABLE helper_service_postings 
ADD COLUMN expires_at TIMESTAMP WITH TIME ZONE;

-- Create index on expires_at for efficient filtering
CREATE INDEX IF NOT EXISTS idx_helper_service_postings_expires_at ON helper_service_postings(expires_at DESC);

-- Verify the change
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'helper_service_postings' 
ORDER BY ordinal_position;
