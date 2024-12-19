/*
  # Video Processing System Schema

  1. Types
    - video_status enum for tracking processing states
    - Values: pending, processing, completed, failed

  2. Tables
    - video_queue: Stores video processing requests
    - Includes user reference, video details, and processing status

  3. Security
    - RLS enabled
    - Policies for user data access

  4. Triggers
    - Status transition validation
    - Timestamp management
*/

-- Check if type already exists and drop if needed
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'video_status') THEN
        CREATE TYPE video_status AS ENUM (
            'pending',
            'processing',
            'completed',
            'failed'
        );
    END IF;
END $$;

-- Create video queue table if it doesn't exist
CREATE TABLE IF NOT EXISTS video_queue (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users NOT NULL,
    youtube_url text NOT NULL,
    start_time integer NOT NULL,
    duration integer NOT NULL,
    platform text NOT NULL,
    status video_status NOT NULL DEFAULT 'pending',
    version integer NOT NULL DEFAULT 1,
    output_url text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE video_queue ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can insert their own videos" ON video_queue;
DROP POLICY IF EXISTS "Users can view their own videos" ON video_queue;

-- Create policies
CREATE POLICY "Users can insert their own videos"
    ON video_queue FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own videos"
    ON video_queue FOR SELECT 
    TO authenticated
    USING (auth.uid() = user_id);

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS check_video_status_transition() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Create status transition function
CREATE FUNCTION check_video_status_transition()
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

    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create updated_at function
CREATE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER video_status_transition
    BEFORE UPDATE OF status ON video_queue
    FOR EACH ROW
    EXECUTE FUNCTION check_video_status_transition();

CREATE TRIGGER update_video_queue_updated_at
    BEFORE UPDATE ON video_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();