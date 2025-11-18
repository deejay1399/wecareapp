# WeCareApp Database Setup

This directory contains SQL scripts for setting up the database tables for the WeCareApp.

## Supabase Setup Instructions

### 1. Create a Supabase Project
1. Go to [Supabase](https://supabase.com)
2. Sign up/Login and create a new project
3. Wait for the project to be set up

### 2. Get Your Project Credentials
1. Go to Settings > API
2. Copy the Project URL and anon public key
3. Update `lib/utils/constants/supabase_config.dart` with your credentials:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
}
```

### 3. Run SQL Scripts
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Run the SQL scripts in the following order:

#### Employer Setup
- Execute `sql/employer/create_employer_table.sql`
- Execute `sql/employer/disable_rls_and_create_policies.sql`

This will create the employers table with the following structure:
- `id` (UUID, Primary Key)
- `first_name` (VARCHAR(50))
- `last_name` (VARCHAR(50))
- `email` (VARCHAR(255), Unique)
- `phone` (VARCHAR(20), Unique)
- `password_hash` (VARCHAR(255))
- `barangay` (VARCHAR(100))
- `barangay_clearance_base64` (TEXT) - Stores base64 encoded image
- `is_verified` (BOOLEAN)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### Helper Setup
- Execute `sql/helper/create_helper_table.sql`
- Execute `sql/helper/disable_rls_and_create_policies.sql`

#### Job Postings Setup
- Execute `sql/job_postings/create_job_postings_table.sql`
- Execute `sql/job_postings/disable_rls_and_create_policies.sql`

**Important Migration Note**: If you already have a `job_postings` table created before the latest updates, you need to run the migration script to add missing columns:
- Execute `sql/job_postings/add_missing_columns.sql`

#### Applications Setup
- Execute `sql/applications/create_applications_table.sql`
- Execute `sql/applications/disable_rls_and_create_policies.sql`

#### Ratings Setup
- Execute `sql/ratings/create_ratings_table.sql`
- Execute `sql/ratings/disable_rls_and_create_policies.sql`

#### Messaging Setup
- Execute `sql/conversations/create_conversations_table.sql`
- Execute `sql/conversations/disable_rls_and_create_policies.sql`
- Execute `sql/messages/create_messages_table.sql`
- Execute `sql/messages/disable_rls_and_create_policies.sql`

#### Job Offers Setup
- Execute `sql/job_offers/create_job_offers_table.sql`
- Execute `sql/job_offers/disable_rls_and_create_policies.sql`

#### Notifications Setup
- Execute `sql/notifications/create_notifications_table.sql`
- Execute `sql/notifications/disable_rls_and_create_policies.sql`

This will create the helpers table with the following structure:
- `id` (UUID, Primary Key)
- `first_name` (VARCHAR(50))
- `last_name` (VARCHAR(50))
- `email` (VARCHAR(255), Unique)
- `phone` (VARCHAR(20), Unique)
- `password_hash` (VARCHAR(255))
- `skill` (VARCHAR(100)) - Helper's primary skill
- `experience` (VARCHAR(50)) - Years of experience
- `barangay` (VARCHAR(100))
- `barangay_clearance_base64` (TEXT) - Stores base64 encoded image
- `is_verified` (BOOLEAN)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

This will create the job_postings table with the following structure:
- `id` (UUID, Primary Key)
- `employer_id` (UUID, Foreign Key to employers table)
- `title` (VARCHAR(200)) - Job title
- `description` (TEXT) - Job description
- `salary` (DECIMAL(10,2)) - Salary amount
- `payment_frequency` (VARCHAR(50)) - Payment frequency (Per Hour, Per Day, Per Week, bi weekly, Per Month)
- `barangay` (VARCHAR(100)) - Job location
- `required_skills` (TEXT[]) - Array of required skills
- `status` (VARCHAR(20)) - Job status (active, paused, closed)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

This will create the applications table with the following structure:
- `id` (UUID, Primary Key)
- `job_posting_id` (UUID, Foreign Key to job_postings table)
- `helper_id` (UUID, Foreign Key to helpers table)
- `cover_letter` (TEXT) - Application cover letter
- `status` (VARCHAR(20)) - Application status (pending, accepted, rejected, withdrawn)
- `applied_at` (TIMESTAMP) - When application was submitted
- `updated_at` (TIMESTAMP)

This will create the ratings table with the following structure:
- `id` (UUID, Primary Key)
- `rater_id` (UUID) - ID of the person giving the rating
- `rater_type` (VARCHAR(20)) - Type of rater (helper, employer)
- `rated_id` (UUID) - ID of the person being rated
- `rated_type` (VARCHAR(20)) - Type of person being rated (helper, employer)
- `job_posting_id` (UUID) - Optional reference to job posting
- `service_posting_id` (UUID) - Optional reference to service posting
- `rating` (INTEGER) - Rating from 1 to 5 stars
- `review_text` (TEXT) - Optional review comment
- `is_anonymous` (BOOLEAN) - Whether the rating is anonymous
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

This will create the conversations table with the following structure:
- `id` (TEXT, Primary Key) - Unique conversation identifier
- `employer_id` (UUID, Foreign Key to employers table)
- `employer_name` (TEXT) - Employer display name
- `helper_id` (UUID, Foreign Key to helpers table)
- `helper_name` (TEXT) - Helper display name
- `job_id` (TEXT) - Reference to job/service
- `job_title` (TEXT) - Job/service title
- `status` (TEXT) - Conversation status (active, archived, blocked)
- `unread_count_employer` (INTEGER) - Unread messages count for employer
- `unread_count_helper` (INTEGER) - Unread messages count for helper
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

This will create the messages table with the following structure:
- `id` (TEXT, Primary Key) - Unique message identifier
- `conversation_id` (TEXT, Foreign Key to conversations table)
- `sender_id` (UUID) - ID of message sender
- `sender_type` (TEXT) - Type of sender (Employer, Helper)
- `sender_name` (TEXT) - Display name of sender
- `content` (TEXT) - Message content
- `message_type` (TEXT) - Type of message (text, image, file)
- `status` (TEXT) - Message status (sent, delivered, read)
- `created_at` (TIMESTAMP)
- `read_at` (TIMESTAMP) - When message was read

This will create the job_offers table with the following structure:
- `id` (UUID, Primary Key)
- `conversation_id` (TEXT, Foreign Key to conversations table)
- `employer_id` (UUID, Foreign Key to employers table)
- `helper_id` (UUID, Foreign Key to helpers table)
- `service_posting_id` (UUID, Foreign Key to helper_service_postings table)
- `title` (TEXT) - Job offer title
- `description` (TEXT) - Job offer description
- `salary` (DECIMAL(10,2)) - Offered salary
- `payment_frequency` (TEXT) - Payment frequency
- `location` (TEXT) - Job location
- `required_skills` (TEXT[]) - Array of required skills
- `status` (TEXT) - Offer status (pending, accepted, rejected, expired)
- `rejection_reason` (TEXT) - Optional rejection reason
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

This will create the notifications table with the following structure:
- `id` (UUID, Primary Key)
- `recipient_id` (UUID) - ID of user who receives the notification (can be helper or employer)
- `recipient_type` (VARCHAR(20)) - Type of recipient (helper, employer)
- `title` (TEXT) - Notification title
- `body` (TEXT) - Notification message body
- `type` (VARCHAR(50)) - Notification type (job_application, application_accepted, application_rejected, etc.)
- `category` (VARCHAR(50)) - Notification category (new, update, alert, message)
- `target_id` (UUID) - Reference to related entity (e.g., job_posting_id)
- `is_read` (BOOLEAN) - Whether notification has been read
- `timestamp` (TIMESTAMP) - When notification was created
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)
- `responded_at` (TIMESTAMP) - When helper responded to offer

### 4. Fix 401 Unauthorized Error
If you get a 401 Unauthorized error when trying to register/login, it means Row Level Security (RLS) is enabled on your tables. Since we're not using Supabase Auth, you need to disable RLS:

**Solution**: Run the respective `disable_rls_and_create_policies.sql` scripts in your Supabase SQL Editor.

These scripts disable RLS on both employers and helpers tables, allowing direct access with the anon key.

### 5. Set Row Level Security (Optional for Production)
For production apps, you may want to enable RLS with custom policies instead of disabling it completely. The `disable_rls_and_create_policies.sql` files contain commented examples of how to set up policies for anonymous access.

## Important Notes

- **Password Security**: Passwords are hashed using SHA-256 with salt
- **No Supabase Auth**: This implementation uses custom authentication tables instead of Supabase's built-in auth
- **Phone Format**: Phone numbers are stored with +63 prefix for Philippine numbers
- **Image Storage**: Barangay clearance images are stored as base64 encoded strings directly in the database
- **Image Types**: Only image files (JPG, PNG) are accepted for barangay clearance uploads
- **RLS Disabled**: Row Level Security is disabled to allow direct table access without authentication
- **Skills & Experience**: Helper table includes skill and experience fields for profile management

## Testing the Setup

1. Make sure you've updated the Supabase configuration
2. Run all SQL scripts (both employer and helper setup)
3. Run the Flutter app
4. Try registering new employer and helper accounts with image uploads
5. Try logging in with the created accounts
6. Check your Supabase dashboard to see the data in both tables

## Troubleshooting

### 401 Unauthorized Error
- **Cause**: Row Level Security is enabled on the tables
- **Solution**: Run the respective `disable_rls_and_create_policies.sql` scripts
- **Check**: Go to Database > Tables > employers/helpers > Settings and verify RLS is disabled

### Unable to Insert Data
- **Cause**: Missing permissions or RLS blocking access
- **Solution**: Ensure RLS is disabled or proper policies are in place

### Login Not Working
- **Cause**: Table doesn't exist or wrong credentials
- **Solution**: Verify tables are created and test with registered account credentials

## Future Enhancements

- Add image compression before base64 encoding to reduce database size
- Implement password reset functionality
- Add email verification
- Set up proper RLS policies for production
- Consider using Supabase Storage for large images if base64 becomes inefficient
- Add helper skill verification system
- Implement helper rating and review system
