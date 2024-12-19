import { download } from 'https://deno.land/x/download@v1.0.1/mod.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { retry } from './utils/retry.ts'

interface VideoData {
  id: string
  youtube_url: string
  start_time: number
  duration: number
  platform: string
  user_id: string
}

export async function processYouTubeVideo(video: VideoData): Promise<string> {
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const retryOptions = {
    maxAttempts: 3,
    delay: 2000,
    backoff: 2,
    onRetry: (error: Error, attempt: number) => {
      console.warn(`Retry attempt ${attempt} for video ${video.id}:`, error.message)
    }
  }

  try {
    return await retry(async () => {
      // Download and process video
      const videoData = await download(video.youtube_url)
      const processedVideo = await processVideo(videoData, {
        startTime: video.start_time,
        duration: video.duration,
        platform: video.platform
      })
      
      const fileName = `${video.id}/processed.mp4`
      const uploadUrl = await uploadToStorage(processedVideo, fileName, supabaseClient)
      
      return uploadUrl
    }, retryOptions)
  } catch (error) {
    // Mark as failed on error
    await supabaseClient
      .from('video_queue')
      .update({ 
        status: 'failed',
        updated_at: new Date().toISOString()
      })
      .eq('id', video.id)

    throw error
  }
}