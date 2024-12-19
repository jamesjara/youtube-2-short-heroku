/*
  # Video Processing System Tables

  1. New Tables
    - `video_queue`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `youtube_url` (text)
      - `start_time` (integer)
      - `duration` (integer)
      - `platform` (text)
      - `status` (video_status enum)
      - `output_url` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. New Types
    - `video_status` enum for tracking video processing states

  3. Security
    - Enable RLS on video_queue table
    - Add policies for authenticated users to manage their videos
    - Add constraints for data validation

  4. Triggers
    - Auto-update updated_at timestamp
    - Validate status transitions
*/

-- Create video status type if it doesn't exist
DO $$ BEGIN
    CREATE TYPE video_status AS ENUM (
        'pending',
        'processing',
        'completed',
        'failed'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create video queue table
CREATE TABLE IF NOT EXISTS video_queue (
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

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_video_queue_user_id ON video_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_video_queue_status ON video_queue(status);

-- Enable Row Level Security
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