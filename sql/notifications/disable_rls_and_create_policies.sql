-- Disable Row Level Security for notifications table
-- This allows direct access with the anon key without Supabase Auth
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- Grant necessary permissions for anonymous access
GRANT ALL ON TABLE notifications TO anon;
GRANT ALL ON TABLE notifications TO authenticated;

-- Optional: If you want to enable RLS in the future with custom policies,
-- uncomment the following lines and modify them according to your needs:

-- Enable RLS
-- ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Allow users to view their own notifications
-- CREATE POLICY "Users can view their own notifications" ON notifications
--   FOR SELECT USING (recipient_id = auth.uid());

-- Allow service to create notifications for users
-- CREATE POLICY "Service can create notifications" ON notifications
--   FOR INSERT WITH CHECK (true);

-- Allow users to update their own notifications (mark as read)
-- CREATE POLICY "Users can update their own notifications" ON notifications
--   FOR UPDATE USING (recipient_id = auth.uid());

-- Allow users to delete their own notifications
-- CREATE POLICY "Users can delete their own notifications" ON notifications
--   FOR DELETE USING (recipient_id = auth.uid());

-- Note: RLS is disabled for this table. Authorization is handled at the application level.
