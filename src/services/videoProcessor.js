import { supabase } from '../lib/supabase';
import ytdl from 'ytdl-core';
import { retry } from '../utils/retry';

export async function processVideo(videoData) {
  const retryOptions = {
    maxAttempts: 3,
    delay: 2000,
    backoff: 2,
    onRetry: (error, attempt) => {
      console.warn(`Retry attempt ${attempt} due to error:`, error.message);
    }
  };

  try {
    return await retry(async () => {
      // Download video using ytdl-core
      const videoStream = ytdl(videoData.youtube_url, {
        quality: 'highest',
        filter: 'videoandaudio'
      });

      // Convert stream to blob for upload
      const chunks = [];
      for await (const chunk of videoStream) {
        chunks.push(chunk);
      }
      const videoBlob = new Blob(chunks, { type: 'video/mp4' });

      // Upload to Supabase storage
      const fileName = `${videoData.user_id}/${Date.now()}.mp4`;
      const { data: { publicUrl }, error: uploadError } = await supabase.storage
        .from('videos')
        .upload(fileName, videoBlob);

      if (uploadError) throw uploadError;

      // Update video status
      const { error: updateError } = await supabase
        .from('video_queue')
        .update({ 
          status: 'processing',
          output_url: publicUrl 
        })
        .eq('id', videoData.id);

      if (updateError) throw updateError;

      return publicUrl;
    }, retryOptions);
  } catch (error) {
    console.error('Error processing video after retries:', error);
    
    // Update video status to failed
    await supabase
      .from('video_queue')
      .update({ 
        status: 'failed',
        updated_at: new Date().toISOString()
      })
      .eq('id', videoData.id);

    throw error;
  }
}