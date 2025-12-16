import { createClient } from "@supabase/supabase-js";

// Centralized Supabase client and auth helpers
// - `supabase`: base client for any query / RPC
// - `signInWithOtp`: email magic-link / OTP sign-in
// - `signOut`: sign current user out
// - `posts` CRUD helpers: basic typed helpers for the `posts` table
//
// NOTE: On the server (Route Handlers / Server Components) prefer using
// `@supabase/auth-helpers-nextjs` with `createRouteHandlerClient` or
// `createServerComponentClient` so auth cookies are respected.

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error(
    "Missing Supabase environment variables. Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY"
  );
}

export const supabase = createClient(supabaseUrl, supabaseKey);

export async function signInWithOtp(email: string) {
  // Client-side email OTP / magic-link sign-in
  // See: https://supabase.com/docs/reference/javascript/auth-signinwithotp
  return supabase.auth.signInWithOtp({ email });
}

export async function signOut() {
  // Signs out the current user (client-side)
  // See: https://supabase.com/docs/reference/javascript/auth-signout
  return supabase.auth.signOut();
}

// ------- Posts CRUD helpers -------

// Adjust this type to match your `posts` table definition in Supabase
export type Post = {
  id: string; // uuid
  title: string;
  content: string | null;
  created_at: string; // ISO timestamp
  updated_at: string | null;
  author_id: string | null; // user id
  is_private: boolean; // NEW: true = private, false = public
};

// Create a new post
export async function createPost(input: {
  title: string;
  content?: string;
  isPrivate?: boolean; // NEW
}): Promise<{ data: Post | null; error: Error | null }> {
  const { data, error } = await supabase
    .from("posts")
    .insert({
      title: input.title,
      content: input.content ?? null,
      is_private: input.isPrivate ?? false, // default: public
    })
    .select()
    .single();

  return { data: data as Post | null, error: error as Error | null };
}

// Read: list posts (optionally by author)
export async function listPosts(options?: {
  authorId?: string;
  onlyPrivate?: boolean;
  onlyPublic?: boolean;
}): Promise<{ data: Post[] | null; error: Error | null }> {
  let query = supabase.from("posts").select("*").order("created_at", { ascending: false });

  if (options?.authorId) {
    query = query.eq("author_id", options.authorId);
  }

  if (options?.onlyPrivate) {
    query = query.eq("is_private", true);
  }

  if (options?.onlyPublic) {
    query = query.eq("is_private", false);
  }

  const { data, error } = await query;
  return { data: data as Post[] | null, error: error as Error | null };
}

// Read: get a single post by id
export async function getPostById(id: string): Promise<{
  data: Post | null;
  error: Error | null;
}> {
  const { data, error } = await supabase.from("posts").select("*").eq("id", id).single();

  return { data: data as Post | null, error: error as Error | null };
}

// Update a post
export async function updatePost(
  id: string,
  input: {
    title?: string;
    content?: string | null;
    isPrivate?: boolean; // NEW
  }
): Promise<{ data: Post | null; error: Error | null }> {
  const payload: Record<string, unknown> = {};

  if (input.title !== undefined) payload.title = input.title;
  if (input.content !== undefined) payload.content = input.content;
  if (input.isPrivate !== undefined) payload.is_private = input.isPrivate;

  const { data, error } = await supabase
    .from("posts")
    .update(payload)
    .eq("id", id)
    .select()
    .single();

  return { data: data as Post | null, error: error as Error | null };
}

// Delete a post
export async function deletePost(id: string): Promise<{ error: Error | null }> {
  const { error } = await supabase.from("posts").delete().eq("id", id);
  return { error: error as Error | null };
}
