-- Migration script to fix jobs that should be in progress
-- This will update any jobs that have accepted applications but are still in 'active' status

-- Update jobs to in progress where applications were accepted
-- but the job status wasn't updated properly
UPDATE job_postings jp
SET 
    status = 'in progress',
    assigned_helper_id = a.helper_id,
    assigned_helper_name = (
        SELECT h.first_name || ' ' || h.last_name 
        FROM helpers h 
        WHERE h.id = a.helper_id
    ),
    updated_at = NOW()
FROM applications a
WHERE jp.id = a.job_posting_id
  AND a.status = 'accepted'
  AND jp.status = 'active'  -- Only update jobs that are still 'active'
  AND jp.assigned_helper_id IS NULL;  -- And don't have a helper assigned yet

-- Verify the update
SELECT 
    jp.id,
    jp.title,
    jp.status,
    jp.assigned_helper_id,
    jp.assigned_helper_name,
    a.status as application_status
FROM job_postings jp
LEFT JOIN applications a ON jp.id = a.job_posting_id AND a.status = 'accepted'
WHERE jp.status = 'in progress'
ORDER BY jp.updated_at DESC;

