import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export async function validateRequest(req: Request, supabase: SupabaseClient) {
  const token = req.headers.get('Authorization')?.split(' ')[1] ?? ''
  const { data: { user }, error } = await supabase.auth.getUser(token)
  
  if (error || !user) return null
  return user
}