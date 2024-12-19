/*
  # Add Video Queue Triggers
  
  Creates triggers for:
  - Status transition validation
  - Automatic timestamp updates
*/

DO $$ 
BEGIN
    -- Drop existing triggers if they exist
    DROP TRIGGER IF EXISTS video_status_transition ON video_queue;
    DROP TRIGGER IF EXISTS update_video_queue_updated_at ON video_queue;
    
    -- Create new triggers
    CREATE TRIGGER video_status_transition
        BEFORE UPDATE OF status ON video_queue
        FOR EACH ROW
        EXECUTE FUNCTION check_video_status_transition();

    CREATE TRIGGER update_video_queue_updated_at
        BEFORE UPDATE ON video_queue
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
END $$;