/*
  # Video Queue and Storage Setup

  1. Tables
    - `video_queue`: Tracks video processing jobs
      - id: Unique identifier
      - user_id: Reference to auth.users
      - youtube_url: Source video URL
      - start_time: Video start position
      - duration: Video length
      - platform: Target platform
      - status: Processing status
      - output_url: Processed video URL
      - created_at: Creation timestamp
      - updated_at: Last update timestamp

  2. Security
    - Row Level Security (RLS) enabled
    - Policies for user data access
    - Storage policies for video uploads

  3. Storage
    - Public bucket for processed videos
    - Secure upload/update policies
*/

-- Drop existing objects
DROP TABLE IF EXISTS video_queue CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;

-- Drop existing storage policies
DO $$
BEGIN
  DROP POLICY IF EXISTS "Authenticated users can upload videos" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can update their videos" ON storage.objects;
  DROP POLICY IF EXISTS "Anyone can view videos" ON storage.objects;
EXCEPTION
  WHEN undefined_object THEN NULL;
END $$;

-- Create video_queue table
CREATE TABLE video_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  youtube_url text NOT NULL,
  start_time integer NOT NULL,
  duration integer NOT NULL,
  platform text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
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

-- Create updated_at trigger function
CREATE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger
CREATE TRIGGER update_video_queue_updated_at
  BEFORE UPDATE ON video_queue
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();

-- Create storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('videos', 'videos', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies
CREATE POLICY "Authenticated users can upload videos"
ON storage.objects FOR INSERT 
TO authenticated
WITH CHECK (bucket_id = 'videos' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Authenticated users can update their videos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'videos' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view videos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'videos');