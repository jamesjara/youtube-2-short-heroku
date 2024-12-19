/*
  # Add version control and status management
  
  1. Changes
    - Add version column for optimistic concurrency control
    - Create and implement video status enum
    - Add status transition constraints
    - Set up status validation trigger
  
  2. Security
    - Maintain existing RLS policies
    - Ensure data integrity through constraints
*/

-- Create video status enum type
CREATE TYPE video_status AS ENUM ('pending', 'processing', 'completed', 'failed');

-- Create video_queue table with proper types
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

-- Create policies
CREATE POLICY "Users can insert their own videos"
ON video_queue FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own videos"
ON video_queue FOR SELECT 
TO authenticated
USING (auth.uid() = user_id);

-- Create status transition check function
CREATE OR REPLACE FUNCTION check_video_status_transition()
RETURNS TRIGGER AS $$
BEGIN
  -- Only allow specific status transitions
  IF OLD.status = 'pending' AND NEW.status NOT IN ('processing', 'failed') THEN
    RAISE EXCEPTION 'Invalid status transition from pending';
  END IF;
  
  IF OLD.status = 'processing' AND NEW.status NOT IN ('completed', 'failed') THEN
    RAISE EXCEPTION 'Invalid status transition from processing';
  END IF;
  
  IF OLD.status IN ('completed', 'failed') THEN
    RAISE EXCEPTION 'Cannot transition from final status';
  END IF;

  -- Increment version on status change
  NEW.version = OLD.version + 1;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for status transitions
CREATE TRIGGER video_status_transition
  BEFORE UPDATE OF status ON video_queue
  FOR EACH ROW
  EXECUTE FUNCTION check_video_status_transition();

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_video_queue_updated_at
  BEFORE UPDATE ON video_queue
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();