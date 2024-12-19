/*
  # Fix video processing and storage handling

  1. Changes
    - Add unique constraint to video_queue table
    - Update storage policies to use video ID instead of user folder
    - Add indexes for better query performance

  2. Security
    - Maintain RLS policies
    - Update storage policies for better security
*/

-- Add unique constraint and index
ALTER TABLE video_queue 
ADD CONSTRAINT unique_user_video 
UNIQUE (user_id, youtube_url, start_time, duration);

CREATE INDEX idx_video_queue_status 
ON video_queue(status);

-- Update storage policies
DROP POLICY IF EXISTS "Authenticated users can upload videos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update their videos" ON storage.objects;

CREATE POLICY "Authenticated users can upload videos"
ON storage.objects FOR INSERT 
TO authenticated
WITH CHECK (
  bucket_id = 'videos' 
  AND EXISTS (
    SELECT 1 FROM video_queue
    WHERE id::text = storage.foldername(name)
    AND user_id = auth.uid()
  )
);

CREATE POLICY "Authenticated users can update their videos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'videos' 
  AND EXISTS (
    SELECT 1 FROM video_queue
    WHERE id::text = storage.foldername(name)
    AND user_id = auth.uid()
  )
);