import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { processYouTubeVideo } from './videoProcessor.ts'
import { validateRequest } from './utils/auth.ts'
import { getVideoDetails } from './utils/database.ts'
import { corsHeaders } from './utils/cors.ts'
import { NotFoundError, ValidationError, DatabaseError } from './utils/errors.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    const user = await validateRequest(req, supabaseClient)
    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }), 
        { 
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    const { videoId } = await req.json()
    
    try {
      const video = await getVideoDetails(videoId, supabaseClient)
      const outputUrl = await processYouTubeVideo(video)

      await supabaseClient
        .from('video_queue')
        .update({ 
          status: 'completed',
          output_url: outputUrl,
          updated_at: new Date().toISOString()
        })
        .eq('id', videoId)

      return new Response(
        JSON.stringify({ success: true, outputUrl }), 
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    } catch (error) {
      const status = error instanceof NotFoundError ? 404 :
                    error instanceof ValidationError ? 400 :
                    error instanceof DatabaseError ? 500 : 500;

      return new Response(
        JSON.stringify({ error: error.message }), 
        { 
          status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Internal server error' }), 
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})