-- Add profile_picture_url (public URL) support to helpers table
ALTER TABLE helpers
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;

-- Add comment for the new column
COMMENT ON COLUMN helpers.profile_picture_url IS 'Public URL (e.g. Supabase Storage) for the helper profile picture';

-- Create index to speed up queries that filter by presence of a URL
CREATE INDEX IF NOT EXISTS idx_helpers_profile_picture_url ON helpers(profile_picture_url)
WHERE profile_picture_url IS NOT NULL;
