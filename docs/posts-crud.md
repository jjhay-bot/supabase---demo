# Posts CRUD: Table Schema & RLS (Supabase)

This document explains how the `posts` table is defined in Supabase, how
Row Level Security (RLS) is configured, and how the TypeScript CRUD helpers
in `src/lib/supabaseClient.ts` are intended to be used.

## 1. Database schema

Create the `posts` table in the Supabase SQL editor:

```sql
create table if not exists posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text,
  author_id uuid references auth.users(id),
  is_private boolean not null default false, -- false = public
  created_at timestamptz not null default now(),
  updated_at timestamptz
);
```

- `is_private = false` → public post
- `is_private = true` → private post (only owner should see it)

## 2. Row Level Security (RLS)

Enable RLS and add policies so we support these view cases:

1. Authenticated user seeing their own posts (private + public)
2. Authenticated user browsing public posts from anyone
3. Unauthenticated user browsing public posts

Run this in the Supabase SQL editor:

```sql
alter table posts enable row level security;

-- 1) Public posts: visible to everyone (auth + anon)
create policy "select public posts" on posts
  for select
  to public
  using (is_private = false);

-- 2) Own posts: visible to the owner (even if private)
create policy "select own posts" on posts
  for select
  to authenticated
  using (auth.uid() = author_id);

-- 3) Insert: authenticated users can create posts they own
create policy "insert posts for auth users" on posts
  for insert
  to authenticated
  with check (auth.uid() = author_id);

-- 4) Update: only owner can update
create policy "update own posts" on posts
  for update
  to authenticated
  using (auth.uid() = author_id);

-- 5) Delete: only owner can delete
create policy "delete own posts" on posts
  for delete
  to authenticated
  using (auth.uid() = author_id);
```

With these policies:

- Public posts are visible to everyone (even when not logged in).
- A user always sees their own posts, including private ones.
- Only the owner can insert/update/delete their own posts.

## 3. TypeScript type and helpers

All helpers live in `src/lib/supabaseClient.ts`.

### `Post` type

```ts
export type Post = {
  id: string; // uuid
  title: string;
  content: string | null;
  created_at: string; // ISO timestamp
  updated_at: string | null;
  author_id: string | null; // user id
  is_private: boolean; // true = private, false = public
};
```

### 3.1 Create: `createPost`

```ts
export async function createPost(input: {
  title: string;
  content?: string;
  isPrivate?: boolean;
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
```

Usage example:

```ts
const { data, error } = await createPost({
  title: "Hello world",
  content: "My first post",
  isPrivate: true, // omit or false for public
});
```

### 3.2 List: `listPosts`

```ts
export async function listPosts(options?: {
  authorId?: string;
  onlyPrivate?: boolean;
  onlyPublic?: boolean;
}): Promise<{ data: Post[] | null; error: Error | null }> {
  let query = supabase
    .from("posts")
    .select("*")
    .order("created_at", { ascending: false });

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
```

Examples:

```ts
// Public feed (auth or anon)
const { data: publicPosts } = await listPosts({ onlyPublic: true });

// My posts (requires you to pass the current user's id)
const { data: myPosts } = await listPosts({ authorId: user.id });

// My private posts only
const { data: myPrivatePosts } = await listPosts({
  authorId: user.id,
  onlyPrivate: true,
});
```

### 3.3 Read single: `getPostById`

```ts
export async function getPostById(id: string): Promise<{
  data: Post | null;
  error: Error | null;
}> {
  const { data, error } = await supabase
    .from("posts")
    .select("*")
    .eq("id", id)
    .single();

  return { data: data as Post | null, error: error as Error | null };
}
```

The RLS policies decide whether the caller is allowed to see that row.

### 3.4 Update: `updatePost`

```ts
export async function updatePost(
  id: string,
  input: {
    title?: string;
    content?: string | null;
    isPrivate?: boolean;
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
```

Example:

```ts
const { data: updated, error } = await updatePost(postId, {
  title: "Updated title",
  isPrivate: false,
});
```

### 3.5 Delete: `deletePost`

```ts
export async function deletePost(id: string): Promise<{ error: Error | null }> {
  const { error } = await supabase.from("posts").delete().eq("id", id);
  return { error: error as Error | null };
}
```

## 4. Error handling pattern

All helpers follow the same pattern and never throw directly:

```ts
const { data, error } = await createPost({ title, content });

if (error) {
  // show toast / error message
  return;
}

// use `data`
```


This keeps UI code simple and consistent.

## 5. Evolving the posts table (adding columns)

When you need to add new fields to `posts` (for example `like_count` or
`location`), follow this pattern.

### 5.1 Update the table schema

Run an `alter table` in the Supabase SQL editor:

```sql
alter table posts
  add column if not exists like_count integer not null default 0,
  add column if not exists location text;
```

- `like_count` starts at `0`.
- `location` is optional.

### 5.2 Update the TypeScript `Post` type

Extend the `Post` type in `src/lib/supabaseClient.ts`:

```ts
export type Post = {
  // ...existing fields...
  is_private: boolean;
  like_count: number;      // NEW
  location: string | null; // NEW
};
```

### 5.3 Update CRUD helpers (if needed)

Decide which fields are controlled by the author vs by other users.

Example: allow author to set `location` and initial visibility, and keep
`like_count` defaulted by the DB:

```ts
export async function createPost(input: {
  title: string;
  content?: string;
  isPrivate?: boolean;
  location?: string;
}) {
  const { data, error } = await supabase
    .from("posts")
    .insert({
      title: input.title,
      content: input.content ?? null,
      is_private: input.isPrivate ?? false,
      location: input.location ?? null,
      // like_count uses DB default = 0
    })
    .select()
    .single();

  return { data: data as Post | null, error: error as Error | null };
}
```

For updates:

```ts
export async function updatePost(
  id: string,
  input: {
    title?: string;
    content?: string | null;
    isPrivate?: boolean;
    location?: string | null;
    likeCount?: number; // only if authors can set this directly
  }
) {
  const payload: Record<string, unknown> = {};

  if (input.title !== undefined) payload.title = input.title;
  if (input.content !== undefined) payload.content = input.content;
  if (input.isPrivate !== undefined) payload.is_private = input.isPrivate;
  if (input.location !== undefined) payload.location = input.location;
  if (input.likeCount !== undefined) payload.like_count = input.likeCount;

  const { data, error } = await supabase
    .from("posts")
    .update(payload)
    .eq("id", id)
    .select()
    .single();

  return { data: data as Post | null, error: error as Error | null };
}
```

For things like "likes" you may prefer a separate API/route that increments
`like_count` instead of letting clients set any value.

### 5.4 RLS changes (usually minimal)

Most of the time you do **not** need to change RLS when adding simple fields
like `like_count` or `location`:

- Existing policies such as `using (auth.uid() = author_id)` still work.
- Visibility based on `is_private` also still works.

You only need to change RLS if the new fields change who is allowed to read
or write rows. Example: if you decide that **any user** can increment
`like_count` on public posts, you would:

- Add a dedicated `update` policy that allows updating `like_count` for
  `is_private = false` rows, while keeping the owner-only policy for other
  fields.

In general, the workflow is:

1. Plan the new columns and who can read/write them.
2. `alter table` in SQL.
3. Update the `Post` type.
4. Update CRUD helpers where needed.
5. Adjust RLS **only** if access rules change.
