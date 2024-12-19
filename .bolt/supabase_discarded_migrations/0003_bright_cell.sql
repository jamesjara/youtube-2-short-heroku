/*
  # Update Video Queue Schema

  1. Changes
    - Removes version-based locking
    - Simplifies status transitions
    - Adds data validation constraints
    - Updates indexes for performance

  2. Security
    - Maintains existing RLS policies
    - Ensures data integrity with constraints
*/

-- Add constraints if they don't exist
DO $$ BEGIN
    ALTER TABLE video_queue 
        ADD CONSTRAINT video_queue_start_time_check 
        CHECK (start_time >= 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE video_queue 
        ADD CONSTRAINT video_queue_duration_check 
        CHECK (duration > 0 AND duration <= 60);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE video_queue 
        ADD CONSTRAINT video_queue_platform_check 
        CHECK (platform IN ('TikTok', 'Instagram Reels', 'YouTube Shorts'));
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create indexes if they don't exist
DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_video_queue_user_id ON video_queue(user_id);
    CREATE INDEX IF NOT EXISTS idx_video_queue_status ON video_queue(status);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Update status transition trigger
CREATE OR REPLACE FUNCTION check_video_status_transition()
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

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;