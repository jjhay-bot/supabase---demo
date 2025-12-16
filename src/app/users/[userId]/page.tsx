import { listPosts, type Post } from "@/lib/supabaseClient";
import Link from "next/link";

interface UserPostsPageProps {
  params: { userId: string };
}

export default async function UserPostsPage({ params }: UserPostsPageProps) {
  const userId = params.userId;
  const { data, error } = await listPosts({ authorId: userId, onlyPublic: true });
  const posts = (data ?? []) as Post[];

  return (
    <main className="flex min-h-screen flex-col">
      <header className="flex items-center justify-between border-b px-4 py-3">
        <Link href="/" className="text-base font-semibold">
          Bucketmatch
        </Link>
        <nav className="flex items-center gap-4 text-sm">
          <Link href="/posts" className="font-medium">
            Public Posts
          </Link>
          <Link href="/profile" className="text-gray-600 hover:text-gray-900">
            Profile
          </Link>
        </nav>
      </header>

      <section className="flex flex-1 flex-col items-center p-4">
        <h1 className="mb-4 text-2xl font-bold">User's Public Posts</h1>
        <p className="mb-2 text-sm text-gray-700">User ID: <span className="font-mono">{userId}</span></p>

        {error && (
          <p className="text-sm text-red-500">
            Failed to load posts: {error.message}
          </p>
        )}

        {!error && posts.length === 0 && (
          <p className="text-sm text-gray-500">No public posts for this user.</p>
        )}

        {!error && posts.length > 0 && (
          <ul className="mt-2 w-full max-w-xl space-y-2">
            {posts.map((post) => (
              <li
                key={post.id}
                className="rounded-md border px-3 py-2 text-sm"
              >
                <p className="font-medium">{post.title}</p>
                {post.content && (
                  <p className="mt-1 text-xs text-gray-600 line-clamp-2">
                    {post.content}
                  </p>
                )}
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}
