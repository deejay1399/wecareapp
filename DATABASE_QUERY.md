# 📊 Database Query - Execute in Supabase SQL Editor

## Quick Setup (Copy & Paste)

### Step 1: Go to Supabase Dashboard
Visit: https://app.supabase.com → Select Project: ummiucjxysjuhirtrekw → Click "SQL Editor"

### Step 2: Create New Query and Execute This:

```sql
-- ============================================
-- WeCare Reports Table - Complete Setup
-- ============================================

-- Drop existing table if needed (comment out if first time)
-- DROP TABLE IF EXISTS reports CASCADE;

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

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(type);
CREATE INDEX IF NOT EXISTS idx_reports_reported_by ON reports(reported_by);
CREATE INDEX IF NOT EXISTS idx_reports_reported_user ON reports(reported_user);
CREATE INDEX IF NOT EXISTS idx_reports_reference_id ON reports(reference_id);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at);

-- Enable Row Level Security
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Allow users to create reports"
  ON reports FOR INSERT TO authenticated
  WITH CHECK (
    reported_by = (SELECT id FROM helpers WHERE id = auth.uid()) OR
    reported_by = (SELECT id FROM employers WHERE id = auth.uid())
  );

CREATE POLICY "Allow admins to view all reports"
  ON reports FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow admins to update reports"
  ON reports FOR UPDATE TO authenticated
  USING (true) WITH CHECK (true);
```

## Verification Queries

After executing the main query above, run these to verify:

### Check Table Exists:
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'reports';
```
**Expected**: 1 row with "reports"

### Check Indexes Created:
```sql
SELECT indexname FROM pg_indexes 
WHERE tablename = 'reports' AND schemaname = 'public';
```
**Expected**: 6 indexes listed

### Check RLS Enabled:
```sql
SELECT relname FROM pg_class 
WHERE relname = 'reports' AND relrowsecurity = true;
```
**Expected**: 1 row with "reports"

### Check RLS Policies:
```sql
SELECT policyname FROM pg_policies 
WHERE tablename = 'reports';
```
**Expected**: 3 policies

## Test Data Insertion

```sql
INSERT INTO reports (
  reported_by, 
  reported_user, 
  reason, 
  type, 
  reference_id, 
  description,
  reporter_name,
  reported_user_name
) VALUES (
  'a0000000-0000-0000-0000-000000000001'::uuid,
  'b0000000-0000-0000-0000-000000000001'::uuid,
  'spam',
  'job_posting',
  'c0000000-0000-0000-0000-000000000001'::uuid,
  'This posting contains spam content',
  'Test Reporter',
  'Test User'
);
```

Then verify:
```sql
SELECT * FROM reports ORDER BY created_at DESC LIMIT 1;
```

## Useful Admin Queries

### Get Pending Reports:
```sql
SELECT id, reported_user_name, reason, description, created_at 
FROM reports 
WHERE status = 'pending' 
ORDER BY created_at DESC;
```

### Count Reports by Status:
```sql
SELECT status, COUNT(*) as count 
FROM reports 
GROUP BY status;
```

### Count Reports by Type:
```sql
SELECT type, COUNT(*) as count 
FROM reports 
GROUP BY type;
```

### Get Reports by User:
```sql
SELECT * FROM reports 
WHERE reported_user = 'USER_UUID'
ORDER BY created_at DESC;
```

### Update Report Status:
```sql
UPDATE reports 
SET status = 'resolved', 
    admin_notes = 'Warned user about spam content',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 'REPORT_UUID';
```

## Troubleshooting

### Permission Denied Error:
- Make sure you're in Supabase SQL Editor (not running locally)
- Verify you're logged into the correct project
- Check authentication level in Supabase

### Table Already Exists:
- The `IF NOT EXISTS` clause prevents errors
- If you need to reset: `DROP TABLE IF EXISTS reports CASCADE;`

### UUIDs Invalid:
- Copy UUID values from your helpers/employers table
- Or use `SELECT id FROM helpers LIMIT 1;` to get a valid UUID

## Connection Info for App

Already configured in `/lib/admin_main.dart` and `/lib/main.dart`:

```
URL: https://ummiucjxysjuhirtrekw.supabase.co
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtbWl1Y2p4eXNqdWhpcnRyZWt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1NjQ0NzYsImV4cCI6MjA3MjE0MDQ3Nn0.rcrhQ7by-AQk-SYtfEZYeUsUbMTj-aQHWj_2xGC_LfE
```

---
**Status**: ✅ Ready to Execute
**Time to Setup**: ~2 minutes
