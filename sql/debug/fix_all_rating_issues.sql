-- Complete fix for rating issues
-- Run this script to fix all rating-related problems

-- STEP 1: Add 'completed' status to applications constraint
-- Drop the old constraint
ALTER TABLE applications 
DROP CONSTRAINT IF EXISTS applications_status_check;

-- Add new constraint with 'completed' status included
ALTER TABLE applications 
ADD CONSTRAINT applications_status_check 
CHECK (status IN ('pending', 'accepted', 'rejected', 'withdrawn', 'completed'));

-- STEP 2: Update existing completed jobs' applications
UPDATE applications
SET status = 'completed'
WHERE status = 'accepted'
  AND job_posting_id IN (
    SELECT id 
    FROM job_postings 
    WHERE status = 'completed'
  );

-- STEP 3: Verify the fix
SELECT 
    jp.id as job_id,
    jp.title,
    jp.status as job_status,
    a.id as application_id,
    a.status as application_status,
    h.first_name || ' ' || h.last_name as helper_name,
    e.first_name || ' ' || e.last_name as employer_name,
    CASE 
        WHEN jp.status = 'completed' AND a.status = 'completed' THEN '✓ Ready for rating'
        WHEN jp.status = 'completed' AND a.status != 'completed' THEN '✗ Issue - App not completed'
        WHEN jp.status != 'completed' THEN '⏳ Job still in progress'
        ELSE '? Unknown status'
    END as rating_ready
FROM job_postings jp
LEFT JOIN applications a ON jp.id = a.job_posting_id AND a.status IN ('accepted', 'completed')
LEFT JOIN helpers h ON a.helper_id = h.id
LEFT JOIN employers e ON jp.employer_id = e.id
WHERE jp.assigned_helper_id IS NOT NULL
ORDER BY jp.updated_at DESC;

-- STEP 4: Show statistics
SELECT 
    'Total Jobs' as metric,
    COUNT(*) as count
FROM job_postings
UNION ALL
SELECT 
    'In Progress Jobs',
    COUNT(*)
FROM job_postings
WHERE status = 'in progress'
UNION ALL
SELECT 
    'Completed Jobs',
    COUNT(*)
FROM job_postings
WHERE status = 'completed'
UNION ALL
SELECT 
    'Applications Ready for Rating',
    COUNT(*)
FROM applications a
JOIN job_postings jp ON a.job_posting_id = jp.id
WHERE jp.status = 'completed' AND a.status = 'completed';

