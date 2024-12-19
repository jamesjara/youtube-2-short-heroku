/*
  # Video Processing Infrastructure

  1. New Tables
    - `video_queue` for tracking video processing jobs
    - Includes user reference, video details, and processing status
  
  2. Security
    - Enable RLS
    - Add policies for authenticated users
    - Set up storage policies for video uploads
*/

-- Create video_queue table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'video_queue') THEN
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
  END IF;
END $$;

-- Enable RLS
ALTER TABLE video_queue ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Users can insert their own videos" ON video_queue;
  DROP POLICY IF EXISTS "Users can view their own videos" ON video_queue;
END $$;

-- Create policies
CREATE POLICY "Users can insert their own videos"
ON video_queue FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own videos"
ON video_queue FOR SELECT 
TO authenticated
USING (auth.uid() = user_id);

-- Create or replace updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS update_video_queue_updated_at ON video_queue;
CREATE TRIGGER update_video_queue_updated_at
  BEFORE UPDATE ON video_queue
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();

-- Create storage bucket if it doesn't exist
DO $$
BEGIN
  INSERT INTO storage.buckets (id, name, public)
  VALUES ('videos', 'videos', true)
  ON CONFLICT (id) DO NOTHING;
END $$;

-- Drop existing storage policies if they exist
DO $$
BEGIN
  DROP POLICY IF EXISTS "Authenticated users can upload videos" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can update their videos" ON storage.objects;
  DROP POLICY IF EXISTS "Anyone can view videos" ON storage.objects;
END $$;

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