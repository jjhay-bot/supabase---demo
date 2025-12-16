# Supabase Auth & CRUD Helpers

Centralized helpers for signing users in and out via Supabase and for basic
CRUD on the `posts` table.

## Location

- Client + shared helpers: `src/lib/supabaseClient.ts`

## Auth exports

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

## Posts CRUD helpers

For the `posts` table schema, RLS policies, and detailed CRUD helper
examples (`createPost`, `listPosts`, `getPostById`, `updatePost`,
`deletePost`), see:

- `docs/posts-crud.md`

This keeps auth-focused docs here and full CRUD + table/RLS docs in a
single dedicated place.

## Design & security considerations for CRUD

When adding more CRUD helpers, keep these points in mind:

### 1. Row Level Security (RLS)

- Turn on RLS for your tables in Supabase.
- Write policies that enforce ownership, for example:

```sql
-- Only allow authenticated users to insert
create policy "insert posts for auth users" on posts
  for insert
  to authenticated
  with check (auth.uid() = author_id);

-- Only allow owners to select/update/delete their own posts
create policy "select own posts" on posts
  for select
  to authenticated
  using (auth.uid() = author_id);

create policy "update own posts" on posts
  for update
  to authenticated
  using (auth.uid() = author_id);

create policy "delete own posts" on posts
  for delete
  to authenticated
  using (auth.uid() = author_id);
```

This way, even if the client calls the helpers directly, the database enforces
who can see or change what.

### 2. Where to call CRUD from

- **Client-side (React components):** fine for simple apps or prototypes.
  - Call the helpers directly from event handlers.
  - Make sure RLS is enabled, since the client has direct DB access.
- **Server-side (Route Handlers / API routes):** better for complex logic.
  - Wrap Supabase calls in `/app/api/.../route.ts` handlers.
  - Validate input and enforce business rules on the server.

### 3. Error handling pattern

Standard pattern when using these helpers:

```ts
const { data, error } = await createPost({ title, content });

if (error) {
  // show toast / error message
  return;
}

// use `data`
```

Avoid throwing inside helpers; instead, return `{ data, error }` so the UI can
decide how to react.

### 4. Evolving your CRUD

As the app grows, consider:

- Moving per-domain helpers into their own files (e.g. `src/lib/posts.ts`).
- Adding pagination parameters to `list*` functions.
- Using generated types from Supabase (via `supabase-js` type generation) to
  avoid hand-written table types.

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
`src/lib/supabaseClient.ts`. When you start adding more tables, follow the
same pattern used for `posts`: define a type, add `create*`, `list*`,
`get*ById`, `update*`, `delete*` helpers, and secure everything with RLS
policies in Supabase.
