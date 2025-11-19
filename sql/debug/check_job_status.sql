-- Debug script to check job posting statuses and assignments
-- Run this in your Supabase SQL editor to see what's happening

-- 1. Check all job postings with their statuses
SELECT 
    id,
    title,
    status,
    assigned_helper_id,
    assigned_helper_name,
    employer_id,
    created_at,
    updated_at
FROM job_postings
ORDER BY updated_at DESC;

-- 2. Check applications and their statuses
SELECT 
    a.id as application_id,
    a.status as app_status,
    a.applied_at,
    jp.title as job_title,
    jp.status as job_status,
    jp.assigned_helper_id,
    jp.assigned_helper_name,
    h.first_name || ' ' || h.last_name as helper_name
FROM applications a
JOIN job_postings jp ON a.job_posting_id = jp.id
JOIN helpers h ON a.helper_id = h.id
ORDER BY a.applied_at DESC;

-- 3. Count jobs by status
SELECT 
    status,
    COUNT(*) as count
FROM job_postings
GROUP BY status;

-- 4. Check for accepted applications without in progress jobs
SELECT 
    a.id as application_id,
    a.status as app_status,
    jp.title as job_title,
    jp.status as job_status,
    jp.id as job_id,
    h.first_name || ' ' || h.last_name as helper_name
FROM applications a
JOIN job_postings jp ON a.job_posting_id = jp.id
JOIN helpers h ON a.helper_id = h.id
WHERE a.status = 'accepted' 
  AND jp.status != 'in progress';

-- 5. Find in progress jobs
SELECT 
    jp.id,
    jp.title,
    jp.status,
    jp.employer_id,
    jp.assigned_helper_id,
    jp.assigned_helper_name,
    e.first_name || ' ' || e.last_name as employer_name
FROM job_postings jp
JOIN employers e ON jp.employer_id = e.id
WHERE jp.status = 'in progress';

