import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export async function uploadToStorage(
  videoData: Uint8Array,
  fileName: string,
  supabase: SupabaseClient
): Promise<string> {
  const { error } = await supabase.storage
    .from('videos')
    .upload(fileName, videoData, {
      contentType: 'video/mp4',
      upsert: true
    })

  if (error) throw error

  const { data: { publicUrl } } = supabase.storage
    .from('videos')
    .getPublicUrl(fileName)

  return publicUrl
}