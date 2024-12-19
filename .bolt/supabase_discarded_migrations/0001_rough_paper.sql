/*
  # Video Processing Queue

  1. New Tables
    - `video_queue`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `youtube_url` (text)
      - `start_time` (integer)
      - `duration` (integer)
      - `platform` (text)
      - `status` (text)
      - `output_url` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
  
  2. Security
    - Enable RLS on video_queue table
    - Add policies for users to manage their own videos
*/

CREATE TABLE IF NOT EXISTS video_queue (
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

ALTER TABLE video_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own videos"
  ON video_queue
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own videos"
  ON video_queue
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);