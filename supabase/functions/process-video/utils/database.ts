import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { DatabaseError, NotFoundError, ValidationError } from './errors.ts'

export async function getVideoDetails(videoId: string, supabase: SupabaseClient) {
  try {
    if (!videoId) {
      throw new ValidationError('Video ID is required');
    }

    // First check if the video exists
    const { count, error: countError } = await supabase
      .from('video_queue')
      .select('*', { count: 'exact', head: true })
      .eq('id', videoId);

    if (countError) {
      throw new DatabaseError(
        'Failed to check video existence',
        countError.code,
        countError.details,
        countError.hint
      );
    }

    if (count === 0) {
      throw new NotFoundError(`Video with ID ${videoId} not found`);
    }

    if (count > 1) {
      throw new DatabaseError(`Multiple videos found with ID ${videoId}`);
    }

    // Now safely fetch the single video
    const { data, error } = await supabase
      .from('video_queue')
      .select('*')
      .eq('id', videoId)
      .limit(1)
      .single();

    if (error) {
      throw new DatabaseError(
        'Failed to fetch video details',
        error.code,
        error.details,
        error.hint
      );
    }

    return data;
  } catch (error) {
    // Log the error for debugging
    console.error('Error in getVideoDetails:', error);
    
    // Rethrow with appropriate error type
    if (error instanceof ValidationError || 
        error instanceof NotFoundError || 
        error instanceof DatabaseError) {
      throw error;
    }
    
    throw new DatabaseError('An unexpected error occurred while fetching video details');
  }
}