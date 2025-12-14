-- Add expiration date field to job_postings table
-- This allows job postings to automatically expire after a set date

-- Add the expires_at column
ALTER TABLE job_postings 
ADD COLUMN expires_at TIMESTAMP WITH TIME ZONE;

-- Create index on expires_at for efficient filtering
CREATE INDEX IF NOT EXISTS idx_job_postings_expires_at ON job_postings(expires_at DESC);

-- Verify the change
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'job_postings' 
ORDER BY ordinal_position;
