/*
  # Add Video Queue Security Policies
  
  Sets up RLS policies for user access control
*/

-- Safely handle policies
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can insert their own videos" ON video_queue;
    DROP POLICY IF EXISTS "Users can view their own videos" ON video_queue;
END $$;

-- Create policies
CREATE POLICY "Users can insert their own videos"
    ON video_queue FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own videos"
    ON video_queue FOR SELECT 
    TO authenticated
    USING (auth.uid() = user_id);