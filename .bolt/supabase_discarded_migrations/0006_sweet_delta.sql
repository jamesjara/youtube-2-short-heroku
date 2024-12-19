/*
  # Add Video Queue Functions and Triggers
  
  Adds functions for:
  - Status transition validation
  - Automatic timestamp updates
*/

-- Drop existing functions
DROP FUNCTION IF EXISTS check_video_status_transition() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Create status transition function
CREATE FUNCTION check_video_status_transition()
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

    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create updated_at function
CREATE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;