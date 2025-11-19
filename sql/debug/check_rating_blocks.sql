-- Debug script to check why ratings might be blocked
-- This helps identify application and job status mismatches

-- 1. Check completed jobs with their application statuses
SELECT 
    jp.id as job_id,
    jp.title,
    jp.status as job_status,
    jp.employer_id,
    jp.assigned_helper_id,
    a.id as application_id,
    a.status as application_status,
    a.helper_id,
    CASE 
        WHEN jp.status = 'completed' AND a.status = 'completed' THEN '✓ Can rate'
        WHEN jp.status = 'completed' AND a.status != 'completed' THEN '✗ BLOCKED - Application not completed'
        WHEN jp.status != 'completed' THEN '✗ BLOCKED - Job not completed'
        ELSE '? Unknown'
    END as rating_status
FROM job_postings jp
LEFT JOIN applications a ON jp.id = a.job_posting_id AND a.status IN ('accepted', 'completed')
WHERE jp.status IN ('in progress', 'completed')
ORDER BY jp.updated_at DESC;

-- 2. Find jobs that are completed but applications are still 'accepted'
-- These will block ratings!
SELECT 
    jp.id as job_id,
    jp.title,
    jp.status as job_status,
    a.id as application_id,
    a.status as application_status,
    h.first_name || ' ' || h.last_name as helper_name,
    e.first_name || ' ' || e.last_name as employer_name
FROM job_postings jp
JOIN applications a ON jp.id = a.job_posting_id
JOIN helpers h ON a.helper_id = h.id
JOIN employers e ON jp.employer_id = e.id
WHERE jp.status = 'completed'
  AND a.status = 'accepted';  -- This is the problem!

-- 3. Count rating blocks by reason
SELECT 
    CASE 
        WHEN jp.status != 'completed' THEN 'Job not completed yet'
        WHEN a.status != 'completed' THEN 'Application status not updated'
        ELSE 'No blocks'
    END as block_reason,
    COUNT(*) as count
FROM job_postings jp
LEFT JOIN applications a ON jp.id = a.job_posting_id AND a.status IN ('accepted', 'completed')
WHERE jp.assigned_helper_id IS NOT NULL
GROUP BY block_reason;

