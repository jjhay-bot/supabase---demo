# Supabase Auth Helpers

Centralized helpers for signing users in and out via Supabase.

## Location

- Client + shared helpers: `src/lib/supabaseClient.ts`

## Exports

### `supabase`

Low-level Supabase client configured from environment variables.

```ts
import { supabase } from '@/lib/supabaseClient';

const { data, error } = await supabase.from('profiles').select('*');
```

### `signInWithOtp(email: string)`

Email OTP / magic-link sign-in. Intended for client-side use (e.g. inside React components or handlers that run in the browser).

```ts
import { signInWithOtp } from '@/lib/supabaseClient';

const { data, error } = await signInWithOtp('user@example.com');
```

- Sends an email with a magic link / one-time code.
- Returns the underlying Supabase response `{ data, error }`.

### `signOut()`

Signs out the currently authenticated user (client-side).

```ts
import { signOut } from '@/lib/supabaseClient';

const { error } = await signOut();
```

## Server-side usage (APIs, server components)

For API routes / Route Handlers and Server Components, prefer the official
Supabase Auth Helpers for Next.js so that auth cookies are handled correctly:

- Package: `@supabase/auth-helpers-nextjs`
- Docs: [Supabase Auth Helpers for Next.js](https://supabase.com/docs/guides/auth/auth-helpers/nextjs)

```ts
// Example only – not yet implemented in this repo
import { cookies } from 'next/headers';
import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';

export async function GET() {
  const supabase = createRouteHandlerClient({ cookies });
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // ...
}
```

In this project we keep only the shared client + simple helpers in
`src/lib/supabaseClient.ts`. When you start adding API routes, we can
introduce `@supabase/auth-helpers-nextjs` and extend these docs with
concrete examples.
