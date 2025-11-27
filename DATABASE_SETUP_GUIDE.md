# WeCare Reports Database Setup Guide

## Overview
The reporting system requires a `reports` table in your Supabase PostgreSQL database. This table stores all user reports for job postings, service postings, and job applications.

## Supabase Credentials
```
Project URL: https://ummiucjxysjuhirtrekw.supabase.co
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtbWl1Y2p4eXNqdWhpcnRyZWt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1NjQ0NzYsImV4cCI6MjA3MjE0MDQ3Nn0.rcrhQ7by-AQk-SYtfEZYeUsUbMTj-aQHWj_2xGC_LfE
```

## Step 1: Access Supabase SQL Editor

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Login with your credentials
3. Select your project: **ummiucjxysjuhirtrekw**
4. Navigate to **SQL Editor** (left sidebar)
5. Click **New Query**

## Step 2: Execute the Reports Table Creation

Copy and paste the following SQL command into the SQL Editor:

```sql
-- Create reports table
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reported_by UUID NOT NULL,
  reported_user UUID NOT NULL,
  reason VARCHAR(100) NOT NULL,
  type VARCHAR(50) NOT NULL,
  reference_id UUID NOT NULL,
  description TEXT NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  admin_notes TEXT,
  reporter_name VARCHAR(255),
  reported_user_name VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(type);
CREATE INDEX IF NOT EXISTS idx_reports_reported_by ON reports(reported_by);
CREATE INDEX IF NOT EXISTS idx_reports_reported_user ON reports(reported_user);
CREATE INDEX IF NOT EXISTS idx_reports_reference_id ON reports(reference_id);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at);

-- Enable RLS
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Create policies for reports table
CREATE POLICY "Allow users to create reports"
  ON reports
  FOR INSERT
  TO authenticated
  WITH CHECK (reported_by = (SELECT id FROM helpers WHERE id = auth.uid()) OR
 reported_by = (SELECT id FROM employers WHERE id = auth.uid()));

CREATE POLICY "Allow admins to view all reports"
  ON reports
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow admins to update reports"
  ON reports
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);
```

Click **Run** button to execute the query.

## Step 3: Verify Table Creation

Run the verification query to confirm the table was created:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'reports';
```

Expected result: One row with `reports` in the table_name column.

## Step 4: Test Insert Permission

Verify the table can accept records:

```sql
SELECT COUNT(*) as total_reports FROM reports;
```

Expected result: `0` (empty table is fine for new installations)

## Step 5: Check Indexes

Verify all indexes were created:

```sql
SELECT indexname 
FROM pg_indexes 
WHERE tablename = 'reports' 
AND schemaname = 'public';
```

Expected result: 6 index rows (idx_reports_status, idx_reports_type, idx_reports_reported_by, idx_reports_reported_user, idx_reports_reference_id, idx_reports_created_at)

## Connection String for Application

The application automatically uses Supabase SDK configured in `admin_main.dart` and `main.dart`:

```dart
await Supabase.initialize(
  url: 'https://ummiucjxysjuhirtrekw.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtbWl1Y2p4eXNqdWhpcnRyZWt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1NjQ0NzYsImV4cCI6MjA3MjE0MDQ3Nn0.rcrhQ7by-AQk-SYtfEZYeUsUbMTj-aQHWj_2xGC_LfE',
);
```

## Available Report Types

The system supports three types of reports:

1. **job_posting** - Reports for employer job postings
2. **service_posting** - Reports for helper service postings
3. **job_application** - Reports for job applications

## Report Statuses

Reports can have the following statuses:

- **pending** - Newly submitted reports (default)
- **under_review** - Admin is currently reviewing
- **resolved** - Admin has taken action
- **dismissed** - Report was reviewed and deemed invalid

## Helper Method Usage

In any component, you can submit a report using:

```dart
import 'package:wecareapp/services/report_service.dart';
import 'package:wecareapp/models/report.dart';

// Submit a report
await ReportService.submitReport(
  reportedByUserId: currentUser.id,
  reportedUserId: targetUser.id,
  reason: 'spam',
  type: 'job_posting',
  referenceId: jobPostingId,
  description: 'This posting contains spam content',
  reporterName: currentUser.name,
  reportedUserName: targetUser.name,
);
```

## Database Queries for Admin Dashboard

### Get All Pending Reports
```sql
SELECT * FROM reports WHERE status = 'pending' ORDER BY created_at DESC;
```

### Get Reports by Type
```sql
SELECT * FROM reports WHERE type = 'job_posting' ORDER BY created_at DESC;
```

### Get Reports for Specific User
```sql
SELECT * FROM reports WHERE reported_user = 'USER_UUID' ORDER BY created_at DESC;
```

### Update Report Status
```sql
UPDATE reports 
SET status = 'resolved', 
    admin_notes = 'Action taken',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 'REPORT_UUID';
```

### Get Report Statistics
```sql
SELECT 
  status,
  type,
  COUNT(*) as count
FROM reports
GROUP BY status, type
ORDER BY status, type;
```

## Testing the System

1. **Submit a Report**: Use the report button on job posting, service posting, or application
2. **View in Admin Panel**: Navigate to Admin Dashboard → Reports
3. **Manage Reports**: Filter by status or type, update report status with admin notes

## Troubleshooting

### Reports table not found
- Verify SQL query executed without errors
- Check that table appears in Supabase SQL Editor's table list
- Ensure the correct project is selected

### Cannot insert reports
- Verify user is authenticated
- Check that reported_by UUID exists in helpers or employers table
- Review RLS policies are enabled

### Admin cannot view reports
- Ensure user is authenticated
- Check RLS policies allow SELECT for authenticated users
- Verify reported_user UUID is valid

## File Locations

- **Model**: `/lib/models/report.dart`
- **Service**: `/lib/services/report_service.dart`
- **Dialog**: `/lib/widgets/dialogs/report_dialog.dart`
- **Admin Page**: `/lib/screens/admin/admin_reports_page.dart`
- **Admin Dashboard**: `/lib/admin_main.dart`
- **SQL Migration**: `/sql/reports/create_reports_table.sql`

## Support

For issues or questions about the reporting system:
1. Check the admin_reports_page.dart for filtering and display logic
2. Review report_service.dart for database operations
3. Verify RLS policies in Supabase SQL Editor

---
**Last Updated**: $(date)
**Version**: 1.0
