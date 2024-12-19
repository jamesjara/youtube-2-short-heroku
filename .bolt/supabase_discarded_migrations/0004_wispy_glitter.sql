/*
  # Create Video Queue Table
  
  Creates the main video_queue table and enables RLS
*/

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