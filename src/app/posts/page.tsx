import Link from "next/link";
import { supabase } from "@/lib/supabaseClient";

const PAGE_SIZE = 10;

export default async function PublicPostsPage({
  searchParams,
}: {
  searchParams?: { page?: string };
}) {
  const page = Math.max(1, Number(searchParams?.page) || 1);
  const from = (page - 1) * PAGE_SIZE;
  const to = from + PAGE_SIZE - 1;

  // Fetch posts for the current page and get filtered count in one query
  const { data: posts, error, count } = await supabase
    .from("posts")
    .select("*", { count: "exact" })
    .eq("type", 1)
    .order("created_at", { ascending: false })
    .range(from, to);

  const total = count || 0;
  const totalPages = Math.ceil(total / PAGE_SIZE);

  console.log(posts, error, count);


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
        <h1 className="mb-4 text-2xl font-bold">Public Posts</h1>

        {error && (
          <p className="text-sm text-red-500">
            Failed to load posts: {error.message}
          </p>
        )}

        {!error && posts.length === 0 && (
          <p className="text-sm text-gray-500">No public posts yet.</p>
        )}

        {!error && posts.length > 0 && (
          <>
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
            <div className="mt-6 flex items-center gap-2">
              <span className="text-xs text-gray-500">
                Page {page} of {totalPages} ({total} posts)
              </span>
              <nav className="flex gap-1">
                <Link
                  href={`/posts?page=${page - 1}`}
                  className={`px-2 py-1 text-xs rounded ${page <= 1
                      ? "pointer-events-none opacity-50"
                      : "hover:bg-gray-100"
                    }`}
                  aria-disabled={page <= 1}
                >
                  Prev
                </Link>
                <Link
                  href={`/posts?page=${page + 1}`}
                  className={`px-2 py-1 text-xs rounded ${page >= totalPages
                      ? "pointer-events-none opacity-50"
                      : "hover:bg-gray-100"
                    }`}
                  aria-disabled={page >= totalPages}
                >
                  Next
                </Link>
              </nav>
            </div>
          </>
        )}
      </section>
    </main>
  );
}
