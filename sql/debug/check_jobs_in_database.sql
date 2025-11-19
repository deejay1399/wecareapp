-- Check if there are actual jobs in the database
-- Run this to see what job data exists

-- 1. Count total jobs by status
SELECT 
    status,
    COUNT(*) as count
FROM job_postings
GROUP BY status
ORDER BY count DESC;

-- 2. Show all active jobs (these should appear in Find Jobs)
SELECT 
    id,
    title,
    description,
    barangay,
    salary,
    payment_frequency,
    status,
    employer_id,
    created_at
FROM job_postings
WHERE status = 'active'
ORDER BY created_at DESC
LIMIT 20;

-- 3. Count jobs by status
SELECT 
    CASE 
        WHEN COUNT(*) FILTER (WHERE status = 'active') = 0 THEN '⚠️ No active jobs!'
        ELSE '✓ Has active jobs'
    END as active_jobs_status,
    COUNT(*) FILTER (WHERE status = 'active') as active_count,
    COUNT(*) FILTER (WHERE status = 'in progress') as in progress_count,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
    COUNT(*) as total_jobs
FROM job_postings;

-- 4. Show job postings with employer info
SELECT 
    jp.id,
    jp.title,
    jp.status,
    jp.barangay,
    e.first_name || ' ' || e.last_name as employer_name,
    jp.created_at
FROM job_postings jp
JOIN employers e ON jp.employer_id = e.id
ORDER BY jp.created_at DESC
LIMIT 10;

-- 5. Check if there are ANY jobs at all
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM job_postings) THEN 'Database has jobs ✓'
        ELSE 'Database is EMPTY - No jobs found! ⚠️'
    END as database_status;

