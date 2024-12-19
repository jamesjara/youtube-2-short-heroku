/*
  # Complete Schema Recreation

  1. Changes
    - Drops all existing tables and types
    - Recreates video_queue table with improved structure
    - Adds proper constraints and indexes
    - Sets up RLS policies

  2. Security
    - Enables RLS
    - Creates policies for user data access
    - Adds proper constraints for data validation
*/

-- Drop existing objects
DROP TABLE IF EXISTS video_queue CASCADE;
DROP TYPE IF EXISTS video_status CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;
DROP FUNCTION IF EXISTS check_video_status_transition CASCADE;

-- Create video status type
CREATE TYPE video_status AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed'
);

-- Create video queue table
CREATE TABLE video_queue (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users NOT NULL,
    youtube_url text NOT NULL,
    start_time integer NOT NULL CHECK (start_time >= 0),
    duration integer NOT NULL CHECK (duration > 0 AND duration <= 60),
    platform text NOT NULL CHECK (platform IN ('TikTok', 'Instagram Reels', 'YouTube Shorts')),
    status video_status NOT NULL DEFAULT 'pending',
    output_url text,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_video_queue_user_id ON video_queue(user_id);
CREATE INDEX idx_video_queue_status ON video_queue(status);

-- Enable RLS
ALTER TABLE video_queue ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can insert their own videos"
    ON video_queue FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own videos"
    ON video_queue FOR SELECT 
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own videos"
    ON video_queue FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create updated_at trigger
CREATE TRIGGER update_video_queue_updated_at
    BEFORE UPDATE ON video_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create status transition trigger function
CREATE OR REPLACE FUNCTION check_video_status_transition()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'pending' AND NEW.status NOT IN ('processing', 'failed') THEN
        RAISE EXCEPTION 'Invalid status transition from pending';
    END IF;
    
    IF OLD.status = 'processing' AND NEW.status NOT IN ('completed', 'failed') THEN
        RAISE EXCEPTION 'Invalid status transition from processing';
    END IF;
    
    IF OLD.status IN ('completed', 'failed') THEN
        RAISE EXCEPTION 'Cannot transition from final status';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create status transition trigger
CREATE TRIGGER video_status_transition
    BEFORE UPDATE OF status ON video_queue
    FOR EACH ROW
    EXECUTE FUNCTION check_video_status_transition();