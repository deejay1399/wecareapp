-- Migration script to add missing columns to job_postings table
-- Run this if the table was already created without these columns

-- Add missing columns if they don't exist
DO $$ 
BEGIN
    -- Add applications_count column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'job_postings' AND column_name = 'applications_count') THEN
        ALTER TABLE job_postings ADD COLUMN applications_count INTEGER DEFAULT 0;
    END IF;

    -- Add assigned_helper_id column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'job_postings' AND column_name = 'assigned_helper_id') THEN
        ALTER TABLE job_postings ADD COLUMN assigned_helper_id UUID REFERENCES helpers(id) ON DELETE SET NULL;
    END IF;

    -- Add assigned_helper_name column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'job_postings' AND column_name = 'assigned_helper_name') THEN
        ALTER TABLE job_postings ADD COLUMN assigned_helper_name VARCHAR(200);
    END IF;
END
$$;

-- Drop the old status constraint and add new one with additional statuses
ALTER TABLE job_postings DROP CONSTRAINT IF EXISTS job_postings_status_check;
ALTER TABLE job_postings ADD CONSTRAINT job_postings_status_check 
    CHECK (status IN ('active', 'paused', 'closed', 'filled', 'in progress', 'completed'));

-- Add index for assigned_helper_id if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_job_postings_assigned_helper_id ON job_postings(assigned_helper_id);

-- Verify the changes
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'job_postings' 
ORDER BY ordinal_position;
