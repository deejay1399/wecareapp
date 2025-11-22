-- Fix the job_postings status constraint to use underscore for in_progress
-- This migration updates the constraint to match what the database expects

-- Drop the old constraint
ALTER TABLE job_postings DROP CONSTRAINT IF EXISTS job_postings_status_check;

-- Add the corrected constraint with 'in_progress' (underscore)
ALTER TABLE job_postings ADD CONSTRAINT job_postings_status_check 
    CHECK (status IN ('active', 'paused', 'closed', 'filled', 'in_progress', 'completed'));

-- Verify the constraint was created
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'job_postings' 
AND constraint_name = 'job_postings_status_check';
