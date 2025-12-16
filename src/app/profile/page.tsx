"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import {
  supabase,
  type Post,
  listPosts,
  createPost,
  updatePost,
  deletePost,
} from "@/lib/supabaseClient";

export default function ProfilePage() {
  const [loading, setLoading] = useState(true);
  const [session, setSession] = useState<
    Awaited<ReturnType<typeof supabase.auth.getSession>>["data"]["session"] | null
  >(null);

  const [posts, setPosts] = useState<Post[] | null>(null);
  const [postsLoading, setPostsLoading] = useState(false);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingPost, setEditingPost] = useState<Post | null>(null);
  const [formTitle, setFormTitle] = useState("");
  const [formContent, setFormContent] = useState("");
  const [formIsPrivate, setFormIsPrivate] = useState(false);
  const [formSubmitting, setFormSubmitting] = useState(false);

  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const pageSize = 2; // match DEFAULT_PAGE_SIZE

  useEffect(() => {
    let mounted = true;

    async function loadSessionAndPosts() {
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (!mounted) return;
      setSession(session);
      setLoading(false);

      if (session?.user) {
        setPostsLoading(true);
        const { data, error, count } = await listPosts({
          authorId: session.user.id,
          page: currentPage,
          pageSize,
        });
        if (!mounted) return;
        if (!error) setPosts(data);
        setTotalPages(count ? Math.max(1, Math.ceil(count / pageSize)) : 1);
        setPostsLoading(false);
      }
    }

    loadSessionAndPosts();

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, [currentPage]);

  async function refreshPosts(userId: string) {
    setPostsLoading(true);
    const { data, error, count } = await listPosts({ authorId: userId, page: currentPage, pageSize });
    if (!error) setPosts(data);
    setTotalPages(count ? Math.max(1, Math.ceil(count / pageSize)) : 1);
    setPostsLoading(false);
  }

  function openCreateModal() {
    setEditingPost(null);
    setFormTitle("");
    setFormContent("");
    setFormIsPrivate(false);
    setIsModalOpen(true);
  }

  function openEditModal(post: Post) {
    setEditingPost(post);
    setFormTitle(post.title);
    setFormContent(post.content ?? "");
    setFormIsPrivate(post.is_private);
    setIsModalOpen(true);
  }

  async function handleSubmit(userId: string) {
    setFormSubmitting(true);

    if (editingPost) {
      await updatePost(editingPost.id, {
        title: formTitle,
        content: formContent,
        isPrivate: formIsPrivate,
      });
    } else {
      await createPost({
        title: formTitle,
        content: formContent,
        isPrivate: formIsPrivate,
      });
    }

    setFormSubmitting(false);
    setIsModalOpen(false);
    await refreshPosts(userId);
  }

  async function handleDelete(postId: string, userId: string) {
    // Simple confirm for now
    if (!confirm("Delete this post?")) return;
    await deletePost(postId);
    await refreshPosts(userId);
  }

  if (loading) {
    return (
      <main className="flex min-h-screen flex-col items-center justify-center p-4">
        <p className="text-sm text-gray-600">Loading...</p>
      </main>
    );
  }

  if (!session) {
    return (
      <main className="flex min-h-screen flex-col items-center justify-center p-4">
        <p className="mb-4 text-sm text-gray-600">
          You need to sign in to view your profile.
        </p>
        <Link
          href="/"
          className="rounded-md bg-black px-4 py-2 text-sm font-medium text-white"
        >
          Go to sign in
        </Link>
      </main>
    );
  }

  const user = session.user;

  return (
    <main className="flex min-h-screen flex-col">
      <header className="flex items-center justify-between border-b px-4 py-3">
        <Link href="/" className="text-base font-semibold">
          Bucketmatch
        </Link>
        <nav className="flex items-center gap-4 text-sm">
          <Link href="/profile" className="font-medium">
            Profile
          </Link>
        </nav>
      </header>

      <section className="flex flex-1 flex-col items-center justify-center p-4">
        <h1 className="mb-4 text-2xl font-bold">My Profile</h1>
        <div className="mb-8 space-y-2 text-sm text-gray-700">
          <p>
            <span className="font-semibold">User ID:</span> {user.id}
          </p>
          <p>
            <span className="font-semibold">Email:</span> {user.email}
          </p>
        </div>

        <div className="w-full max-w-xl">
          <div className="mb-2 flex items-center justify-between">
            <h2 className="text-lg font-semibold">My Posts</h2>
            <button
              onClick={openCreateModal}
              className="rounded-md bg-black px-3 py-1 text-sm text-white hover:bg-gray-900"
            >
              New Post
            </button>
          </div>

          {postsLoading && (
            <p className="text-sm text-gray-500">Loading posts...</p>
          )}

          {!postsLoading && (!posts || posts.length === 0) && (
            <p className="text-sm text-gray-500">
              You have not created any posts yet.
            </p>
          )}

          {!postsLoading && posts && posts.length > 0 && (
            <>
              <ul className="space-y-2">
                {posts.map((post) => (
                  <li
                    key={post.id}
                    className="flex items-center justify-between rounded-md border px-3 py-2 text-sm"
                  >
                    <div>
                      <p className="font-medium">{post.title}</p>
                      <p className="text-xs text-gray-500">
                        {post.is_private ? "Private" : "Public"}
                      </p>
                    </div>
                    <div className="flex items-center gap-2 text-xs">
                      <button
                        onClick={() => openEditModal(post)}
                        className="rounded border px-2 py-1 hover:bg-gray-50"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleDelete(post.id, user.id)}
                        className="rounded border border-red-500 px-2 py-1 text-red-600 hover:bg-red-50"
                      >
                        Delete
                      </button>
                    </div>
                  </li>
                ))}
              </ul>
              <div className="flex justify-center mt-4 gap-2">
                <button
                  onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                  disabled={currentPage === 1}
                  className="rounded border px-3 py-1 text-sm disabled:opacity-50"
                >
                  Previous
                </button>
                <span className="px-2 py-1 text-sm">
                  Page {currentPage} of {totalPages}
                </span>
                <button
                  onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                  disabled={currentPage === totalPages}
                  className="rounded border px-3 py-1 text-sm disabled:opacity-50"
                >
                  Next
                </button>
              </div>
            </>
          )}
        </div>

        {isModalOpen && (
          <div className="fixed inset-0 z-10 flex items-center justify-center bg-black/40">
            <div className="w-full max-w-md rounded-lg bg-white p-4 shadow-lg">
              <h2 className="mb-3 text-lg font-semibold">
                {editingPost ? "Edit Post" : "New Post"}
              </h2>
              <div className="space-y-3 text-sm">
                <div>
                  <label className="mb-1 block font-medium">Title</label>
                  <input
                    value={formTitle}
                    onChange={(e) => setFormTitle(e.target.value)}
                    className="w-full rounded border px-2 py-1"
                    placeholder="Post title"
                  />
                </div>
                <div>
                  <label className="mb-1 block font-medium">Content</label>
                  <textarea
                    value={formContent}
                    onChange={(e) => setFormContent(e.target.value)}
                    className="h-24 w-full rounded border px-2 py-1"
                    placeholder="Write something..."
                  />
                </div>
                <label className="flex items-center gap-2 text-xs font-medium">
                  <input
                    type="checkbox"
                    checked={formIsPrivate}
                    onChange={(e) => setFormIsPrivate(e.target.checked)}
                  />
                  Private (only you can see)
                </label>
              </div>

              <div className="mt-4 flex justify-end gap-2 text-sm">
                <button
                  onClick={() => setIsModalOpen(false)}
                  className="rounded border px-3 py-1 hover:bg-gray-50"
                  disabled={formSubmitting}
                >
                  Cancel
                </button>
                <button
                  onClick={() => handleSubmit(user.id)}
                  className="rounded bg-black px-3 py-1 text-white hover:bg-gray-900 disabled:opacity-60"
                  disabled={formSubmitting || !formTitle.trim()}
                >
                  {formSubmitting
                    ? "Saving..."
                    : editingPost
                      ? "Save changes"
                      : "Create"}
                </button>
              </div>
            </div>
          </div>
        )}
      </section>
    </main>
  );
}
