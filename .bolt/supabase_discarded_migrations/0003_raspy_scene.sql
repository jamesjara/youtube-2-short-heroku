/*
  # Create Video Processing Triggers
  
  1. Functions
    - Status transition validation
    - Updated timestamp management
  
  2. Triggers
    - Validate status changes
    - Update timestamps
*/

-- Status transition validator
CREATE FUNCTION check_video_status_transition()
RETURNS TRIGGER AS $$
BEGIN
  -- Only allow specific status transitions
  IF OLD.status = 'pending' AND NEW.status NOT IN ('processing', 'failed') THEN
    RAISE EXCEPTION 'Invalid status transition from pending';
  END IF;
  
  IF OLD.status = 'processing' AND NEW.status NOT IN ('completed', 'failed') THEN
    RAISE EXCEPTION 'Invalid status transition from processing';
  END IF;
  
  IF OLD.status IN ('completed', 'failed') THEN
    RAISE EXCEPTION 'Cannot transition from final status';
  END IF;

  -- Increment version on status change
  NEW.version = OLD.version + 1;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Updated timestamp manager
CREATE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER video_status_transition
  BEFORE UPDATE OF status ON video_queue
  FOR EACH ROW
  EXECUTE FUNCTION check_video_status_transition();

CREATE TRIGGER update_video_queue_updated_at
  BEFORE UPDATE ON video_queue
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();