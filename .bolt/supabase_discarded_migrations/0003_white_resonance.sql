/*
  # Remove version tracking from video queue

  1. Changes
    - Remove version column and related functions
    - Update status transition logic
    - Maintain data integrity during migration

  2. Security
    - Preserves existing RLS policies
    - No changes to security model
*/

-- Safely drop version column if it exists
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'video_queue' 
        AND column_name = 'version'
    ) THEN
        ALTER TABLE video_queue DROP COLUMN version;
    END IF;
END $$;

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS video_status_transition ON video_queue;
DROP FUNCTION IF EXISTS check_video_status_transition();

-- Create new status transition function without version tracking
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

-- Create new trigger
CREATE TRIGGER video_status_transition
    BEFORE UPDATE OF status ON video_queue
    FOR EACH ROW
    EXECUTE FUNCTION check_video_status_transition();