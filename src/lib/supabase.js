import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://toobrchgcvfbwusrgvrj.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRvb2JyY2hnY3ZmYnd1c3JndnJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ2MDU0MTEsImV4cCI6MjA1MDE4MTQxMX0.zyAI2rLbgE43XpkFcLTkbREZeqoGL1zHV74dxiCfrAM';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);