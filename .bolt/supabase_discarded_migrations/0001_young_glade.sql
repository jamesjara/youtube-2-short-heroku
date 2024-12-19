/*
  # Add videos table and policies

  1. New Tables
    - `videos`
      - Stores video processing metadata and user associations
      - Includes status tracking and output URL storage
      - Links to auth.users for ownership

  2. Security
    - Row Level Security (RLS) enabled
    - Policies for user data access control
    - Users can only view and create their own videos
*/

-- Create videos table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'videos') THEN
    CREATE TABLE videos (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      youtube_url text NOT NULL,
      start_time integer NOT NULL DEFAULT 0,
      duration integer NOT NULL,
      platform text NOT NULL,
      status text NOT NULL DEFAULT 'pending',
      output_url text,
      created_at timestamptz DEFAULT now(),
      user_id uuid REFERENCES auth.users(id)
    );

    -- Enable RLS
    ALTER TABLE videos ENABLE ROW LEVEL SECURITY;

    -- Create policies for data access
    CREATE POLICY "Users can view their own videos"
      ON videos
      FOR SELECT
      TO authenticated
      USING (auth.uid() = user_id);

    CREATE POLICY "Users can create their own videos"
      ON videos
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;