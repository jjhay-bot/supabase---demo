import { createClient } from '@supabase/supabase-js';

// Centralized Supabase client and auth helpers
// - `supabase`: base client for any query / RPC
// - `signInWithOtp`: email magic-link / OTP sign-in
// - `signOut`: sign current user out
//
// NOTE: On the server (Route Handlers / Server Components) prefer using
// `@supabase/auth-helpers-nextjs` with `createRouteHandlerClient` or
// `createServerComponentClient` so auth cookies are respected.

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Missing Supabase environment variables. Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY');
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
