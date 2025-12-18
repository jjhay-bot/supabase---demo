import { supabase } from "../lib/supabaseClient";

/**
 * Fetch a post by its ID from the Supabase database.
 * @param postId The ID of the post to fetch.
 * @returns The post object if found, otherwise null.
 */
export async function getPost(postId: string) {
  const { data, error } = await supabase.from("posts").select("*").eq("id", postId).single();

  if (error) {
    console.error("Error fetching post:", error);
    return null;
  }
  return data;
}

/**
 * Fetch a paginated list of posts from the Supabase database.
 * @param page The page number (1-based).
 * @returns An array of post objects for the requested page.
 */
export async function getPosts(page: number) {
  const pageSize = 10;
  const from = (page - 1) * pageSize;
  const to = from + pageSize - 1;

  // const { data, error } = await supabase
  //   .from('posts')
  //   .select('*')
  //   .order('created_at', { ascending: false })
  //   .range(from, to);
  const { data, error } = await supabase
    .from("posts")
    .select("*")
    // .order("created_at", { ascending: false })
    .range(from, to);

  if (error) {
    console.error("Error fetching paginated posts:", error);
    return [];
  }
  console.log("data", data);

  return data || [];
}

/**
 * Fetch a paginated list of posts from the Supabase database, FE-ready with pagination metadata.
 * @param page The page number (1-based).
 * @returns An object with posts data, page, pageSize, and total count.
 */
export async function listPosts(page: number = 1) {
  const pageSize = 10;
  const safePage = Math.max(1, page);
  const from = (safePage - 1) * pageSize;
  const to = from + pageSize - 1;

  // Fetch posts for the current page (no count)
  const { data, error } = await supabase
    .from("posts")
    .select("*")
    .order("created_at", { ascending: false })
    .range(from, to);

  // Fetch total count separately
  const { count, error: countError } = await supabase
    .from("posts")
    .select("*", { count: "exact", head: true });

  if (error || countError) {
    console.error("Error fetching paginated posts:", error || countError);
    return { data: [], page: safePage, pageSize, total: 0 };
  }

  return {
    data: data || [],
    page: safePage,
    pageSize,
    total: count || 0,
  };
}
