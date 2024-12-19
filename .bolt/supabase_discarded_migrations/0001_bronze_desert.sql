/*
  # Storage Policies for Video Processing

  1. Storage Bucket
    - Create videos bucket for storing processed videos
  
  2. Security
    - Enable policies for authenticated users
*/

-- Create a storage bucket for videos
INSERT INTO storage.buckets (id, name)
VALUES ('videos', 'videos')
ON CONFLICT DO NOTHING;

-- Allow authenticated users to upload videos
CREATE POLICY "Users can upload their own videos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'videos' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to read their own videos
CREATE POLICY "Users can read their own videos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'videos' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);