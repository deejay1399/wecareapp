# Notifications Setup - Database Configuration

## Your Actual Database Schema

Your Supabase `notifications` table is already created with this structure:

```sql
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  user_id uuid NULL,
  title text NOT NULL,
  is_read boolean NULL DEFAULT false,
  created_at timestamp with time zone NULL DEFAULT now(),
  type text NULL DEFAULT 'update'::text,
  category text NULL DEFAULT 'update'::text,
  target_id text NULL,
  body text NULL,
  recipient_id uuid NOT NULL,
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;
```

## Table Columns

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key - Auto-generated |
| `recipient_id` | UUID | **Main field** - ID of user receiving notification (helper or employer) |
| `user_id` | UUID | Optional - Reference to auth.users (for Supabase Auth integration) |
| `title` | TEXT | Notification title (e.g., "New Application") |
| `body` | TEXT | Notification message body (e.g., "John Doe applied for Cleaning Service") |
| `type` | TEXT | Type of notification (job_application, application_accepted, application_rejected, etc.) |
| `category` | TEXT | Category (new, update, alert, message) |
| `target_id` | TEXT | Reference ID (e.g., job_posting_id) |
| `is_read` | BOOLEAN | Whether notification has been read |
| `created_at` | TIMESTAMP | When notification was created |

## How It Works

### When a Helper Applies for a Job:
1. ✅ Application record is saved to `applications` table
2. ✅ Notification is created with:
   - `recipient_id` = employer's ID
   - `title` = "New Application"
   - `body` = "[Helper Name] applied for \"[Job Title]\""
   - `type` = "job_application"
   - `is_read` = false
   - `created_at` = now()

### When an Employer Accepts an Application:
1. ✅ Application status updated to "accepted"
2. ✅ Notification sent to helper with:
   - `recipient_id` = helper's ID
   - `title` = "Application Accepted! 🎉"
   - `body` = "Your application for \"[Job Title]\" has been accepted"
   - `type` = "application_accepted"
   - `is_read` = false

### When an Employer Rejects an Application:
1. ✅ Application status updated to "rejected"
2. ✅ Notification sent to helper with:
   - `recipient_id` = helper's ID
   - `title` = "Application Not Selected"
   - `body` = "Unfortunately, your application for \"[Job Title]\" was not selected"
   - `type` = "application_rejected"
   - `is_read` = false

## Code Implementation

### NotificationService.createNotification()
```dart
await NotificationService.createNotification(
  recipientId: employerId,  // UUID of recipient
  title: 'New Application',
  body: '$helperName applied for "$jobTitle"',
  type: 'job_application',
  category: 'new',
  targetId: jobPostingId,
);
```

### ApplicationService.applyForJob()
- Saves application to database
- Retrieves employer ID from job posting
- Creates notification for employer
- All debug messages logged to console

## Testing

1. **Check Console Logs** for DEBUG messages:
   ```
   DEBUG: Attempting to apply for job - jobPostingId: ..., helperId: ...
   DEBUG: Application successfully inserted with ID: ...
   DEBUG: Creating notification for employer: ...
   DEBUG: Notification created successfully
   ```

2. **Verify in Supabase**:
   - Go to `Database > Tables > notifications`
   - Check that new records appear when helper applies
   - Verify `recipient_id`, `title`, `body`, `type`, `is_read` fields

3. **Check on Employer Account**:
   - Login as employer
   - Go to Notifications page
   - Should see "New Application" notification from helper

## Troubleshooting

### No notification appears
- Check console logs for errors
- Verify `notifications` table exists in Supabase
- Ensure RLS policies allow inserts (if enabled)
- Check that employer_id is correctly retrieved from job_postings

### Wrong recipient gets notification
- Verify employer_id in job_postings table is correct
- Check recipient_id value in notifications table

### Application saves but notification fails
- Check Supabase SQL Editor for table structure
- Run: `SELECT * FROM notifications LIMIT 1;` to verify table exists
- Check for permission/RLS errors in console

---

**Status**: ✅ Ready to use - No additional SQL needed

