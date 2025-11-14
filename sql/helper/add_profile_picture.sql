-- Add profile picture support to helpers table
ALTER TABLE helpers 
ADD COLUMN IF NOT EXISTS profile_picture_base64 TEXT;

-- Add comment for the new column
COMMENT ON COLUMN helpers.profile_picture_base64 IS 'Base64 encoded profile picture data for the helper';

-- Create a small partial index to speed up queries that check presence of a profile picture
-- Avoid indexing the full base64 column (can exceed Postgres index row size).
-- Index only the row id for rows where the base64 column is not null.
CREATE INDEX IF NOT EXISTS idx_helpers_has_profile_picture ON helpers(id)
WHERE profile_picture_base64 IS NOT NULL;
