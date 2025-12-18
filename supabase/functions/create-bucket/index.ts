import { serve } from "https://deno.land/std@0.181.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.34.0";

interface RequestBody {
  user_id: number;
  title: string;
  description?: string | null;
  is_private?: boolean;
  completion_date?: string | null; // ISO date
}

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars');
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

serve(async (req: Request) => {
  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { 'Content-Type': 'application/json' } });
    }

    const contentType = req.headers.get('content-type') || '';
    if (!contentType.includes('application/json')) {
      return new Response(JSON.stringify({ error: 'Expected application/json' }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }

    const body: RequestBody = await req.json().catch(() => null);
    if (!body) return new Response(JSON.stringify({ error: 'Invalid JSON body' }), { status: 400, headers: { 'Content-Type': 'application/json' } });

    const { user_id, title, description = null, is_private = false, completion_date = null } = body;

    if (typeof user_id !== 'number' || !Number.isInteger(user_id)) {
      return new Response(JSON.stringify({ error: 'user_id is required and must be an integer' }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
    if (!title || typeof title !== 'string') {
      return new Response(JSON.stringify({ error: 'title is required and must be a string' }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }

    // generate uid
    const uid = crypto.randomUUID();

    // Insert into buckets and return the row
    const { data: bucketData, error: bucketError } = await supabase
      .from('buckets')
      .insert([{ uid, title, description, completion_date, is_private, related_user_id: user_id, created_by: user_id, creator: 'edge-function' }])
      .select('*')
      .single();

    if (bucketError) {
      console.error('Insert bucket error', bucketError);
      return new Response(JSON.stringify({ error: 'Failed to insert bucket', details: bucketError.message }), { status: 500, headers: { 'Content-Type': 'application/json' } });
    }

    const bucketId = (bucketData as any).id;

    const { data: userBucketData, error: userBucketError } = await supabase
      .from('users_buckets')
      .insert([{ user_id, bucket_id: bucketId, bucket_uid: uid }])
      .select('*')
      .single();

    if (userBucketError) {
      console.error('Insert users_buckets error', userBucketError);
      return new Response(JSON.stringify({ error: 'Failed to insert users_buckets', details: userBucketError.message }), { status: 500, headers: { 'Content-Type': 'application/json' } });
    }

    const responseBody = {
      bucket: bucketData,
      user_bucket: userBucketData,
    };

    return new Response(JSON.stringify(responseBody), { status: 201, headers: { 'Content-Type': 'application/json' } });
  } catch (err) {
    console.error('Unhandled error', err);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }
});
