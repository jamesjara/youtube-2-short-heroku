/*
  # Create Video Queue Table
  
  1. Table Structure
    - `id`: UUID primary key
    - `user_id`: References auth.users
    - `youtube_url`: Video source URL
    - `start_time`: Start timestamp in seconds
    - `duration`: Video length in seconds
    - `platform`: Target platform
    - `status`: Current processing status
    - `version`: Optimistic locking
    - `output_url`: Processed video URL
    - Timestamps for created_at and updated_at
  
  2. Security
    - Enable RLS
    - Add policies for user access
*/

CREATE TABLE video_queue (
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