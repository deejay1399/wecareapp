-- Debug script to check if user IDs match between sessions and jobs
-- This will help identify why in progress jobs aren't showing in the app

-- 1. Check in progress jobs with their employer and helper IDs
SELECT 
    jp.id as job_id,
    jp.title,
    jp.status,
    jp.employer_id,
    jp.assigned_helper_id,
    jp.assigned_helper_name,
    e.first_name || ' ' || e.last_name as employer_name,
    e.email as employer_email
FROM job_postings jp
LEFT JOIN employers e ON jp.employer_id = e.id
WHERE jp.status = 'in progress'
ORDER BY jp.updated_at DESC;

-- 2. Check helpers associated with in progress jobs
SELECT 
    jp.id as job_id,
    jp.title,
    jp.assigned_helper_id,
    h.id as helper_id_from_table,
    h.first_name || ' ' || h.last_name as helper_name,
    h.email as helper_email
FROM job_postings jp
LEFT JOIN helpers h ON jp.assigned_helper_id = h.id
WHERE jp.status = 'in progress';

-- 3. Check all employers in the system
SELECT 
    id as employer_id,
    first_name || ' ' || last_name as name,
    email,
    created_at
FROM employers
ORDER BY created_at DESC;

-- 4. Check all helpers in the system
SELECT 
    id as helper_id,
    first_name || ' ' || last_name as name,
    email,
    created_at
FROM helpers
ORDER BY created_at DESC;

-- 5. Check if user IDs from auth.users match the employer/helper tables
-- This helps identify if session.getCurrentUserId() returns the correct ID
SELECT 
    'Employer' as user_type,
    e.id,
    e.first_name || ' ' || e.last_name as name,
    e.email,
    au.id as auth_user_id,
    CASE 
        WHEN e.id = au.id THEN '✓ Match'
        ELSE '✗ Mismatch'
    END as id_check
FROM employers e
LEFT JOIN auth.users au ON e.email = au.email
UNION ALL
SELECT 
    'Helper' as user_type,
    h.id,
    h.first_name || ' ' || h.last_name as name,
    h.email,
    au.id as auth_user_id,
    CASE 
        WHEN h.id = au.id THEN '✓ Match'
        ELSE '✗ Mismatch'
    END as id_check
FROM helpers h
LEFT JOIN auth.users au ON h.email = au.email;

