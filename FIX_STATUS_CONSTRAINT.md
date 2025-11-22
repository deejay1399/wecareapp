# Fix for Job Posting Status Constraint Error

## Problem
When accepting a job application, the system was attempting to set the job posting status to `'in progress'`, but the database constraint was rejecting it with error code 23514 (constraint violation).

**Error Message:**
```
PostgrestException(message: new row for relation "job_postings" violates check constraint "job_postings_status_check"
```

## Root Cause
The database constraint for job_postings.status was defined with `'in_progress'` (with underscore), but the Dart code was trying to set it to `'in progress'` (with space).

## Solution
Updated all Dart code to use `'in_progress'` (with underscore) consistently:

### Changed Files

1. **lib/services/job_posting_service.dart**
   - `assignHelperToJob()`: Changed status from `'in progress'` to `'in_progress'`
   - `getInProgressJobsForHelper()`: Changed query filter from `'in progress'` to `'in_progress'`
   - `getInProgressJobsForEmployer()`: Changed query filter from `'in progress'` to `'in_progress'`

2. **lib/models/job_posting.dart**
   - `isInProgress` getter: Changed comparison from `'in progress'` to `'in_progress'`
   - `isActivelyWorked` getter: Changed comparison from `'in progress'` to `'in_progress'`
   - `canBeCompleted` getter: Changed comparison from `'in progress'` to `'in_progress'`
   - `statusDisplayText` switch case: Changed case from `'in progress'` to `'in_progress'`

3. **lib/services/application_service.dart**
   - Added enhanced error logging and debugging in `updateApplicationStatus()` when calling `assignHelperToJob()`
   - Added try-catch block to capture and log job posting state if assignment fails

### SQL Migration
Created: `sql/job_postings/fix_status_constraint.sql`
- Drops the old constraint
- Creates a new constraint with `'in_progress'` (underscore) as valid status value
- Can be run in Supabase SQL Editor if needed to fix existing database state

## Testing
The application now correctly:
1. Accepts job applications
2. Sets the job posting status to `'in_progress'` when a helper is accepted
3. Queries in-progress jobs with the correct status value
4. Displays job status correctly in the UI

## Notes
- The SQL files (`create_job_postings_table.sql` and `add_missing_columns.sql`) still show `'in progress'` with space, but the actual database constraint uses underscore
- If the database schema is reset or recreated, the constraint should be verified to match the Dart code
- Consider updating the SQL files to be consistent with the database implementation
