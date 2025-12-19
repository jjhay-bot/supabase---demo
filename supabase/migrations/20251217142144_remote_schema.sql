


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";








ALTER SCHEMA "public" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "unaccent" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";





SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."collaborators" (
    "id" bigint NOT NULL,
    "uid" "text",
    "related_user_id" bigint,
    "related_bucket_id" bigint,
    "approved_by_creator" boolean DEFAULT false,
    "approved_by_collaborator" boolean DEFAULT false,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "related_user_email" "text",
    "related_bucket_uid" "text"
);


ALTER TABLE "public"."collaborators" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_collaborators_to_bucket"("p_bucket_id" bigint, "p_user_ids" bigint[]) RETURNS SETOF "public"."collaborators"
    LANGUAGE "sql"
    AS $$
    INSERT INTO collaborators (
        related_user_id,
        related_bucket_id,
        approved_by_creator,
        approved_by_collaborator,
        created_at,
        updated_at
    )
    SELECT
        unnest(p_user_ids) AS related_user_id,
        p_bucket_id,
        TRUE,              -- approved_by_creator
        FALSE,             -- approved_by_collaborator
        NOW(),
        NOW()
    ON CONFLICT (related_user_id, related_bucket_id)
    DO NOTHING
    RETURNING *;
$$;


ALTER FUNCTION "public"."add_collaborators_to_bucket"("p_bucket_id" bigint, "p_user_ids" bigint[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_collaborators_to_bucket"("p_bucket_id" bigint, "p_user_ids" bigint[], "p_sender_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_user_id BIGINT;
    v_collab_id BIGINT;
BEGIN
    FOREACH v_user_id IN ARRAY p_user_ids LOOP
        
        -- Insert collaborator (skip duplicates)
        INSERT INTO collaborators (
            related_user_id,
            related_bucket_id,
            approved_by_creator,
            approved_by_collaborator,
            created_at,
            updated_at
        )
        VALUES (
            v_user_id,
            p_bucket_id,
            TRUE,
            FALSE,
            NOW(),
            NOW()
        )
        ON CONFLICT (related_user_id, related_bucket_id)
        DO NOTHING
        RETURNING id INTO v_collab_id;

        -- Only create a notification if collaborator insert actually happened
        IF v_collab_id IS NOT NULL THEN
            INSERT INTO notifications (
                recipient_id,
                sender_id,
                type,
                content,
                referenced_bucket_id,
                created_at,
                updated_at
            )
            VALUES (
                v_user_id,
                p_sender_id,
                12,
                '',
                p_bucket_id,
                NOW(),
                NOW()
            );
        END IF;

    END LOOP;
END;
$$;


ALTER FUNCTION "public"."add_collaborators_to_bucket"("p_bucket_id" bigint, "p_user_ids" bigint[], "p_sender_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_or_create_conversation"("p_user1" bigint, "p_user2" bigint) RETURNS bigint
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    existing_conversation_id bigint;
BEGIN
    -- 1. Check if a conversation exists with both users where draft = false
    SELECT cu.conversation_id INTO existing_conversation_id
    FROM conversations_users cu
    JOIN conversations c ON cu.conversation_id = c.id
    WHERE cu.user_id IN (p_user1, p_user2)
      AND c.draft = false
    GROUP BY cu.conversation_id
    HAVING COUNT(*) = 2
    LIMIT 1;

    -- 2. If a conversation with draft = false exists, return it
    IF existing_conversation_id IS NOT NULL THEN
        RETURN existing_conversation_id;

    -- 3. If a conversation with draft = true exists, delete it and its related entries
    ELSE
        -- Delete the old conversation with draft = true and its related entries
        DELETE FROM messages
        WHERE related_conversation_id IN (
            SELECT cu.conversation_id
            FROM conversations_users cu
            JOIN conversations c ON cu.conversation_id = c.id
            WHERE cu.user_id IN (p_user1, p_user2)
              AND c.draft = true
            GROUP BY cu.conversation_id
            HAVING COUNT(*) = 2
            LIMIT 1
        );

        DELETE FROM conversations_users
        WHERE conversation_id IN (
            SELECT cu.conversation_id
            FROM conversations_users cu
            JOIN conversations c ON cu.conversation_id = c.id
            WHERE cu.user_id IN (p_user1, p_user2)
              AND c.draft = true
            GROUP BY cu.conversation_id
            HAVING COUNT(*) = 2
            LIMIT 1
        );

        DELETE FROM conversations
        WHERE draft = true
          AND id IN (
              SELECT cu.conversation_id
              FROM conversations_users cu
              WHERE cu.user_id IN (p_user1, p_user2)
              GROUP BY cu.conversation_id
              HAVING COUNT(*) = 2
              LIMIT 1
          );
    END IF;

    -- 4. Create a new conversation with draft = true and return it
    INSERT INTO conversations (last_updated, created_by, draft)
    VALUES (NOW(), p_user1, true)
    RETURNING id INTO existing_conversation_id;

    -- 5. Link both users to the new conversation
    INSERT INTO conversations_users (conversation_id, user_id)
    VALUES 
        (existing_conversation_id, p_user1),
        (existing_conversation_id, p_user2);

    -- Return the newly created conversation ID
    RETURN existing_conversation_id;
END;
$$;


ALTER FUNCTION "public"."check_or_create_conversation"("p_user1" bigint, "p_user2" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."clone_and_add_bucket"("p_original_bucket_id" bigint, "p_current_user_id" bigint, "p_mark_completed" boolean) RETURNS bigint
    LANGUAGE "plpgsql"
    AS $$DECLARE
    v_new_bucket_id bigint;
    v_title text;
    v_description text;
    v_display_picture_url text;
    v_user_full_name text;
BEGIN
    -- Get original bucket info
    SELECT title, description, display_picture_url
    INTO v_title, v_description, v_display_picture_url
    FROM buckets
    WHERE id = p_original_bucket_id;

    -- Get user full name
    SELECT full_name INTO v_user_full_name
    FROM users
    WHERE id = p_current_user_id;

    -- 1) Clone bucket
    INSERT INTO buckets (
        title, description, display_picture_url,
        created_by, related_user_id,
        is_completed, created_at, updated_at
    )
    VALUES (
        v_title, v_description, v_display_picture_url,
        p_current_user_id, p_current_user_id,
        p_mark_completed, NOW(), NOW()
    )
    RETURNING id INTO v_new_bucket_id;

    -- 2) Clone categories
    INSERT INTO buckets_categories (bucket_id, category, category_name)
    SELECT v_new_bucket_id, category, category_name
    FROM buckets_categories
    WHERE bucket_id = p_original_bucket_id;

    -- 3) Clone tags
    INSERT INTO buckets_tags (bucket_id, tag)
    SELECT v_new_bucket_id, tag
    FROM buckets_tags
    WHERE bucket_id = p_original_bucket_id;

    -- 4) Insert into users_buckets
    INSERT INTO users_buckets (bucket_id, user_id)
    VALUES (v_new_bucket_id, p_current_user_id);

    -- 5) Create post ONLY if completed
    IF p_mark_completed THEN
        INSERT INTO posts (
        related_user_id,
        related_bucket_id,
        type,
        title,
        name,
        created_by,
        created_at,
        updated_at
    )
    VALUES (
        p_current_user_id,
        v_new_bucket_id,
        4,
        v_title,
        v_user_full_name,
        p_current_user_id,
        NOW(),
        NOW()
    );
    END IF;

    RETURN v_new_bucket_id;
END;$$;


ALTER FUNCTION "public"."clone_and_add_bucket"("p_original_bucket_id" bigint, "p_current_user_id" bigint, "p_mark_completed" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."exec_sql"("sql" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  EXECUTE sql;
END;
$$;


ALTER FUNCTION "public"."exec_sql"("sql" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_slug_from_email"("p_email" "text") RETURNS "text"
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
  v_local text;
BEGIN
  IF p_email IS NULL THEN
    RETURN NULL;
  END IF;

  v_local := lower(trim(split_part(p_email, '@', 1)));
  v_local := regexp_replace(v_local, '[^a-z0-9]+', '-', 'g');
  v_local := regexp_replace(v_local, '-{2,}', '-', 'g');
  v_local := regexp_replace(v_local, '(^-+|-+$)', '', 'g');

  IF v_local = '' THEN
    v_local := 'user';
  END IF;

  RETURN v_local;
END;
$_$;


ALTER FUNCTION "public"."generate_slug_from_email"("p_email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_user_slug"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $_$
DECLARE
  base text;
  candidate text;
  suffix int := 0;
BEGIN
  IF NEW.slug IS NOT NULL AND trim(NEW.slug) <> '' THEN
    RETURN NEW;
  END IF;

  -- Prefer full_name if present, else use email local part, else 'user'
  IF NEW.full_name IS NOT NULL AND trim(NEW.full_name) <> '' THEN
    base := lower(NEW.full_name);
  ELSIF NEW.email IS NOT NULL THEN
    base := split_part(lower(NEW.email), '@', 1);
  ELSE
    base := 'user';
  END IF;

  -- normalize: keep a-z0-9 and replace others with '-'
  base := regexp_replace(base, '[^a-z0-9]+', '-', 'g');
  base := regexp_replace(base, '(^-+|-+$)', '', 'g');
  IF base = '' THEN
    base := 'user';
  END IF;

  candidate := base;
  WHILE EXISTS (SELECT 1 FROM public.users WHERE slug = candidate) LOOP
    suffix := suffix + 1;
    candidate := base || '-' || suffix::text;
  END LOOP;

  NEW.slug := candidate;
  RETURN NEW;
END;
$_$;


ALTER FUNCTION "public"."generate_user_slug"() OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" bigint NOT NULL,
    "uid" "text",
    "city" "text",
    "profile_picture_url" "text",
    "bio" "text",
    "state_us_only" "text",
    "country" "text",
    "tiktok" "text",
    "linkedin" "text",
    "full_name" "text",
    "instagram" "text",
    "goal_count_trigger" integer DEFAULT 0,
    "welcome_email_sent" boolean DEFAULT false,
    "first_goal_added" boolean DEFAULT false,
    "is_confirmed" boolean DEFAULT false,
    "is_onboarded" boolean DEFAULT false,
    "onboarding_step" integer DEFAULT 0,
    "welcome_message_sent" boolean DEFAULT false,
    "email" "text",
    "slug" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "auth_user_id" "uuid",
    "last_personalized_bucket_flow_at" timestamp with time zone
);


ALTER TABLE "public"."users" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_bucket_approved_collaborator_users"("p_bucket_id" bigint) RETURNS SETOF "public"."users"
    LANGUAGE "sql" STABLE
    AS $$
    SELECT u.*
    FROM users u
    WHERE u.id IN (
        SELECT related_user_id
        FROM collaborators
        WHERE related_bucket_id = p_bucket_id
          AND approved_by_creator IS TRUE
          AND approved_by_collaborator IS TRUE
    );
$$;


ALTER FUNCTION "public"."get_bucket_approved_collaborator_users"("p_bucket_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_bucket_collaborator_users"("p_bucket_id" bigint) RETURNS SETOF "public"."users"
    LANGUAGE "sql" STABLE
    AS $$
    SELECT u.*
    FROM users u
    WHERE u.id IN (
        SELECT related_user_id
        FROM collaborators
        WHERE related_bucket_id = p_bucket_id
    );
$$;


ALTER FUNCTION "public"."get_bucket_collaborator_users"("p_bucket_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_bucket_partner_experts"("p_bucket_id" bigint) RETURNS SETOF json
    LANGUAGE "sql" STABLE
    AS $$
SELECT
  jsonb_set(
    to_jsonb(pe),
    '{pictures}',
    COALESCE(
      (
        SELECT json_agg(pic.picture_url)
        FROM public.partner_experts_pictures pic
        WHERE pic.partner_expert_id = pe.id
      )::jsonb,
      '[]'::jsonb
    )
  ) AS result
FROM public.partner_experts pe
JOIN public.buckets_partner_experts bpe
  ON bpe.partner_expert_id = pe.id
WHERE bpe.bucket_id = p_bucket_id;
$$;


ALTER FUNCTION "public"."get_bucket_partner_experts"("p_bucket_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_buckets_sorted_for_user"("p_user_id" bigint) RETURNS TABLE("id" bigint, "uid" "text", "title" "text", "description" "text", "completion_date" "text", "is_completed" boolean, "is_private" boolean, "related_user_id" bigint, "related_user_email" "text", "user_name" "text", "added_count" integer, "like_count" integer, "comment_count" integer, "storyboard" boolean, "display_picture_url" "text", "location" "text", "custom_explore" boolean, "services_added" boolean, "experts_added" boolean, "completion_range" "text", "creator" "text", "created_by" bigint, "created_at" timestamp without time zone, "updated_at" timestamp without time zone, "category" integer, "sort_factor" integer)
    LANGUAGE "sql" STABLE
    AS $$
    SELECT 
        b.id,
        b.uid,
        b.title,
        b.description,
        b.completion_date,
        b.is_completed,
        b.is_private,
        b.related_user_id,
        b.related_user_email,
        b.user_name,
        b.added_count,
        b.like_count,
        b.comment_count,
        b.storyboard,
        b.display_picture_url,
        b.location,
        b.custom_explore,
        b.services_added,
        b.experts_added,
        b.completion_range,
        b.creator,
        b.created_by,
        b.created_at,
        b.updated_at,
        b.category,
        ub.sort_factor
    FROM users_buckets ub
    JOIN buckets b ON b.id = ub.bucket_id
    WHERE ub.user_id = p_user_id
    ORDER BY ub.sort_factor ASC NULLS FIRST;
$$;


ALTER FUNCTION "public"."get_buckets_sorted_for_user"("p_user_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_collaborators_by_bucket"("p_bucket_id" bigint) RETURNS TABLE("collaborator_id" bigint, "related_user_id" bigint, "full_name" "text", "profile_picture_url" "text", "slug" "text", "approved_by_creator" boolean, "approved_by_collaborator" boolean, "created_at" timestamp with time zone)
    LANGUAGE "sql"
    AS $$
    SELECT 
        c.id AS collaborator_id,
        c.related_user_id,
        u.full_name,
        u.profile_picture_url,
        u.slug,
        c.approved_by_creator,
        c.approved_by_collaborator,
        c.created_at
    FROM public.collaborators c
    JOIN public.users u ON u.id = c.related_user_id
    WHERE c.related_bucket_id = p_bucket_id;
$$;


ALTER FUNCTION "public"."get_collaborators_by_bucket"("p_bucket_id" bigint) OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."buckets" (
    "id" bigint NOT NULL,
    "uid" "text",
    "title" "text",
    "description" "text",
    "completion_date" "date",
    "is_completed" boolean DEFAULT false,
    "is_private" boolean DEFAULT false,
    "related_user_id" bigint,
    "user_name" "text",
    "added_count" integer DEFAULT 0,
    "like_count" integer DEFAULT 0,
    "comment_count" integer DEFAULT 0,
    "storyboard" boolean DEFAULT false,
    "display_picture_url" "text",
    "location" "text",
    "custom_explore" boolean DEFAULT false,
    "experts_added" boolean DEFAULT false,
    "services_added" boolean DEFAULT false,
    "personalized_email" boolean DEFAULT false,
    "completion_range" "text",
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "related_user_email" "text",
    "category" bigint,
    "is_system_bucket" boolean DEFAULT false
);


ALTER TABLE "public"."buckets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."posts" (
    "id" bigint NOT NULL,
    "uid" "text",
    "name" "text",
    "title" "text",
    "image_url" "text",
    "context" "text",
    "related_user_id" bigint,
    "related_bucket_id" bigint,
    "type" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "related_user_email" "text",
    "related_bucket_uid" "text",
    "type_text" "text"
);


ALTER TABLE "public"."posts" OWNER TO "postgres";


COMMENT ON COLUMN "public"."posts"."type_text" IS 'Post Type OS';



CREATE OR REPLACE FUNCTION "public"."get_post_by_id"("p_post_id" bigint) RETURNS TABLE("post" "public"."posts", "related_user_row" "public"."users", "related_bucket_row" "public"."buckets", "goals" "text"[])
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    p,
    u,
    b,
    COALESCE(g.goals, '{}') AS goals
  FROM posts p
  LEFT JOIN users u ON u.id = p.related_user_id
  LEFT JOIN buckets b ON b.id = p.related_bucket_id
  LEFT JOIN LATERAL (
    SELECT array_agg(goal_text ORDER BY id) AS goals
    FROM posts_multi_goals 
    WHERE post_id = p.id
  ) g ON TRUE
  WHERE p.id = p_post_id;
END;
$$;


ALTER FUNCTION "public"."get_post_by_id"("p_post_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_posts_feed"("p_current_user_id" bigint, "p_limit" integer DEFAULT 20, "p_before_id" bigint DEFAULT NULL::bigint, "p_related_bucket_id" bigint DEFAULT NULL::bigint) RETURNS TABLE("post" "public"."posts", "related_user_row" "public"."users", "related_bucket_row" "public"."buckets", "goals" "text"[])
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    p,
    u,
    b,
    COALESCE(g.goals, '{}') AS goals
  FROM public.posts p
  LEFT JOIN public.users u
    ON u.id = p.related_user_id
  LEFT JOIN public.buckets b
    ON b.id = p.related_bucket_id
  LEFT JOIN LATERAL (
    SELECT array_agg(pmg.goal_text ORDER BY pmg.id) AS goals
    FROM public.posts_multi_goals pmg
    WHERE pmg.post_id = p.id
  ) g ON TRUE
  WHERE
    -- Skip posts where user no longer exists
    u.id IS NOT NULL

    -- Optional bucket filter
    AND (p_related_bucket_id IS NULL OR p.related_bucket_id = p_related_bucket_id)

    -- Keyset pagination logic (only by ID)
    AND (
      -- If `p_before_id` is provided, fetch posts with IDs smaller than `p_before_id`
      p_before_id IS NULL
      OR p.id < p_before_id
    )

  -- Order by post ID descending (for pagination, we want the latest posts first)
  ORDER BY
    p.id DESC
  
  -- Limit the number of posts to return
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION "public"."get_posts_feed"("p_current_user_id" bigint, "p_limit" integer, "p_before_id" bigint, "p_related_bucket_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_random_users"() RETURNS TABLE("user_id" bigint, "completed_goal_count" integer, "total_goal_count" integer)
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN QUERY
  WITH goal_count AS (
    SELECT
      related_user_id AS user_id,
      COUNT(*)::int AS total_goal_count,
      COUNT(*) FILTER (WHERE is_completed = TRUE)::int AS completed_goal_count
    FROM buckets
    GROUP BY related_user_id
  )
  SELECT
    u.id AS user_id,
    COALESCE(gc.completed_goal_count, 0) AS completed_goal_count,
    COALESCE(gc.total_goal_count, 0)     AS total_goal_count
  FROM users u
  LEFT JOIN goal_count gc ON gc.user_id = u.id
  ORDER BY random()
  LIMIT 10;
END;
$$;


ALTER FUNCTION "public"."get_random_users"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_random_users"("p_current_user_id" bigint) RETURNS TABLE("user_id" bigint, "completed_goal_count" integer, "total_goal_count" integer)
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN QUERY
  WITH

  -- Users the current viewer already follows
  my_follows AS (
    SELECT following_id
    FROM follows
    WHERE followed_by_id = p_current_user_id
  ),

  -- Goal counts for users
  goal_count AS (
    SELECT
      related_user_id AS user_id,
      COUNT(*)::int AS total_goal_count,
      COUNT(*) FILTER (WHERE is_completed = TRUE)::int AS completed_goal_count
    FROM buckets
    GROUP BY related_user_id
  )

  SELECT
    u.id AS user_id,
    COALESCE(gc.completed_goal_count, 0) AS completed_goal_count,
    COALESCE(gc.total_goal_count, 0)     AS total_goal_count
  FROM users u
  LEFT JOIN goal_count gc ON gc.user_id = u.id
  WHERE 
        u.id IS NOT NULL                         -- don’t return null IDs
    AND u.id <> p_current_user_id                -- don’t return yourself
    AND u.id NOT IN (SELECT following_id FROM my_follows) -- exclude followed users
  ORDER BY random()
  LIMIT 10;

END;
$$;


ALTER FUNCTION "public"."get_random_users"("p_current_user_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_recommended_users"("p_current_user_id" bigint) RETURNS TABLE("recommended_user_row" "jsonb", "mutual_names" "text"[], "mutual_count" integer, "completed_goal_count" integer, "total_goal_count" integer)
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN QUERY
  WITH

  -- Step 1: All users I follow
  my_follows AS (
    SELECT following_id
    FROM follows
    WHERE followed_by_id = p_current_user_id
  ),

  -- Step 2: Users followed by people I follow
  second_degree AS (
    SELECT 
      f.following_id AS suggested_user_id,
      u.full_name AS mutual_friend_name
    FROM follows f
    JOIN users u 
      ON u.id = f.followed_by_id
    WHERE f.followed_by_id IN (SELECT following_id FROM my_follows)
  ),

  -- Step 3: Clean (remove myself + users I already follow)
  cleaned AS (
    SELECT 
      sd.suggested_user_id,
      sd.mutual_friend_name
    FROM second_degree sd
    WHERE sd.suggested_user_id <> p_current_user_id
      AND sd.suggested_user_id NOT IN (SELECT following_id FROM my_follows)
  ),

  -- Step 4: Group mutual names
  grouped AS (
    SELECT
      c.suggested_user_id,
      array_agg(c.mutual_friend_name ORDER BY c.mutual_friend_name) AS mutual_names,
      COUNT(*)::int AS mutual_count
    FROM cleaned c
    GROUP BY c.suggested_user_id
  ),

  -- Step 5: Get goal stats per user
  goal_stats AS (
    SELECT 
      related_user_id,
      COUNT(*)::int AS total_goal_count,
      COUNT(*) FILTER (WHERE is_completed = true)::int AS completed_goal_count
    FROM buckets
    GROUP BY related_user_id
  )

  -- Step 6: Final SELECT (JSON user + mutuals + counts)
  SELECT
    to_jsonb(u) AS recommended_user_row,
    g.mutual_names,
    g.mutual_count,
    COALESCE(gs.completed_goal_count, 0) AS completed_goal_count,
    COALESCE(gs.total_goal_count, 0) AS total_goal_count
  FROM grouped g
  JOIN users u ON u.id = g.suggested_user_id
  LEFT JOIN goal_stats gs ON gs.related_user_id = g.suggested_user_id
  ORDER BY g.mutual_count DESC, u.full_name ASC;

END;
$$;


ALTER FUNCTION "public"."get_recommended_users"("p_current_user_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_storyboard_and_links"("p_bucket_id" bigint) RETURNS TABLE("items" "jsonb", "links" "jsonb")
    LANGUAGE "sql" STABLE
    AS $$
SELECT
    (
        SELECT jsonb_agg(sub_sbi)
        FROM (
            SELECT *
            FROM story_board_items
            WHERE related_bucket_id = p_bucket_id
            ORDER BY sort_factor ASC
        ) AS sub_sbi
    ) AS items,

    (
        SELECT jsonb_agg(sub_l)
        FROM (
            SELECT *
            FROM links
            WHERE related_bucket_id = p_bucket_id
            ORDER BY id ASC
        ) AS sub_l
    ) AS links;
$$;


ALTER FUNCTION "public"."get_storyboard_and_links"("p_bucket_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_conversations"("p_user_id" bigint) RETURNS SETOF json
    LANGUAGE "sql" STABLE
    AS $$
WITH user_convos AS (
  SELECT cu.conversation_id
  FROM public.conversations_users cu
  WHERE cu.user_id = p_user_id
),

other_users AS (
  SELECT 
    cu.conversation_id,
    u.id AS user_id,
    u.slug,
    u.full_name,
    u.profile_picture_url
  FROM public.conversations_users cu
  JOIN public.users u ON u.id = cu.user_id
  WHERE cu.user_id <> p_user_id
),

unread AS (
  SELECT 
    m.related_conversation_id AS conversation_id,
    COUNT(*) AS unread_count
  FROM public.messages m
  WHERE m.read = FALSE
    AND m.receiver_id = p_user_id   -- This filters messages where receiver is current user
  GROUP BY m.related_conversation_id
)

SELECT jsonb_build_object(
  'conversation', to_jsonb(c),            -- full conversation row
  'other_user', jsonb_build_object(       -- the person you're chatting with
    'id', ou.user_id,
    'slug', ou.slug,
    'full_name', ou.full_name,
    'profile_picture_url', ou.profile_picture_url
  ),
  'unread_count', COALESCE(u.unread_count, 0)
)
FROM user_convos uc
JOIN public.conversations c 
  ON c.id = uc.conversation_id
JOIN other_users ou 
  ON ou.conversation_id = uc.conversation_id
LEFT JOIN unread u 
  ON u.conversation_id = uc.conversation_id
WHERE (c.draft = FALSE OR (c.draft = TRUE AND c.created_by = p_user_id))  -- Added condition to check draft and creator
ORDER BY c.last_updated DESC NULLS LAST;
$$;


ALTER FUNCTION "public"."get_user_conversations"("p_user_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_notifications"("p_user_id" bigint, "p_limit" integer DEFAULT 20, "p_offset" integer DEFAULT 0) RETURNS SETOF json
    LANGUAGE "sql" STABLE
    AS $$
SELECT
  jsonb_build_object(
    'notification', to_jsonb(n),
    'sender',       to_jsonb(u_sender),
    'bucket',       to_jsonb(b),
    'post',         to_jsonb(p),
    'type',         to_jsonb(t)     -- ⭐ added here
  ) AS result
FROM public.notifications n
LEFT JOIN public.users u_sender
  ON u_sender.id = n.sender_id
LEFT JOIN public.buckets b
  ON b.id = n.referenced_bucket_id
LEFT JOIN public.posts p
  ON p.id = n.referenced_post_id
LEFT JOIN public.type_of_notifications t   -- ⭐ join type table
  ON t.id = n.type                          -- "type" is FK in notifications
WHERE n.recipient_id = p_user_id
ORDER BY n.created_at DESC
LIMIT p_limit OFFSET p_offset;
$$;


ALTER FUNCTION "public"."get_user_notifications"("p_user_id" bigint, "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_partner_experts"("p_user_id" bigint) RETURNS SETOF json
    LANGUAGE "sql" STABLE
    AS $$
SELECT DISTINCT
  jsonb_set(
    to_jsonb(pe),
    '{pictures}',
    COALESCE(
      (
        SELECT json_agg(pic.picture_url)
        FROM public.partner_experts_pictures pic
        WHERE pic.partner_expert_id = pe.id
      )::jsonb,
      '[]'::jsonb
    )
  ) AS result
FROM public.partner_experts pe
JOIN public.buckets_partner_experts bpe
  ON bpe.partner_expert_id = pe.id
JOIN public.buckets b
  ON b.id = bpe.bucket_id
WHERE b.related_user_id = p_user_id;  -- all buckets owned by the user
$$;


ALTER FUNCTION "public"."get_user_partner_experts"("p_user_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_signup_merged"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  auth_id uuid;
  u_email text;
  meta jsonb;
  target_user_id bigint;
  v_bucket_id bigint;
  created_bucket_id bigint;
BEGIN
  IF TG_TABLE_SCHEMA = 'auth' AND TG_TABLE_NAME = 'users' THEN
    auth_id := NEW.id;
    u_email := COALESCE(NEW.email, (NEW.raw_user_meta_data ->> 'email'));
    meta := NEW.raw_user_meta_data;
  ELSIF TG_TABLE_SCHEMA = 'auth' AND TG_TABLE_NAME = 'identities' THEN
    auth_id := NEW.user_id;
    u_email := COALESCE(NEW.email, NEW.identity_data ->> 'email');
    meta := NULL;
  ELSIF TG_TABLE_SCHEMA = 'public' AND TG_TABLE_NAME = 'users' THEN
    target_user_id := NEW.id;
    BEGIN
      INSERT INTO public.buckets (title, related_user_id, is_private, description, display_picture_url, location, completion_date, is_system_bucket, created_at, created_by)
      VALUES ('This is a sample goal that you can delete', target_user_id, true, 'This is where you describe the goal and why it matters to you', 'https://kkgvqywomeoccuzujnpf.supabase.co/storage/v1/object/public/Default%20Goals/Write%20your%20list.svg', 'San Diego, CA, USA', now() + interval '1 day', true, now(), target_user_id)
      RETURNING id INTO created_bucket_id;

      IF created_bucket_id IS NULL THEN
        SELECT id INTO created_bucket_id FROM public.buckets WHERE related_user_id = target_user_id AND is_system_bucket = true ORDER BY created_at DESC LIMIT 1;
      END IF;

      IF created_bucket_id IS NOT NULL THEN
        INSERT INTO public.users_buckets (user_id, bucket_id, sort_factor)
        VALUES (target_user_id, created_bucket_id, 0)
        ON CONFLICT DO NOTHING;
      END IF;

      BEGIN
        UPDATE public.users SET welcome_email_sent = true, updated_at = now() WHERE id = target_user_id;
      EXCEPTION WHEN others THEN
        NULL;
      END;

    EXCEPTION WHEN others THEN
      INSERT INTO public.handle_new_auth_user_debug(new_id_text,new_email,error_message)
        VALUES (COALESCE(target_user_id::text,'null'), COALESCE(NEW.email,'null'), 'public_users_path_error: ' || SQLERRM);
    END;

    RETURN NEW;
  END IF;

  IF u_email IS NOT NULL THEN
    u_email := btrim(u_email);
    IF u_email = '' THEN u_email := NULL; END IF;
  END IF;

  BEGIN
    IF auth_id IS NOT NULL THEN
      SELECT id INTO target_user_id FROM public.users WHERE auth_user_id = auth_id LIMIT 1;

      IF target_user_id IS NULL AND u_email IS NOT NULL THEN
        SELECT id INTO target_user_id FROM public.users WHERE lower(email) = lower(u_email) LIMIT 1;
      END IF;

      IF target_user_id IS NOT NULL THEN
        UPDATE public.users SET auth_user_id = auth_id, updated_at = now() WHERE id = target_user_id AND (auth_user_id IS DISTINCT FROM auth_id);
      ELSE
        INSERT INTO public.users (email, auth_user_id, created_at, updated_at)
        VALUES (u_email, auth_id, now(), now())
        RETURNING id INTO target_user_id;
      END IF;
    ELSIF u_email IS NOT NULL THEN
      SELECT id INTO target_user_id FROM public.users WHERE lower(email) = lower(u_email) LIMIT 1;
      IF target_user_id IS NULL THEN
        INSERT INTO public.users (email, created_at, updated_at) VALUES (u_email, now(), now()) RETURNING id INTO target_user_id;
      END IF;
    END IF;
  EXCEPTION WHEN others THEN
    INSERT INTO public.handle_new_auth_user_debug(new_id_text,new_email,error_message)
      VALUES (COALESCE(auth_id::text,'null'), COALESCE(u_email,'null'), 'sync_user_error: ' || SQLERRM);
  END;

  BEGIN
    IF target_user_id IS NOT NULL THEN
      INSERT INTO public.buckets (created_at, created_by)
      VALUES (now(), target_user_id)
      ON CONFLICT DO NOTHING
      RETURNING id INTO v_bucket_id;

      IF v_bucket_id IS NULL THEN
        SELECT id INTO v_bucket_id FROM public.buckets WHERE created_by = target_user_id ORDER BY created_at DESC LIMIT 1;
      END IF;

      IF v_bucket_id IS NOT NULL THEN
        INSERT INTO public.users_buckets (user_id, bucket_id, sort_factor)
        VALUES (target_user_id, v_bucket_id, 0)
        ON CONFLICT DO NOTHING;
      END IF;
    END IF;
  EXCEPTION WHEN others THEN
    INSERT INTO public.handle_new_auth_user_debug(new_id_text,new_email,error_message)
      VALUES (COALESCE(auth_id::text,'null'), COALESCE(u_email,'null'), 'bucket_create_error: ' || SQLERRM);
  END;

  INSERT INTO public.handle_new_auth_user_debug(new_id_text,new_email,error_message)
    VALUES (COALESCE(auth_id::text,'null'), COALESCE(u_email,'null'), 'merged_trigger_completed');

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_signup_merged"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_signup_onboarding"("p_user_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_founder_id       BIGINT;
  v_conversation_id  BIGINT;
  v_user_full_name   TEXT;
  v_first_name       TEXT;
  v_msg_body         TEXT;
BEGIN
  SELECT id INTO v_founder_id
  FROM public.users
  WHERE email = 'jeremy@bucketmatch.ai'
  LIMIT 1;

  IF v_founder_id IS NULL THEN
    RAISE EXCEPTION 'Founder not found.';
  END IF;

  -- Prevent duplicate welcome messages
  IF EXISTS (
    SELECT 1
    FROM conversations c
    JOIN conversations_users cu1 ON cu1.conversation_id = c.id AND cu1.user_id = p_user_id
    JOIN conversations_users cu2 ON cu2.conversation_id = c.id AND cu2.user_id = v_founder_id
  ) THEN
    RETURN;
  END IF;

  SELECT full_name INTO v_user_full_name
  FROM public.users WHERE id = p_user_id;

  IF v_user_full_name IS NULL OR length(trim(v_user_full_name)) = 0 THEN
    v_user_full_name := 'there';
  END IF;

  v_first_name := split_part(v_user_full_name, ' ', 1);

  INSERT INTO conversations (last_updated, draft, creator, created_by, created_at, updated_at)
  VALUES (NOW(), FALSE, 'system', v_founder_id, NOW(), NOW())
  RETURNING id INTO v_conversation_id;

  INSERT INTO conversations_users (conversation_id, user_id)
  VALUES (v_conversation_id, v_founder_id),
         (v_conversation_id, p_user_id);

  v_msg_body := format(
    'Hey %s, welcome to BucketMatch! 🎉 

I’m Jeremy, the founder. Can’t wait to see what’s on your bucket list! I’ll follow up in a couple days to hear your first impressions.

In the meantime, let me know if you have any questions.

See you around 👋',
    v_user_full_name
  );

  INSERT INTO messages (content, sender_id, receiver_id, related_conversation_id, read, created_by, created_at, updated_at)
  VALUES (v_msg_body, v_founder_id, p_user_id, v_conversation_id, FALSE, v_founder_id, NOW(), NOW());

  UPDATE conversations SET last_updated = NOW(), updated_at = NOW()
  WHERE id = v_conversation_id;

  INSERT INTO scheduled_tasks (user_id, task_type, run_at, payload)
  VALUES (
    p_user_id,
    'signup_second_message',
    NOW() + INTERVAL '2 days',
    jsonb_build_object('conversation_id', v_conversation_id, 'sender_id', v_founder_id)
  );
END;
$$;


ALTER FUNCTION "public"."handle_signup_onboarding"("p_user_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."match_buckets_by_title_simple"("p_bucket_id" bigint, "p_current_user_id" bigint, "p_limit" integer DEFAULT 50, "p_offset" integer DEFAULT 0) RETURNS TABLE("bucket_id" bigint, "bucket_title" "text", "bucket_is_completed" boolean, "creator_user_id" bigint, "creator_name" "text", "creator_slug" "text", "creator_profile_picture_url" "text", "creator_follows_current" boolean, "current_user_follows_creator" boolean)
    LANGUAGE "sql" STABLE
    AS $$
WITH base AS (
  -- Get the title of the reference bucket
  SELECT b.title
  FROM public.buckets b
  WHERE b.id = p_bucket_id
),
creators AS (
  SELECT
    b.id AS bucket_id,
    b.title,
    b.is_completed,
    b.is_private,
    b.related_user_id AS creator_user_id,
    u.full_name AS name,
    u.slug,
    u.profile_picture_url,

    -- creator follows current user
    EXISTS (
      SELECT 1
      FROM public.follows f
      WHERE f.followed_by_id = u.id
        AND f.following_id = p_current_user_id
    ) AS creator_follows_current,

    -- current user follows creator
    EXISTS (
      SELECT 1
      FROM public.follows f
      WHERE f.followed_by_id = p_current_user_id
        AND f.following_id = u.id
    ) AS current_user_follows_creator
  FROM public.buckets b
  JOIN public.users u ON u.id = b.related_user_id
  CROSS JOIN base
  WHERE
    b.id <> p_bucket_id
    AND LOWER(TRIM(b.title)) = LOWER(TRIM(base.title))
)
SELECT
  c.bucket_id,
  c.title AS bucket_title,
  c.is_completed AS bucket_is_completed,
  c.creator_user_id,
  c.name AS creator_name,
  c.slug AS creator_slug,
  c.profile_picture_url AS creator_profile_picture_url,
  c.creator_follows_current,
  c.current_user_follows_creator
FROM creators c
WHERE c.is_private = FALSE
ORDER BY
  c.creator_follows_current DESC,
  c.current_user_follows_creator DESC,
  c.bucket_id DESC
LIMIT p_limit OFFSET p_offset;
$$;


ALTER FUNCTION "public"."match_buckets_by_title_simple"("p_bucket_id" bigint, "p_current_user_id" bigint, "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."match_buckets_for_user"("p_current_user_id" bigint, "p_limit" integer DEFAULT 12, "p_offset" integer DEFAULT 0) RETURNS TABLE("bucket_id" bigint, "bucket_title" "text", "bucket_is_completed" boolean, "creator_user_id" bigint, "creator_name" "text", "creator_slug" "text", "creator_profile_picture_url" "text", "creator_follows_current" boolean, "current_user_follows_creator" boolean)
    LANGUAGE "sql" STABLE
    AS $$
WITH user_buckets AS (
  -- All buckets the current user has (created or added to list)
  SELECT DISTINCT ub.bucket_id
  FROM public.users_buckets ub
  JOIN public.buckets b ON b.id = ub.bucket_id
  WHERE ub.user_id = p_current_user_id
),
selected_tags AS (
  -- All unique tags across ALL of the user's buckets
  SELECT DISTINCT LOWER(TRIM(bt.tag)) AS tag
  FROM public.buckets_tags bt
  JOIN user_buckets ub ON ub.bucket_id = bt.bucket_id
),
candidate_ids AS (
  -- All OTHER buckets (not in user's list) that share those tags
  SELECT bt.bucket_id AS other_id
  FROM public.buckets_tags bt
  JOIN selected_tags s ON LOWER(TRIM(bt.tag)) = s.tag
  WHERE bt.bucket_id NOT IN (SELECT bucket_id FROM user_buckets)
),
ranked AS (
  -- Rank candidates by how many tags they share (across ALL user buckets)
  SELECT c.other_id, COUNT(*)::INT AS shared_tags
  FROM candidate_ids c
  GROUP BY c.other_id
),
creators AS (
  -- Attach creator + follow info (same pattern as your match_buckets_simple)
  SELECT
    b.id AS bucket_id,
    b.title,
    b.is_completed,
    b.is_private,
    b.related_user_id,
    u.id AS creator_user_id,
    u.full_name AS name,
    u.slug,
    u.profile_picture_url,
    -- creator follows current user
    EXISTS (
      SELECT 1
      FROM public.follows f
      WHERE f.followed_by_id = u.id
        AND f.following_id = p_current_user_id
    ) AS creator_follows_current,
    -- current user follows creator
    EXISTS (
      SELECT 1
      FROM public.follows f
      WHERE f.followed_by_id = p_current_user_id
        AND f.following_id = u.id
    ) AS current_user_follows_creator
  FROM public.buckets b
  JOIN public.users u ON u.id = b.related_user_id
)
SELECT
  c.bucket_id,
  c.title AS bucket_title,
  c.is_completed AS bucket_is_completed,
  c.creator_user_id,
  c.name AS creator_name,
  c.slug AS creator_slug,
  c.profile_picture_url AS creator_profile_picture_url,
  c.creator_follows_current,
  c.current_user_follows_creator
FROM ranked r
JOIN creators c ON c.bucket_id = r.other_id
WHERE c.is_private = FALSE  -- don't recommend other people's private buckets
ORDER BY
  c.creator_follows_current DESC,
  c.current_user_follows_creator DESC,
  r.shared_tags DESC,
  c.bucket_id DESC
LIMIT p_limit OFFSET p_offset;
$$;


ALTER FUNCTION "public"."match_buckets_for_user"("p_current_user_id" bigint, "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."match_buckets_simple"("p_bucket_id" bigint, "p_current_user_id" bigint, "p_limit" integer DEFAULT 50, "p_offset" integer DEFAULT 0) RETURNS TABLE("bucket_id" bigint, "bucket_title" "text", "bucket_is_completed" boolean, "creator_user_id" bigint, "creator_name" "text", "creator_slug" "text", "creator_profile_picture_url" "text", "creator_follows_current" boolean, "current_user_follows_creator" boolean)
    LANGUAGE "sql" STABLE
    AS $$
WITH selected_tags AS (
  SELECT DISTINCT LOWER(TRIM(bt.tag)) AS tag
  FROM public.buckets_tags bt
  WHERE bt.bucket_id = p_bucket_id
),
candidate_ids AS (
  SELECT bt.bucket_id AS other_id
  FROM public.buckets_tags bt
  JOIN selected_tags s ON LOWER(TRIM(bt.tag)) = s.tag
  WHERE bt.bucket_id <> p_bucket_id
),
ranked AS (
  SELECT c.other_id, COUNT(*)::INT AS shared_tags
  FROM candidate_ids c
  GROUP BY c.other_id
),
creators AS (
  SELECT
    b.id AS bucket_id,
    b.title,
    b.is_completed,
    b.is_private,
    b.related_user_id AS creator_user_id,
    u.full_name AS name,
    u.slug,
    u.profile_picture_url,
    -- creator follows current user
    EXISTS (
      SELECT 1
      FROM public.follows f
      WHERE f.followed_by_id = u.id
        AND f.following_id = p_current_user_id
    ) AS creator_follows_current,
    -- current user follows creator
    EXISTS (
      SELECT 1
      FROM public.follows f
      WHERE f.followed_by_id = p_current_user_id
        AND f.following_id = u.id
    ) AS current_user_follows_creator
  FROM public.buckets b
  JOIN public.users u ON u.id = b.related_user_id
)
SELECT
  c.bucket_id,
  c.title AS bucket_title,
  c.is_completed AS bucket_is_completed,
  c.creator_user_id,
  c.name AS creator_name,
  c.slug AS creator_slug,
  c.profile_picture_url AS creator_profile_picture_url,
  c.creator_follows_current,
  c.current_user_follows_creator
FROM ranked r
JOIN creators c ON c.bucket_id = r.other_id
WHERE c.is_private = FALSE
ORDER BY
  c.creator_follows_current DESC,
  c.current_user_follows_creator DESC,
  r.shared_tags DESC,
  c.bucket_id DESC
LIMIT p_limit OFFSET p_offset;
$$;


ALTER FUNCTION "public"."match_buckets_simple"("p_bucket_id" bigint, "p_current_user_id" bigint, "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reorder_novels_values"("new_order" bigint[]) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
begin
  update novels n
  set sort_factor = src.position
  from (
    select
      unnest(new_order)                    as id,
      generate_subscripts(new_order, 1)    as position
  ) as src
  where n.id = src.id;
end;
$$;


ALTER FUNCTION "public"."reorder_novels_values"("new_order" bigint[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_buckets_by_title"("p_search" "text", "p_limit" integer DEFAULT 50, "p_offset" integer DEFAULT 0) RETURNS SETOF "public"."buckets"
    LANGUAGE "sql" STABLE
    AS $$
  SELECT *
  FROM public.buckets b
  WHERE
    b.is_private = FALSE                         -- only public buckets
    AND b.related_user_id IS NOT NULL            -- must have a creator
    AND (b.custom_explore IS NULL OR b.custom_explore = FALSE) -- ignore custom_explore = true
    AND trim(p_search) <> ''                     -- avoid empty query = match all
    AND LOWER(b.title) LIKE
        '%' || LOWER(TRIM(p_search)) || '%'      -- case-insensitive contains
  ORDER BY b.id DESC
  LIMIT p_limit OFFSET p_offset;
$$;


ALTER FUNCTION "public"."search_buckets_by_title"("p_search" "text", "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_posts_feed"("p_current_user_id" bigint, "p_search_string" "text", "p_limit" integer DEFAULT 20, "p_before_id" bigint DEFAULT NULL::bigint, "p_related_bucket_id" bigint DEFAULT NULL::bigint) RETURNS TABLE("post" "public"."posts", "related_user_row" "public"."users", "related_bucket_row" "public"."buckets", "goals" "text"[])
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    p,
    u,
    b,
    COALESCE(g.goals, '{}') AS goals
  FROM public.posts p
  LEFT JOIN public.users u
    ON u.id = p.related_user_id
  LEFT JOIN public.buckets b
    ON b.id = p.related_bucket_id
  LEFT JOIN LATERAL (
    SELECT array_agg(pmg.goal_text ORDER BY pmg.id) AS goals
    FROM public.posts_multi_goals pmg
    WHERE pmg.post_id = p.id
  ) g ON TRUE
  WHERE
    -- Skip posts where user no longer exists
    u.id IS NOT NULL

    -- Optional bucket filter
    AND (p_related_bucket_id IS NULL OR p.related_bucket_id = p_related_bucket_id)

    -- Search in post context, user name, and bucket title
    AND (
      p_search_string IS NULL
      OR p.context ILIKE '%' || p_search_string || '%'
      OR u.full_name ILIKE '%' || p_search_string || '%'
      OR b.title ILIKE '%' || p_search_string || '%'
    )

    -- Keyset pagination logic (using ID)
    AND (
      p_before_id IS NULL
      OR p.id < p_before_id
    )

  -- Sort by post ID descending (latest posts first)
  ORDER BY
    p.id DESC

  -- Limit the number of posts to return
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION "public"."search_posts_feed"("p_current_user_id" bigint, "p_search_string" "text", "p_limit" integer, "p_before_id" bigint, "p_related_bucket_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_users_by_full_name"("p_search_string" "text") RETURNS SETOF "public"."users"
    LANGUAGE "sql" STABLE
    AS $$
    SELECT *
    FROM public.users u
    WHERE LOWER(u.full_name) LIKE LOWER('%' || p_search_string || '%');
$$;


ALTER FUNCTION "public"."search_users_by_full_name"("p_search_string" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."start_bucket_email_flow"("p_user_id" bigint, "p_bucket_id" bigint, "p_base_time" timestamp with time zone DEFAULT "now"()) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_is_system BOOLEAN;
  v_already_sent BOOLEAN;
  v_owner BIGINT;
BEGIN
  -- Validate bucket
  SELECT is_system_bucket, personalized_email, related_user_id
  INTO v_is_system, v_already_sent, v_owner
  FROM public.buckets
  WHERE id = p_bucket_id;

  -- Skip if bucket doesn't exist
  IF v_owner IS NULL THEN
    RETURN;
  END IF;

  -- Skip if bucket doesn't belong to user
  IF v_owner <> p_user_id THEN
    RETURN;
  END IF;

  -- Skip system buckets
  IF v_is_system THEN
    RETURN;
  END IF;

  -- Skip if already processed
  IF v_already_sent THEN
    RETURN;
  END IF;

  --------------------------------------------------------------------
  -- Email 1: Action Plan (Day 3)
  --------------------------------------------------------------------
  INSERT INTO public.scheduled_tasks (
    user_id,
    bucket_id,
    task_type,
    run_at
  ) VALUES (
    p_user_id,
    p_bucket_id,
    'bucket_action_plan_email',
    p_base_time + INTERVAL '3 days'
  );

  --------------------------------------------------------------------
  -- Email 2: Suggested Matches (Day 5)
  --------------------------------------------------------------------
  INSERT INTO public.scheduled_tasks (
    user_id,
    bucket_id,
    task_type,
    run_at
  ) VALUES (
    p_user_id,
    p_bucket_id,
    'bucket_suggested_matches_email',
    p_base_time + INTERVAL '5 days'
  );

  --------------------------------------------------------------------
  -- Email 3: Partner Email (Day 7)
  --------------------------------------------------------------------
  INSERT INTO public.scheduled_tasks (
    user_id,
    bucket_id,
    task_type,
    run_at
  ) VALUES (
    p_user_id,
    p_bucket_id,
    'bucket_partner_email',
    p_base_time + INTERVAL '7 days'
  );

  --------------------------------------------------------------------
  -- Mark bucket as processed + update user’s last flow timestamp
  --------------------------------------------------------------------
  UPDATE public.buckets
  SET personalized_email = TRUE
  WHERE id = p_bucket_id;

  UPDATE public.users
  SET last_personalized_bucket_flow_at = NOW()
  WHERE id = p_user_id;

END;
$$;


ALTER FUNCTION "public"."start_bucket_email_flow"("p_user_id" bigint, "p_bucket_id" bigint, "p_base_time" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."start_or_continue_conversation"("p_sender" bigint, "p_receiver" bigint, "p_body" "text", "p_bucket_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    existing_conversation_id bigint;
    new_conversation_id bigint;
BEGIN
    -- 1. Check if conversation exists
    SELECT cu.conversation_id INTO existing_conversation_id
    FROM conversations_users cu
    WHERE cu.user_id IN (p_sender, p_receiver)
    GROUP BY cu.conversation_id
    HAVING COUNT(*) = 2
    LIMIT 1;

    -- 2. If exists → update + insert message
    IF existing_conversation_id IS NOT NULL THEN
        UPDATE conversations
        SET last_updated = NOW()
        WHERE id = existing_conversation_id;

        INSERT INTO messages (related_conversation_id, sender_id, receiver_id, content, referenced_bucket_id, read)
        VALUES (existing_conversation_id, p_sender, p_receiver, p_body, p_bucket_id, FALSE);

    ELSE
        -- 3. Create new conversation
        INSERT INTO conversations (last_updated, created_by, draft)
        VALUES (NOW(), p_sender, FALSE)
        RETURNING id INTO new_conversation_id;

        -- 4. Link both users
        INSERT INTO conversations_users (conversation_id, user_id)
        VALUES 
            (new_conversation_id, p_sender),
            (new_conversation_id, p_receiver);

        -- 5. Insert first message
        INSERT INTO messages (related_conversation_id, sender_id, receiver_id, content, referenced_bucket_id, read)
        VALUES (new_conversation_id, p_sender, p_receiver, p_body, p_bucket_id, FALSE);
    END IF;
END;
$$;


ALTER FUNCTION "public"."start_or_continue_conversation"("p_sender" bigint, "p_receiver" bigint, "p_body" "text", "p_bucket_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_user_email_preferences"("p_user_id" bigint, "p_email_type_ids" bigint[]) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- 1) DELETE rows that are NOT in the new list
  DELETE FROM public.users_email_preferences
  WHERE user_id = p_user_id
    AND email_type <> ALL (p_email_type_ids);

  -- 2) INSERT rows that are missing
  INSERT INTO public.users_email_preferences (user_id, email_type)
  SELECT p_user_id, unnest(p_email_type_ids)
  ON CONFLICT (user_id, email_type) DO NOTHING;

END;
$$;


ALTER FUNCTION "public"."sync_user_email_preferences"("p_user_id" bigint, "p_email_type_ids" bigint[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_novel_order"("id_list" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
declare
    ids text[];
    i int;
    novel_id text;
begin
    -- convert CSV "1,5,3,10" → array ['1','5','3','10']
    ids := string_to_array(id_list, ',');

    -- loop through array and update each
    i := 1;

    foreach novel_id in array ids
    loop
        update novels
        set sort_factor = i
        where id::text = novel_id;

        i := i + 1;
    end loop;
end;
$$;


ALTER FUNCTION "public"."update_novel_order"("id_list" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_story_board_items_order_by_bucket"("id_list" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$DECLARE
  ids text[];
  i int;
  item_id_text text;
  rows_updated int := 0;
  last_count int := 0;
BEGIN
  -- parse CSV to array
  ids := string_to_array(id_list, ',');
  i := 1;

  -- loop through each story_board_item id (as text) and set sort_factor accordingly
  FOREACH item_id_text IN ARRAY ids
  LOOP
    UPDATE public.story_board_items
    SET sort_factor = i
    WHERE id::text = item_id_text;

    GET DIAGNOSTICS last_count = ROW_COUNT;
    rows_updated := rows_updated + last_count;

    i := i + 1;
  END LOOP;

  RETURN jsonb_build_object('ids', ids, 'rows_updated', rows_updated);
END;$$;


ALTER FUNCTION "public"."update_story_board_items_order_by_bucket"("id_list" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_users_buckets_order"("id_list" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$DECLARE
  ids text[];
  i int;
  bucket_id_text text;
  rows_updated int := 0;
  last_count int := 0;
BEGIN
  -- parse CSV to array
  ids := string_to_array(id_list, ',');
  i := 1;

  -- loop through each bucket id (as text) and set sort_factor accordingly
  FOREACH bucket_id_text IN ARRAY ids
  LOOP
    UPDATE public.users_buckets
    SET sort_factor = i
    WHERE bucket_id::text = bucket_id_text;

    GET DIAGNOSTICS last_count = ROW_COUNT;
    rows_updated := rows_updated + last_count;

    i := i + 1;
  END LOOP;

  RETURN jsonb_build_object('ids', ids, 'rows_updated', rows_updated);
END;$$;


ALTER FUNCTION "public"."update_users_buckets_order"("id_list" "text") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."action_plan_tasks" (
    "id" bigint NOT NULL,
    "uid" "text",
    "title" "text",
    "is_completed" boolean DEFAULT false,
    "description" "text",
    "completion_date" "date",
    "related_bucket_id" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "related_bucket_uid" "text"
);


ALTER TABLE "public"."action_plan_tasks" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."action_plan_tasks_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."action_plan_tasks_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."action_plan_tasks_id_seq" OWNED BY "public"."action_plan_tasks"."id";



CREATE TABLE IF NOT EXISTS "public"."admin_email" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."admin_email" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."admin_email_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."admin_email_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."admin_email_id_seq" OWNED BY "public"."admin_email"."id";



CREATE TABLE IF NOT EXISTS "public"."app_icons" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "img" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."app_icons" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."app_icons_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."app_icons_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."app_icons_id_seq" OWNED BY "public"."app_icons"."id";



CREATE TABLE IF NOT EXISTS "public"."bucket_list_filter" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "ui" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."bucket_list_filter" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."bucket_list_filter_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."bucket_list_filter_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."bucket_list_filter_id_seq" OWNED BY "public"."bucket_list_filter"."id";



CREATE TABLE IF NOT EXISTS "public"."buckets_categories" (
    "id" bigint NOT NULL,
    "uid" "text",
    "bucket_id" bigint,
    "category" bigint,
    "bucket_uid" "text",
    "category_name" "text"
);


ALTER TABLE "public"."buckets_categories" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."buckets_categories_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."buckets_categories_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."buckets_categories_id_seq" OWNED BY "public"."buckets_categories"."id";



CREATE TABLE IF NOT EXISTS "public"."buckets_comments" (
    "id" bigint NOT NULL,
    "uid" "text",
    "bucket_id" bigint,
    "comment_id" bigint,
    "bucket_uid" "text",
    "comment_uid" "text"
);


ALTER TABLE "public"."buckets_comments" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."buckets_comments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."buckets_comments_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."buckets_comments_id_seq" OWNED BY "public"."buckets_comments"."id";



CREATE TABLE IF NOT EXISTS "public"."buckets_explore_buckets" (
    "id" bigint NOT NULL,
    "uid" "text",
    "bucket_id" bigint,
    "explore_bucket_id" bigint,
    "bucket_uid" "text",
    "explore_bucket_uid" "text"
);


ALTER TABLE "public"."buckets_explore_buckets" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."buckets_explore_buckets_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."buckets_explore_buckets_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."buckets_explore_buckets_id_seq" OWNED BY "public"."buckets_explore_buckets"."id";



CREATE SEQUENCE IF NOT EXISTS "public"."buckets_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."buckets_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."buckets_id_seq" OWNED BY "public"."buckets"."id";



CREATE TABLE IF NOT EXISTS "public"."buckets_partner_experts" (
    "id" bigint NOT NULL,
    "uid" "text",
    "bucket_id" bigint,
    "partner_expert_id" bigint,
    "bucket_uid" "text",
    "partner_expert_uid" "text"
);


ALTER TABLE "public"."buckets_partner_experts" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."buckets_partner_experts_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."buckets_partner_experts_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."buckets_partner_experts_id_seq" OWNED BY "public"."buckets_partner_experts"."id";



CREATE TABLE IF NOT EXISTS "public"."buckets_story_board_items" (
    "id" bigint NOT NULL,
    "uid" "text",
    "bucket_id" bigint,
    "story_board_item_id" bigint,
    "bucket_uid" "text",
    "story_board_item_uid" "text"
);


ALTER TABLE "public"."buckets_story_board_items" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."buckets_story_board_items_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."buckets_story_board_items_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."buckets_story_board_items_id_seq" OWNED BY "public"."buckets_story_board_items"."id";



CREATE TABLE IF NOT EXISTS "public"."buckets_tags" (
    "id" bigint NOT NULL,
    "uid" "text",
    "bucket_id" bigint,
    "tag" "text",
    "bucket_uid" "text"
);


ALTER TABLE "public"."buckets_tags" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."buckets_tags_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."buckets_tags_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."buckets_tags_id_seq" OWNED BY "public"."buckets_tags"."id";



CREATE TABLE IF NOT EXISTS "public"."category_os" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "emoji" "text",
    "img" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."category_os" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."category_os_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."category_os_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."category_os_id_seq" OWNED BY "public"."category_os"."id";



CREATE SEQUENCE IF NOT EXISTS "public"."collaborators_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."collaborators_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."collaborators_id_seq" OWNED BY "public"."collaborators"."id";



CREATE TABLE IF NOT EXISTS "public"."colours" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."colours" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."colours_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."colours_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."colours_id_seq" OWNED BY "public"."colours"."id";



CREATE TABLE IF NOT EXISTS "public"."comments" (
    "id" bigint NOT NULL,
    "uid" "text",
    "content" "text",
    "related_bucket_id" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "related_bucket_uid" "text"
);


ALTER TABLE "public"."comments" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."comments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."comments_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."comments_id_seq" OWNED BY "public"."comments"."id";



CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "id" bigint NOT NULL,
    "uid" "text",
    "last_updated" timestamp with time zone DEFAULT "now"(),
    "draft" boolean DEFAULT true,
    "related_bucket_id" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "related_bucket_uid" "text"
);


ALTER TABLE "public"."conversations" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."conversations_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."conversations_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."conversations_id_seq" OWNED BY "public"."conversations"."id";



CREATE TABLE IF NOT EXISTS "public"."conversations_users" (
    "id" bigint NOT NULL,
    "uid" "text",
    "conversation_id" bigint,
    "user_id" bigint,
    "conversation_uid" "text",
    "user_uid" "text"
);


ALTER TABLE "public"."conversations_users" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."conversations_users_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."conversations_users_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."conversations_users_id_seq" OWNED BY "public"."conversations_users"."id";



CREATE TABLE IF NOT EXISTS "public"."default_goals" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "img" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."default_goals" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."default_goals_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."default_goals_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."default_goals_id_seq" OWNED BY "public"."default_goals"."id";



CREATE TABLE IF NOT EXISTS "public"."desc_placeholder_os" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."desc_placeholder_os" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."desc_placeholder_os_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."desc_placeholder_os_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."desc_placeholder_os_id_seq" OWNED BY "public"."desc_placeholder_os"."id";



CREATE TABLE IF NOT EXISTS "public"."do_you_already_have_a_bucket_list" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."do_you_already_have_a_bucket_list" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."do_you_already_have_a_bucket_list_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."do_you_already_have_a_bucket_list_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."do_you_already_have_a_bucket_list_id_seq" OWNED BY "public"."do_you_already_have_a_bucket_list"."id";



CREATE TABLE IF NOT EXISTS "public"."doc_extensions" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."doc_extensions" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."doc_extensions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."doc_extensions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."doc_extensions_id_seq" OWNED BY "public"."doc_extensions"."id";



CREATE TABLE IF NOT EXISTS "public"."dummies" (
    "id" bigint NOT NULL,
    "uid" "text",
    "post_maker_id" bigint,
    "post_title" "text",
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."dummies" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."dummies_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."dummies_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."dummies_id_seq" OWNED BY "public"."dummies"."id";



CREATE TABLE IF NOT EXISTS "public"."email_logs" (
    "id" bigint NOT NULL,
    "to_email" "text" NOT NULL,
    "template_id" "text" NOT NULL,
    "payload" "jsonb",
    "type" "text",
    "category" "text",
    "status" "text",
    "response" "text",
    "inserted_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."email_logs" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."email_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."email_logs_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."email_logs_id_seq" OWNED BY "public"."email_logs"."id";



CREATE TABLE IF NOT EXISTS "public"."email_type" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "description" "text",
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."email_type" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."email_type_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."email_type_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."email_type_id_seq" OWNED BY "public"."email_type"."id";



CREATE TABLE IF NOT EXISTS "public"."errors" (
    "id" bigint NOT NULL,
    "uid" "text",
    "log" "text",
    "user_id" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."errors" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."errors_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."errors_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."errors_id_seq" OWNED BY "public"."errors"."id";



CREATE TABLE IF NOT EXISTS "public"."feed_comments" (
    "id" bigint NOT NULL,
    "uid" "text",
    "context" "text",
    "post_id" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "post_uid" "text"
);


ALTER TABLE "public"."feed_comments" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."feed_comments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."feed_comments_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."feed_comments_id_seq" OWNED BY "public"."feed_comments"."id";



CREATE TABLE IF NOT EXISTS "public"."file_type" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "deleted" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."file_type" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."file_type_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."file_type_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."file_type_id_seq" OWNED BY "public"."file_type"."id";



CREATE TABLE IF NOT EXISTS "public"."follow" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "ui" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."follow" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."follow_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."follow_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."follow_id_seq" OWNED BY "public"."follow"."id";



CREATE TABLE IF NOT EXISTS "public"."follows" (
    "id" bigint NOT NULL,
    "uid" "text",
    "following_id" bigint,
    "followed_by_id" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "following_email" "text",
    "followed_by_email" "text"
);


ALTER TABLE "public"."follows" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."follows_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."follows_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."follows_id_seq" OWNED BY "public"."follows"."id";



CREATE TABLE IF NOT EXISTS "public"."handle_new_auth_user_debug" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "new_id_text" "text",
    "new_email" "text",
    "error_message" "text"
);


ALTER TABLE "public"."handle_new_auth_user_debug" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."handle_new_auth_user_debug_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."handle_new_auth_user_debug_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."handle_new_auth_user_debug_id_seq" OWNED BY "public"."handle_new_auth_user_debug"."id";



CREATE TABLE IF NOT EXISTS "public"."how_did_you_hear_about_us" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."how_did_you_hear_about_us" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."how_did_you_hear_about_us_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."how_did_you_hear_about_us_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."how_did_you_hear_about_us_id_seq" OWNED BY "public"."how_did_you_hear_about_us"."id";



CREATE TABLE IF NOT EXISTS "public"."image_extension" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."image_extension" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."image_extension_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."image_extension_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."image_extension_id_seq" OWNED BY "public"."image_extension"."id";



CREATE TABLE IF NOT EXISTS "public"."index_tab" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."index_tab" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."index_tab_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."index_tab_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."index_tab_id_seq" OWNED BY "public"."index_tab"."id";



CREATE TABLE IF NOT EXISTS "public"."likes" (
    "id" bigint NOT NULL,
    "uid" "text",
    "on_bucket_id" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "related_bucket_uid" "text"
);


ALTER TABLE "public"."likes" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."likes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."likes_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."likes_id_seq" OWNED BY "public"."likes"."id";



CREATE TABLE IF NOT EXISTS "public"."links" (
    "id" bigint NOT NULL,
    "uid" "text",
    "url" "text",
    "text_to_display" "text",
    "related_bucket_id" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "related_bucket_uid" "text"
);


ALTER TABLE "public"."links" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."links_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."links_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."links_id_seq" OWNED BY "public"."links"."id";



CREATE TABLE IF NOT EXISTS "public"."message_recs_os" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "buddy" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."message_recs_os" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."message_recs_os_2" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."message_recs_os_2" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."message_recs_os_2_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."message_recs_os_2_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."message_recs_os_2_id_seq" OWNED BY "public"."message_recs_os_2"."id";



CREATE SEQUENCE IF NOT EXISTS "public"."message_recs_os_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."message_recs_os_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."message_recs_os_id_seq" OWNED BY "public"."message_recs_os"."id";



CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" bigint NOT NULL,
    "uid" "text",
    "content" "text",
    "sender_id" bigint,
    "picture_url" "text",
    "receiver_id" bigint,
    "attachment_url" "text",
    "read" boolean DEFAULT false,
    "related_conversation_id" bigint,
    "referenced_bucket_id" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "sender_email" "text",
    "reciever_email" "text",
    "related_conversation_uid" "text",
    "referenced_bucket_uid" "text"
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."messages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."messages_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."messages_id_seq" OWNED BY "public"."messages"."id";



CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" bigint NOT NULL,
    "uid" "text",
    "recipient_id" bigint,
    "content" "text",
    "read" boolean DEFAULT false,
    "sender_id" bigint,
    "referenced_bucket_id" bigint,
    "referenced_post_id" bigint,
    "type" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "sender_email" "text",
    "reciever_email" "text",
    "type_text" "text",
    "referenced_bucket_uid" "text",
    "referenced_post_uid" "text"
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."notifications_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."notifications_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."notifications_id_seq" OWNED BY "public"."notifications"."id";



CREATE TABLE IF NOT EXISTS "public"."novels" (
    "id" bigint NOT NULL,
    "title_name" "text" NOT NULL,
    "author_name" "text" NOT NULL,
    "sort_factor" bigint
);


ALTER TABLE "public"."novels" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."novels_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."novels_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."novels_id_seq" OWNED BY "public"."novels"."id";



CREATE TABLE IF NOT EXISTS "public"."onboarding_qna" (
    "id" bigint NOT NULL,
    "uid" "text",
    "user_id" bigint,
    "how_did_you_hear_about_us" "text",
    "what_inspired_you_to_sign_up" "text",
    "do_you_already_have_a_bucket_list" "text",
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."onboarding_qna" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."onboarding_qna_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."onboarding_qna_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."onboarding_qna_id_seq" OWNED BY "public"."onboarding_qna"."id";



CREATE TABLE IF NOT EXISTS "public"."os_buckets" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "picture" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."os_buckets" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."os_buckets_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."os_buckets_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."os_buckets_id_seq" OWNED BY "public"."os_buckets"."id";



CREATE TABLE IF NOT EXISTS "public"."pages" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "not_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."pages" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pages_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pages_id_seq" OWNED BY "public"."pages"."id";



CREATE TABLE IF NOT EXISTS "public"."partner_experts" (
    "id" bigint NOT NULL,
    "uid" "text",
    "name" "text",
    "logo_url" "text",
    "ai_detail" "text",
    "expert" boolean DEFAULT false,
    "related_user_id" bigint,
    "affiliate_link" "text",
    "short_description" "text",
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "related_user" "text"
);


ALTER TABLE "public"."partner_experts" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."partner_experts_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."partner_experts_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."partner_experts_id_seq" OWNED BY "public"."partner_experts"."id";



CREATE TABLE IF NOT EXISTS "public"."partner_experts_pictures" (
    "id" bigint NOT NULL,
    "uid" "text",
    "partner_expert_id" bigint,
    "picture_url" "text",
    "partner_expert_uid" "text"
);


ALTER TABLE "public"."partner_experts_pictures" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."partner_experts_pictures_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."partner_experts_pictures_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."partner_experts_pictures_id_seq" OWNED BY "public"."partner_experts_pictures"."id";



CREATE TABLE IF NOT EXISTS "public"."popup_goal_tabs" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."popup_goal_tabs" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."popup_goal_tabs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."popup_goal_tabs_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."popup_goal_tabs_id_seq" OWNED BY "public"."popup_goal_tabs"."id";



CREATE TABLE IF NOT EXISTS "public"."post_type_os" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."post_type_os" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."post_type_os_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."post_type_os_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."post_type_os_id_seq" OWNED BY "public"."post_type_os"."id";



CREATE TABLE IF NOT EXISTS "public"."posts_comments" (
    "id" bigint NOT NULL,
    "uid" "text",
    "post_id" bigint,
    "comment_id" bigint,
    "post_uid" "text",
    "comment_uid" "text"
);


ALTER TABLE "public"."posts_comments" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."posts_comments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."posts_comments_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."posts_comments_id_seq" OWNED BY "public"."posts_comments"."id";



CREATE SEQUENCE IF NOT EXISTS "public"."posts_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."posts_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."posts_id_seq" OWNED BY "public"."posts"."id";



CREATE TABLE IF NOT EXISTS "public"."posts_likes" (
    "id" bigint NOT NULL,
    "uid" "text",
    "post_id" bigint,
    "user_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "post_uid" "text",
    "user_uid" "text"
);


ALTER TABLE "public"."posts_likes" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."posts_likes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."posts_likes_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."posts_likes_id_seq" OWNED BY "public"."posts_likes"."id";



CREATE TABLE IF NOT EXISTS "public"."posts_multi_goals" (
    "id" bigint NOT NULL,
    "uid" "text",
    "post_id" bigint,
    "goal_text" "text",
    "post_uid" "text"
);


ALTER TABLE "public"."posts_multi_goals" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."posts_multi_goals_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."posts_multi_goals_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."posts_multi_goals_id_seq" OWNED BY "public"."posts_multi_goals"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_buckets_categories" (
    "id" bigint NOT NULL,
    "uid" "text",
    "bucket_id" bigint,
    "bucket_uid" "text",
    "category" "text"
);


ALTER TABLE "public"."pseudos_buckets_categories" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_buckets_categories_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_buckets_categories_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_buckets_categories_id_seq" OWNED BY "public"."pseudos_buckets_categories"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_buckets_comments" (
    "id" bigint NOT NULL,
    "uid" "text",
    "bucket_id" bigint,
    "bucket_uid" "text",
    "comment_id" bigint,
    "comment_uid" "text"
);


ALTER TABLE "public"."pseudos_buckets_comments" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_buckets_comments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_buckets_comments_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_buckets_comments_id_seq" OWNED BY "public"."pseudos_buckets_comments"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_buckets_explore_buckets" (
    "id" bigint NOT NULL,
    "uid" "text",
    "bucket_id" bigint,
    "bucket_uid" "text",
    "explore_bucket_uids" "text"
);


ALTER TABLE "public"."pseudos_buckets_explore_buckets" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_buckets_explore_buckets_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_buckets_explore_buckets_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_buckets_explore_buckets_id_seq" OWNED BY "public"."pseudos_buckets_explore_buckets"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_buckets_partner_experts" (
    "id" bigint NOT NULL,
    "uid" "text",
    "bucket_id" bigint,
    "bucket_uid" "text",
    "partner_expert_uids" "text"
);


ALTER TABLE "public"."pseudos_buckets_partner_experts" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_buckets_partner_experts_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_buckets_partner_experts_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_buckets_partner_experts_id_seq" OWNED BY "public"."pseudos_buckets_partner_experts"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_buckets_story_board_items" (
    "id" bigint NOT NULL,
    "uid" "text",
    "bucket_id" bigint,
    "bucket_uid" "text",
    "story_board_items_uid" "text"
);


ALTER TABLE "public"."pseudos_buckets_story_board_items" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_buckets_story_board_items_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_buckets_story_board_items_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_buckets_story_board_items_id_seq" OWNED BY "public"."pseudos_buckets_story_board_items"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_buckets_tags" (
    "id" bigint NOT NULL,
    "uid" "text",
    "bucket_id" bigint,
    "bucket_uid" "text",
    "tags" "text"
);


ALTER TABLE "public"."pseudos_buckets_tags" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_buckets_tags_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_buckets_tags_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_buckets_tags_id_seq" OWNED BY "public"."pseudos_buckets_tags"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_conversations_users" (
    "id" bigint NOT NULL,
    "uid" "text",
    "conversation_id" bigint,
    "conversation_uid" "text",
    "user_id" bigint,
    "user_emails" "text"
);


ALTER TABLE "public"."pseudos_conversations_users" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_conversations_users_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_conversations_users_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_conversations_users_id_seq" OWNED BY "public"."pseudos_conversations_users"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_partner_experts_pictures" (
    "id" bigint NOT NULL,
    "uid" "text",
    "partner_expert_id" bigint,
    "partner_expert_uid" "text",
    "picture_urls" "text"
);


ALTER TABLE "public"."pseudos_partner_experts_pictures" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_partner_experts_pictures_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_partner_experts_pictures_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_partner_experts_pictures_id_seq" OWNED BY "public"."pseudos_partner_experts_pictures"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_posts_comments" (
    "id" bigint NOT NULL,
    "post_id" bigint,
    "post_uid" "text",
    "comment_id" bigint,
    "comment_uid" "text"
);


ALTER TABLE "public"."pseudos_posts_comments" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_posts_comments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_posts_comments_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_posts_comments_id_seq" OWNED BY "public"."pseudos_posts_comments"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_posts_likes" (
    "id" bigint NOT NULL,
    "uid" "text",
    "post_id" bigint,
    "post_uid" "text",
    "user_emails" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."pseudos_posts_likes" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_posts_likes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_posts_likes_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_posts_likes_id_seq" OWNED BY "public"."pseudos_posts_likes"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_posts_multi_goals" (
    "id" bigint NOT NULL,
    "uid" "text",
    "post_id" bigint,
    "post_uid" "text",
    "multi_goal_text" "text"
);


ALTER TABLE "public"."pseudos_posts_multi_goals" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_posts_multi_goals_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_posts_multi_goals_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_posts_multi_goals_id_seq" OWNED BY "public"."pseudos_posts_multi_goals"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_recommendations_buckets" (
    "id" bigint NOT NULL,
    "recommendation_id" bigint,
    "recommendation_uid" "text",
    "bucket_uids" "text"
);


ALTER TABLE "public"."pseudos_recommendations_buckets" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_recommendations_buckets_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_recommendations_buckets_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_recommendations_buckets_id_seq" OWNED BY "public"."pseudos_recommendations_buckets"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_referrals_joined_users" (
    "id" bigint NOT NULL,
    "uid" "text",
    "referral_id" bigint,
    "referral_uid" "text",
    "user_emails" "text"
);


ALTER TABLE "public"."pseudos_referrals_joined_users" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_referrals_joined_users_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_referrals_joined_users_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_referrals_joined_users_id_seq" OWNED BY "public"."pseudos_referrals_joined_users"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_story_board_items_links" (
    "id" bigint NOT NULL,
    "uid" "text",
    "story_board_item_id" bigint,
    "story_board_item_uid" "text",
    "links_uid" "text"
);


ALTER TABLE "public"."pseudos_story_board_items_links" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_story_board_items_links_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_story_board_items_links_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_story_board_items_links_id_seq" OWNED BY "public"."pseudos_story_board_items_links"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_users_buckets" (
    "id" bigint NOT NULL,
    "uid" "text",
    "user_id" bigint,
    "user_email" "text",
    "bucket_id" bigint,
    "buckets_uid" "text"
);


ALTER TABLE "public"."pseudos_users_buckets" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_users_buckets_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_users_buckets_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_users_buckets_id_seq" OWNED BY "public"."pseudos_users_buckets"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_users_cover_photos" (
    "id" bigint NOT NULL,
    "uid" "text",
    "user_id" bigint,
    "user_email" "text",
    "cover_photos" "text"
);


ALTER TABLE "public"."pseudos_users_cover_photos" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_users_cover_photos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_users_cover_photos_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_users_cover_photos_id_seq" OWNED BY "public"."pseudos_users_cover_photos"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_users_email_preferences" (
    "id" bigint NOT NULL,
    "uid" "text",
    "user_id" bigint,
    "user_email" "text",
    "email_type" "text"
);


ALTER TABLE "public"."pseudos_users_email_preferences" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_users_email_preferences_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_users_email_preferences_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_users_email_preferences_id_seq" OWNED BY "public"."pseudos_users_email_preferences"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_users_followers" (
    "id" bigint NOT NULL,
    "uid" "text",
    "user_id" bigint,
    "user_email" "text",
    "follower_uids" "text"
);


ALTER TABLE "public"."pseudos_users_followers" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_users_followers_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_users_followers_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_users_followers_id_seq" OWNED BY "public"."pseudos_users_followers"."id";



CREATE TABLE IF NOT EXISTS "public"."pseudos_users_referred" (
    "id" bigint NOT NULL,
    "referrer_id" bigint,
    "referrer_uid" "text",
    "referred_id" bigint,
    "referred_uid" "text",
    "referral_id" bigint,
    "referral_uid" "text"
);


ALTER TABLE "public"."pseudos_users_referred" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."pseudos_users_referred_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."pseudos_users_referred_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."pseudos_users_referred_id_seq" OWNED BY "public"."pseudos_users_referred"."id";



CREATE TABLE IF NOT EXISTS "public"."range_os" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "img" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."range_os" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."range_os_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."range_os_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."range_os_id_seq" OWNED BY "public"."range_os"."id";



CREATE TABLE IF NOT EXISTS "public"."recommendations" (
    "id" bigint NOT NULL,
    "uid" "text",
    "last_updated" "date" DEFAULT CURRENT_DATE,
    "related_user_id" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "related_user_email" "text"
);


ALTER TABLE "public"."recommendations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recommendations_buckets" (
    "id" bigint NOT NULL,
    "uid" "text",
    "recommendation_id" bigint,
    "bucket_id" bigint,
    "recommendation_uid" "text",
    "bucket_uid" "text"
);


ALTER TABLE "public"."recommendations_buckets" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."recommendations_buckets_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."recommendations_buckets_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."recommendations_buckets_id_seq" OWNED BY "public"."recommendations_buckets"."id";



CREATE SEQUENCE IF NOT EXISTS "public"."recommendations_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."recommendations_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."recommendations_id_seq" OWNED BY "public"."recommendations"."id";



CREATE TABLE IF NOT EXISTS "public"."referrals" (
    "id" bigint NOT NULL,
    "uid" "text",
    "code" "text",
    "joined_count" integer DEFAULT 0,
    "related_user_id" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "related_user_email" "text"
);


ALTER TABLE "public"."referrals" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."referrals_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."referrals_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."referrals_id_seq" OWNED BY "public"."referrals"."id";



CREATE TABLE IF NOT EXISTS "public"."referrals_joined_users" (
    "id" bigint NOT NULL,
    "uid" "text",
    "referral_id" bigint,
    "user_id" bigint,
    "referral_uid" "text",
    "user_uid" "text"
);


ALTER TABLE "public"."referrals_joined_users" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."referrals_joined_users_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."referrals_joined_users_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."referrals_joined_users_id_seq" OWNED BY "public"."referrals_joined_users"."id";



CREATE TABLE IF NOT EXISTS "public"."sample_file_csv" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "file" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."sample_file_csv" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."sample_file_csv_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."sample_file_csv_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."sample_file_csv_id_seq" OWNED BY "public"."sample_file_csv"."id";



CREATE TABLE IF NOT EXISTS "public"."scheduled_tasks" (
    "id" bigint NOT NULL,
    "user_id" bigint NOT NULL,
    "bucket_id" bigint,
    "task_type" "text" NOT NULL,
    "run_at" timestamp with time zone NOT NULL,
    "is_executed" boolean DEFAULT false NOT NULL,
    "executed_at" timestamp with time zone,
    "payload" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."scheduled_tasks" OWNER TO "postgres";


ALTER TABLE "public"."scheduled_tasks" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."scheduled_tasks_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."status_bar" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."status_bar" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."status_bar_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."status_bar_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."status_bar_id_seq" OWNED BY "public"."status_bar"."id";



CREATE TABLE IF NOT EXISTS "public"."story_board_items" (
    "id" bigint NOT NULL,
    "uid" "text",
    "answer" "text",
    "random" "text",
    "link" boolean DEFAULT false,
    "picture_url" "text",
    "colour" bigint,
    "related_bucket_id" bigint,
    "question" bigint,
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "colour_text" "text",
    "question_text" "text",
    "related_bucket_uid" "text",
    "sort_factor" integer
);


ALTER TABLE "public"."story_board_items" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."story_board_items_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."story_board_items_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."story_board_items_id_seq" OWNED BY "public"."story_board_items"."id";



CREATE TABLE IF NOT EXISTS "public"."story_board_items_links" (
    "id" bigint NOT NULL,
    "uid" "text",
    "story_board_item_id" bigint,
    "link_id" bigint,
    "story_board_item_uid" "text",
    "link_uid" "text"
);


ALTER TABLE "public"."story_board_items_links" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."story_board_items_links_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."story_board_items_links_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."story_board_items_links_id_seq" OWNED BY "public"."story_board_items_links"."id";



CREATE TABLE IF NOT EXISTS "public"."story_board_qs" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."story_board_qs" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."story_board_qs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."story_board_qs_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."story_board_qs_id_seq" OWNED BY "public"."story_board_qs"."id";



CREATE TABLE IF NOT EXISTS "public"."sub_pointers" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."sub_pointers" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."sub_pointers_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."sub_pointers_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."sub_pointers_id_seq" OWNED BY "public"."sub_pointers"."id";



CREATE TABLE IF NOT EXISTS "public"."subscription_plan" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "discounted_price" "text",
    "price" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."subscription_plan" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."subscription_plan_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."subscription_plan_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."subscription_plan_id_seq" OWNED BY "public"."subscription_plan"."id";



CREATE TABLE IF NOT EXISTS "public"."testimonials" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "c_address" "text",
    "c_name" "text",
    "content" "text",
    "creater_img" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."testimonials" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."testimonials_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."testimonials_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."testimonials_id_seq" OWNED BY "public"."testimonials"."id";



CREATE TABLE IF NOT EXISTS "public"."tests" (
    "id" bigint NOT NULL,
    "uid" "text",
    "text_content" "text",
    "image_url" "text",
    "creator" "text",
    "created_by" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."tests" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."tests_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."tests_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."tests_id_seq" OWNED BY "public"."tests"."id";



CREATE TABLE IF NOT EXISTS "public"."title_placeholder_os" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."title_placeholder_os" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."title_placeholder_os_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."title_placeholder_os_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."title_placeholder_os_id_seq" OWNED BY "public"."title_placeholder_os"."id";



CREATE TABLE IF NOT EXISTS "public"."type_of_notifications" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "content" "text",
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."type_of_notifications" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."type_of_notifications_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."type_of_notifications_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."type_of_notifications_id_seq" OWNED BY "public"."type_of_notifications"."id";



CREATE TABLE IF NOT EXISTS "public"."user_metadata_sync" (
    "id" bigint NOT NULL,
    "auth_user_id" "uuid" NOT NULL,
    "user_id" bigint NOT NULL,
    "payload" "jsonb" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "last_error" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_metadata_sync" OWNER TO "postgres";


ALTER TABLE "public"."user_metadata_sync" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_metadata_sync_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user_sync_queue" (
    "id" bigint NOT NULL,
    "user_id" "uuid",
    "auth_user_id" "uuid",
    "payload" "jsonb",
    "status" "text" DEFAULT 'pending'::"text",
    "attempts" integer DEFAULT 0,
    "last_error" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "public_user_id" bigint
);


ALTER TABLE "public"."user_sync_queue" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."user_sync_queue_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."user_sync_queue_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."user_sync_queue_id_seq" OWNED BY "public"."user_sync_queue"."id";



CREATE TABLE IF NOT EXISTS "public"."users_buckets" (
    "id" bigint NOT NULL,
    "uid" "text",
    "user_id" bigint,
    "bucket_id" bigint,
    "user_uid" "text",
    "bucket_uid" "text",
    "sort_factor" integer
);


ALTER TABLE "public"."users_buckets" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."users_buckets_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."users_buckets_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."users_buckets_id_seq" OWNED BY "public"."users_buckets"."id";



CREATE TABLE IF NOT EXISTS "public"."users_cover_photos" (
    "id" bigint NOT NULL,
    "uid" "text",
    "user_id" bigint,
    "cover_photo_url" "text",
    "user_uid" "text"
);


ALTER TABLE "public"."users_cover_photos" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."users_cover_photos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."users_cover_photos_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."users_cover_photos_id_seq" OWNED BY "public"."users_cover_photos"."id";



CREATE TABLE IF NOT EXISTS "public"."users_email_preferences" (
    "id" bigint NOT NULL,
    "uid" "text",
    "user_id" bigint,
    "email_type" bigint,
    "user_uid" "text",
    "email_type_text" "text"
);


ALTER TABLE "public"."users_email_preferences" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."users_email_preferences_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."users_email_preferences_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."users_email_preferences_id_seq" OWNED BY "public"."users_email_preferences"."id";



CREATE TABLE IF NOT EXISTS "public"."users_followers" (
    "id" bigint NOT NULL,
    "uid" "text",
    "user_id" bigint,
    "follower_id" bigint,
    "user_uid" "text",
    "follower_uid" "text"
);


ALTER TABLE "public"."users_followers" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."users_followers_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."users_followers_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."users_followers_id_seq" OWNED BY "public"."users_followers"."id";



CREATE SEQUENCE IF NOT EXISTS "public"."users_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."users_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."users_id_seq" OWNED BY "public"."users"."id";



CREATE TABLE IF NOT EXISTS "public"."users_referred" (
    "id" bigint NOT NULL,
    "uid" "text",
    "referrer_id" bigint,
    "referred_id" bigint,
    "referral_id" bigint,
    "referrer_uid" "text",
    "referred_uid" "text",
    "referral_uid" "text"
);


ALTER TABLE "public"."users_referred" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."users_referred_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."users_referred_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."users_referred_id_seq" OWNED BY "public"."users_referred"."id";



CREATE TABLE IF NOT EXISTS "public"."vid_extensions" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."vid_extensions" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."vid_extensions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."vid_extensions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."vid_extensions_id_seq" OWNED BY "public"."vid_extensions"."id";



CREATE TABLE IF NOT EXISTS "public"."what_inspired_you_to_sign_up" (
    "id" bigint NOT NULL,
    "display" "text" NOT NULL,
    "sort_factor" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."what_inspired_you_to_sign_up" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."what_inspired_you_to_sign_up_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."what_inspired_you_to_sign_up_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."what_inspired_you_to_sign_up_id_seq" OWNED BY "public"."what_inspired_you_to_sign_up"."id";



ALTER TABLE ONLY "public"."action_plan_tasks" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."action_plan_tasks_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."admin_email" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."admin_email_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."app_icons" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."app_icons_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."bucket_list_filter" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."bucket_list_filter_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."buckets" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."buckets_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."buckets_categories" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."buckets_categories_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."buckets_comments" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."buckets_comments_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."buckets_explore_buckets" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."buckets_explore_buckets_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."buckets_partner_experts" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."buckets_partner_experts_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."buckets_story_board_items" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."buckets_story_board_items_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."buckets_tags" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."buckets_tags_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."category_os" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."category_os_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."collaborators" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."collaborators_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."colours" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."colours_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."comments" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."comments_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."conversations" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."conversations_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."conversations_users" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."conversations_users_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."default_goals" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."default_goals_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."desc_placeholder_os" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."desc_placeholder_os_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."do_you_already_have_a_bucket_list" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."do_you_already_have_a_bucket_list_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."doc_extensions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."doc_extensions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."dummies" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."dummies_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."email_logs" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."email_logs_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."email_type" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."email_type_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."errors" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."errors_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."feed_comments" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."feed_comments_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."file_type" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."file_type_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."follow" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."follow_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."follows" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."follows_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."handle_new_auth_user_debug" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."handle_new_auth_user_debug_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."how_did_you_hear_about_us" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."how_did_you_hear_about_us_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."image_extension" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."image_extension_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."index_tab" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."index_tab_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."likes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."likes_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."links" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."links_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."message_recs_os" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."message_recs_os_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."message_recs_os_2" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."message_recs_os_2_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."messages" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."messages_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."notifications" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."notifications_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."onboarding_qna" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."onboarding_qna_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."os_buckets" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."os_buckets_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pages" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pages_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."partner_experts" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."partner_experts_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."partner_experts_pictures" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."partner_experts_pictures_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."popup_goal_tabs" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."popup_goal_tabs_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."post_type_os" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."post_type_os_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."posts" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."posts_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."posts_comments" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."posts_comments_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."posts_likes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."posts_likes_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."posts_multi_goals" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."posts_multi_goals_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_buckets_categories" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_buckets_categories_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_buckets_comments" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_buckets_comments_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_buckets_explore_buckets" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_buckets_explore_buckets_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_buckets_partner_experts" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_buckets_partner_experts_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_buckets_story_board_items" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_buckets_story_board_items_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_buckets_tags" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_buckets_tags_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_conversations_users" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_conversations_users_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_partner_experts_pictures" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_partner_experts_pictures_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_posts_comments" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_posts_comments_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_posts_likes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_posts_likes_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_posts_multi_goals" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_posts_multi_goals_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_recommendations_buckets" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_recommendations_buckets_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_referrals_joined_users" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_referrals_joined_users_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_story_board_items_links" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_story_board_items_links_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_users_buckets" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_users_buckets_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_users_cover_photos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_users_cover_photos_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_users_email_preferences" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_users_email_preferences_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_users_followers" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_users_followers_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."pseudos_users_referred" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pseudos_users_referred_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."range_os" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."range_os_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."recommendations" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."recommendations_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."recommendations_buckets" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."recommendations_buckets_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."referrals" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."referrals_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."referrals_joined_users" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."referrals_joined_users_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."sample_file_csv" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sample_file_csv_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."status_bar" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."status_bar_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."story_board_items" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."story_board_items_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."story_board_items_links" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."story_board_items_links_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."story_board_qs" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."story_board_qs_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."sub_pointers" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sub_pointers_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."subscription_plan" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."subscription_plan_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."testimonials" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."testimonials_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."tests" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tests_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."title_placeholder_os" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."title_placeholder_os_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."type_of_notifications" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."type_of_notifications_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."user_sync_queue" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."user_sync_queue_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."users" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."users_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."users_buckets" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."users_buckets_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."users_cover_photos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."users_cover_photos_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."users_email_preferences" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."users_email_preferences_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."users_followers" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."users_followers_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."users_referred" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."users_referred_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."vid_extensions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."vid_extensions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."what_inspired_you_to_sign_up" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."what_inspired_you_to_sign_up_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."action_plan_tasks"
    ADD CONSTRAINT "action_plan_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_email"
    ADD CONSTRAINT "admin_email_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_icons"
    ADD CONSTRAINT "app_icons_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bucket_list_filter"
    ADD CONSTRAINT "bucket_list_filter_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."buckets_categories"
    ADD CONSTRAINT "buckets_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."buckets_comments"
    ADD CONSTRAINT "buckets_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."buckets_explore_buckets"
    ADD CONSTRAINT "buckets_explore_buckets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."buckets_partner_experts"
    ADD CONSTRAINT "buckets_partner_experts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."buckets"
    ADD CONSTRAINT "buckets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."buckets_story_board_items"
    ADD CONSTRAINT "buckets_story_board_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."buckets_tags"
    ADD CONSTRAINT "buckets_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."category_os"
    ADD CONSTRAINT "category_os_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."collaborators"
    ADD CONSTRAINT "collaborators_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."colours"
    ADD CONSTRAINT "colours_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversations_users"
    ADD CONSTRAINT "conversations_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."default_goals"
    ADD CONSTRAINT "default_goals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."desc_placeholder_os"
    ADD CONSTRAINT "desc_placeholder_os_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."do_you_already_have_a_bucket_list"
    ADD CONSTRAINT "do_you_already_have_a_bucket_list_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."doc_extensions"
    ADD CONSTRAINT "doc_extensions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."dummies"
    ADD CONSTRAINT "dummies_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."email_logs"
    ADD CONSTRAINT "email_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."email_type"
    ADD CONSTRAINT "email_type_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."errors"
    ADD CONSTRAINT "errors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feed_comments"
    ADD CONSTRAINT "feed_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."file_type"
    ADD CONSTRAINT "file_type_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."follow"
    ADD CONSTRAINT "follow_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."follows"
    ADD CONSTRAINT "follows_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."handle_new_auth_user_debug"
    ADD CONSTRAINT "handle_new_auth_user_debug_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."how_did_you_hear_about_us"
    ADD CONSTRAINT "how_did_you_hear_about_us_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."image_extension"
    ADD CONSTRAINT "image_extension_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."index_tab"
    ADD CONSTRAINT "index_tab_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."likes"
    ADD CONSTRAINT "likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."links"
    ADD CONSTRAINT "links_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."message_recs_os_2"
    ADD CONSTRAINT "message_recs_os_2_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."message_recs_os"
    ADD CONSTRAINT "message_recs_os_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."novels"
    ADD CONSTRAINT "novels_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."onboarding_qna"
    ADD CONSTRAINT "onboarding_qna_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."os_buckets"
    ADD CONSTRAINT "os_buckets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pages"
    ADD CONSTRAINT "pages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."partner_experts_pictures"
    ADD CONSTRAINT "partner_experts_pictures_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."partner_experts"
    ADD CONSTRAINT "partner_experts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."popup_goal_tabs"
    ADD CONSTRAINT "popup_goal_tabs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_type_os"
    ADD CONSTRAINT "post_type_os_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."posts_comments"
    ADD CONSTRAINT "posts_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."posts_likes"
    ADD CONSTRAINT "posts_likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."posts_multi_goals"
    ADD CONSTRAINT "posts_multi_goals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_buckets_categories"
    ADD CONSTRAINT "pseudos_buckets_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_buckets_comments"
    ADD CONSTRAINT "pseudos_buckets_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_buckets_explore_buckets"
    ADD CONSTRAINT "pseudos_buckets_explore_buckets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_buckets_partner_experts"
    ADD CONSTRAINT "pseudos_buckets_partner_experts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_buckets_story_board_items"
    ADD CONSTRAINT "pseudos_buckets_story_board_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_buckets_tags"
    ADD CONSTRAINT "pseudos_buckets_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_conversations_users"
    ADD CONSTRAINT "pseudos_conversations_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_partner_experts_pictures"
    ADD CONSTRAINT "pseudos_partner_experts_pictures_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_posts_comments"
    ADD CONSTRAINT "pseudos_posts_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_posts_likes"
    ADD CONSTRAINT "pseudos_posts_likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_posts_multi_goals"
    ADD CONSTRAINT "pseudos_posts_multi_goals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_recommendations_buckets"
    ADD CONSTRAINT "pseudos_recommendations_buckets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_referrals_joined_users"
    ADD CONSTRAINT "pseudos_referrals_joined_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_story_board_items_links"
    ADD CONSTRAINT "pseudos_story_board_items_links_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_users_buckets"
    ADD CONSTRAINT "pseudos_users_buckets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_users_cover_photos"
    ADD CONSTRAINT "pseudos_users_cover_photos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_users_email_preferences"
    ADD CONSTRAINT "pseudos_users_email_preferences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_users_followers"
    ADD CONSTRAINT "pseudos_users_followers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pseudos_users_referred"
    ADD CONSTRAINT "pseudos_users_referred_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."range_os"
    ADD CONSTRAINT "range_os_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recommendations_buckets"
    ADD CONSTRAINT "recommendations_buckets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recommendations"
    ADD CONSTRAINT "recommendations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referrals_joined_users"
    ADD CONSTRAINT "referrals_joined_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sample_file_csv"
    ADD CONSTRAINT "sample_file_csv_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."scheduled_tasks"
    ADD CONSTRAINT "scheduled_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."status_bar"
    ADD CONSTRAINT "status_bar_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."story_board_items_links"
    ADD CONSTRAINT "story_board_items_links_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."story_board_items"
    ADD CONSTRAINT "story_board_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."story_board_qs"
    ADD CONSTRAINT "story_board_qs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sub_pointers"
    ADD CONSTRAINT "sub_pointers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscription_plan"
    ADD CONSTRAINT "subscription_plan_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."testimonials"
    ADD CONSTRAINT "testimonials_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tests"
    ADD CONSTRAINT "tests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."title_placeholder_os"
    ADD CONSTRAINT "title_placeholder_os_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."type_of_notifications"
    ADD CONSTRAINT "type_of_notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."collaborators"
    ADD CONSTRAINT "unique_user_bucket" UNIQUE ("related_user_id", "related_bucket_id");



ALTER TABLE ONLY "public"."user_metadata_sync"
    ADD CONSTRAINT "user_metadata_sync_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_sync_queue"
    ADD CONSTRAINT "user_sync_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_auth_user_id_key" UNIQUE ("auth_user_id");



ALTER TABLE ONLY "public"."users_buckets"
    ADD CONSTRAINT "users_buckets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users_cover_photos"
    ADD CONSTRAINT "users_cover_photos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."users_email_preferences"
    ADD CONSTRAINT "users_email_preferences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users_email_preferences"
    ADD CONSTRAINT "users_email_preferences_unique" UNIQUE ("user_id", "email_type");



ALTER TABLE ONLY "public"."users_followers"
    ADD CONSTRAINT "users_followers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users_referred"
    ADD CONSTRAINT "users_referred_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vid_extensions"
    ADD CONSTRAINT "vid_extensions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."what_inspired_you_to_sign_up"
    ADD CONSTRAINT "what_inspired_you_to_sign_up_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_buckets_related_user_id" ON "public"."buckets" USING "btree" ("related_user_id");



CREATE INDEX "idx_email_logs_inserted_at" ON "public"."email_logs" USING "btree" ("inserted_at");



CREATE INDEX "idx_email_logs_to_email" ON "public"."email_logs" USING "btree" ("to_email");



CREATE INDEX "idx_novels_sort_factor" ON "public"."novels" USING "btree" ("sort_factor");



CREATE INDEX "idx_public_users_lower_email" ON "public"."users" USING "btree" ("lower"("email"));



CREATE INDEX "idx_scheduled_tasks_bucket" ON "public"."scheduled_tasks" USING "btree" ("bucket_id");



CREATE INDEX "idx_scheduled_tasks_due" ON "public"."scheduled_tasks" USING "btree" ("run_at") WHERE ("is_executed" = false);



CREATE INDEX "idx_scheduled_tasks_user" ON "public"."scheduled_tasks" USING "btree" ("user_id");



CREATE INDEX "idx_user_metadata_sync_auth_user_id" ON "public"."user_metadata_sync" USING "btree" ("auth_user_id");



CREATE INDEX "idx_user_metadata_sync_status" ON "public"."user_metadata_sync" USING "btree" ("status");



CREATE INDEX "idx_users_buckets_user_sort" ON "public"."users_buckets" USING "btree" ("user_id", "sort_factor");



CREATE UNIQUE INDEX "idx_users_email_lower_unique" ON "public"."users" USING "btree" ("lower"("email"));



CREATE INDEX "idx_users_lower_email" ON "public"."users" USING "btree" ("lower"("email"));



CREATE INDEX "idx_users_lower_slug" ON "public"."users" USING "btree" ("lower"("slug"));



CREATE UNIQUE INDEX "idx_users_slug_unique" ON "public"."users" USING "btree" ("slug") WHERE ("slug" IS NOT NULL);



CREATE INDEX "posts_bucket_created_at_id_desc_idx" ON "public"."posts" USING "btree" ("related_bucket_id", "created_at" DESC, "id" DESC);



CREATE INDEX "posts_created_at_id_desc_idx" ON "public"."posts" USING "btree" ("created_at" DESC, "id" DESC);



CREATE INDEX "posts_multi_goals_post_id_idx" ON "public"."posts_multi_goals" USING "btree" ("post_id");



CREATE OR REPLACE TRIGGER "generate_user_slug_trg" BEFORE INSERT ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."generate_user_slug"();



CREATE OR REPLACE TRIGGER "trg_handle_signup_merged_on_public_users" AFTER INSERT ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."handle_signup_merged"();



ALTER TABLE ONLY "public"."action_plan_tasks"
    ADD CONSTRAINT "action_plan_tasks_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."action_plan_tasks"
    ADD CONSTRAINT "action_plan_tasks_related_bucket_id_fkey" FOREIGN KEY ("related_bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buckets_categories"
    ADD CONSTRAINT "buckets_categories_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buckets_categories"
    ADD CONSTRAINT "buckets_categories_category_fkey" FOREIGN KEY ("category") REFERENCES "public"."category_os"("id");



ALTER TABLE ONLY "public"."buckets"
    ADD CONSTRAINT "buckets_category_fkey" FOREIGN KEY ("category") REFERENCES "public"."category_os"("id");



ALTER TABLE ONLY "public"."buckets_comments"
    ADD CONSTRAINT "buckets_comments_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buckets_comments"
    ADD CONSTRAINT "buckets_comments_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buckets"
    ADD CONSTRAINT "buckets_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buckets_explore_buckets"
    ADD CONSTRAINT "buckets_explore_buckets_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buckets_explore_buckets"
    ADD CONSTRAINT "buckets_explore_buckets_explore_bucket_id_fkey" FOREIGN KEY ("explore_bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buckets_partner_experts"
    ADD CONSTRAINT "buckets_partner_experts_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buckets_partner_experts"
    ADD CONSTRAINT "buckets_partner_experts_partner_expert_id_fkey" FOREIGN KEY ("partner_expert_id") REFERENCES "public"."partner_experts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buckets"
    ADD CONSTRAINT "buckets_related_user_id_fkey" FOREIGN KEY ("related_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buckets_story_board_items"
    ADD CONSTRAINT "buckets_story_board_items_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buckets_story_board_items"
    ADD CONSTRAINT "buckets_story_board_items_story_board_item_id_fkey" FOREIGN KEY ("story_board_item_id") REFERENCES "public"."story_board_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buckets_tags"
    ADD CONSTRAINT "buckets_tags_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."collaborators"
    ADD CONSTRAINT "collaborators_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."collaborators"
    ADD CONSTRAINT "collaborators_related_bucket_id_fkey" FOREIGN KEY ("related_bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."collaborators"
    ADD CONSTRAINT "collaborators_related_user_id_fkey" FOREIGN KEY ("related_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_related_bucket_id_fkey" FOREIGN KEY ("related_bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_related_bucket_id_fkey" FOREIGN KEY ("related_bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations_users"
    ADD CONSTRAINT "conversations_users_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations_users"
    ADD CONSTRAINT "conversations_users_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."dummies"
    ADD CONSTRAINT "dummies_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."dummies"
    ADD CONSTRAINT "dummies_post_maker_id_fkey" FOREIGN KEY ("post_maker_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."errors"
    ADD CONSTRAINT "errors_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."errors"
    ADD CONSTRAINT "errors_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."feed_comments"
    ADD CONSTRAINT "feed_comments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."feed_comments"
    ADD CONSTRAINT "feed_comments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."follows"
    ADD CONSTRAINT "follows_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."follows"
    ADD CONSTRAINT "follows_followed_by_id_fkey" FOREIGN KEY ("followed_by_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."follows"
    ADD CONSTRAINT "follows_following_id_fkey" FOREIGN KEY ("following_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."likes"
    ADD CONSTRAINT "likes_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."likes"
    ADD CONSTRAINT "likes_on_bucket_id_fkey" FOREIGN KEY ("on_bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."links"
    ADD CONSTRAINT "links_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."links"
    ADD CONSTRAINT "links_related_bucket_id_fkey" FOREIGN KEY ("related_bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_receiver_id_fkey" FOREIGN KEY ("receiver_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_referenced_bucket_id_fkey" FOREIGN KEY ("referenced_bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_related_conversation_id_fkey" FOREIGN KEY ("related_conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_referenced_bucket_id_fkey" FOREIGN KEY ("referenced_bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_referenced_post_id_fkey" FOREIGN KEY ("referenced_post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_type_fkey" FOREIGN KEY ("type") REFERENCES "public"."type_of_notifications"("id");



ALTER TABLE ONLY "public"."onboarding_qna"
    ADD CONSTRAINT "onboarding_qna_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."onboarding_qna"
    ADD CONSTRAINT "onboarding_qna_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."partner_experts"
    ADD CONSTRAINT "partner_experts_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."partner_experts_pictures"
    ADD CONSTRAINT "partner_experts_pictures_partner_expert_id_fkey" FOREIGN KEY ("partner_expert_id") REFERENCES "public"."partner_experts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."partner_experts"
    ADD CONSTRAINT "partner_experts_related_user_id_fkey" FOREIGN KEY ("related_user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."posts_comments"
    ADD CONSTRAINT "posts_comments_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts_comments"
    ADD CONSTRAINT "posts_comments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts_likes"
    ADD CONSTRAINT "posts_likes_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts_likes"
    ADD CONSTRAINT "posts_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts_multi_goals"
    ADD CONSTRAINT "posts_multi_goals_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_related_bucket_id_fkey" FOREIGN KEY ("related_bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_related_user_id_fkey" FOREIGN KEY ("related_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_type_fkey" FOREIGN KEY ("type") REFERENCES "public"."post_type_os"("id");



ALTER TABLE ONLY "public"."pseudos_buckets_categories"
    ADD CONSTRAINT "pseudos_buckets_categories_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_buckets_comments"
    ADD CONSTRAINT "pseudos_buckets_comments_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_buckets_comments"
    ADD CONSTRAINT "pseudos_buckets_comments_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_buckets_explore_buckets"
    ADD CONSTRAINT "pseudos_buckets_explore_buckets_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_buckets_partner_experts"
    ADD CONSTRAINT "pseudos_buckets_partner_experts_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_buckets_story_board_items"
    ADD CONSTRAINT "pseudos_buckets_story_board_items_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_buckets_tags"
    ADD CONSTRAINT "pseudos_buckets_tags_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_conversations_users"
    ADD CONSTRAINT "pseudos_conversations_users_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_conversations_users"
    ADD CONSTRAINT "pseudos_conversations_users_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_partner_experts_pictures"
    ADD CONSTRAINT "pseudos_partner_experts_pictures_partner_expert_id_fkey" FOREIGN KEY ("partner_expert_id") REFERENCES "public"."partner_experts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_posts_comments"
    ADD CONSTRAINT "pseudos_posts_comments_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_posts_comments"
    ADD CONSTRAINT "pseudos_posts_comments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_posts_likes"
    ADD CONSTRAINT "pseudos_posts_likes_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_posts_multi_goals"
    ADD CONSTRAINT "pseudos_posts_multi_goals_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_recommendations_buckets"
    ADD CONSTRAINT "pseudos_recommendations_buckets_recommendation_id_fkey" FOREIGN KEY ("recommendation_id") REFERENCES "public"."recommendations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_referrals_joined_users"
    ADD CONSTRAINT "pseudos_referrals_joined_users_referral_id_fkey" FOREIGN KEY ("referral_id") REFERENCES "public"."referrals"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_story_board_items_links"
    ADD CONSTRAINT "pseudos_story_board_items_links_story_board_item_id_fkey" FOREIGN KEY ("story_board_item_id") REFERENCES "public"."story_board_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_users_buckets"
    ADD CONSTRAINT "pseudos_users_buckets_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_users_buckets"
    ADD CONSTRAINT "pseudos_users_buckets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_users_cover_photos"
    ADD CONSTRAINT "pseudos_users_cover_photos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_users_email_preferences"
    ADD CONSTRAINT "pseudos_users_email_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_users_followers"
    ADD CONSTRAINT "pseudos_users_followers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_users_referred"
    ADD CONSTRAINT "pseudos_users_referred_referral_id_fkey" FOREIGN KEY ("referral_id") REFERENCES "public"."referrals"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_users_referred"
    ADD CONSTRAINT "pseudos_users_referred_referred_id_fkey" FOREIGN KEY ("referred_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pseudos_users_referred"
    ADD CONSTRAINT "pseudos_users_referred_referrer_id_fkey" FOREIGN KEY ("referrer_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recommendations_buckets"
    ADD CONSTRAINT "recommendations_buckets_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recommendations_buckets"
    ADD CONSTRAINT "recommendations_buckets_recommendation_id_fkey" FOREIGN KEY ("recommendation_id") REFERENCES "public"."recommendations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recommendations"
    ADD CONSTRAINT "recommendations_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recommendations"
    ADD CONSTRAINT "recommendations_related_user_id_fkey" FOREIGN KEY ("related_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referrals_joined_users"
    ADD CONSTRAINT "referrals_joined_users_referral_id_fkey" FOREIGN KEY ("referral_id") REFERENCES "public"."referrals"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referrals_joined_users"
    ADD CONSTRAINT "referrals_joined_users_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_related_user_id_fkey" FOREIGN KEY ("related_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."scheduled_tasks"
    ADD CONSTRAINT "scheduled_tasks_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."scheduled_tasks"
    ADD CONSTRAINT "scheduled_tasks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."story_board_items"
    ADD CONSTRAINT "story_board_items_colour_fkey" FOREIGN KEY ("colour") REFERENCES "public"."colours"("id");



ALTER TABLE ONLY "public"."story_board_items"
    ADD CONSTRAINT "story_board_items_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."story_board_items_links"
    ADD CONSTRAINT "story_board_items_links_link_id_fkey" FOREIGN KEY ("link_id") REFERENCES "public"."links"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."story_board_items_links"
    ADD CONSTRAINT "story_board_items_links_story_board_item_id_fkey" FOREIGN KEY ("story_board_item_id") REFERENCES "public"."story_board_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."story_board_items"
    ADD CONSTRAINT "story_board_items_question_fkey" FOREIGN KEY ("question") REFERENCES "public"."story_board_qs"("id");



ALTER TABLE ONLY "public"."story_board_items"
    ADD CONSTRAINT "story_board_items_related_bucket_id_fkey" FOREIGN KEY ("related_bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tests"
    ADD CONSTRAINT "tests_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_auth_user_id_fkey" FOREIGN KEY ("auth_user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."users_buckets"
    ADD CONSTRAINT "users_buckets_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "public"."buckets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users_buckets"
    ADD CONSTRAINT "users_buckets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users_cover_photos"
    ADD CONSTRAINT "users_cover_photos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users_email_preferences"
    ADD CONSTRAINT "users_email_preferences_email_type_fkey" FOREIGN KEY ("email_type") REFERENCES "public"."email_type"("id");



ALTER TABLE ONLY "public"."users_email_preferences"
    ADD CONSTRAINT "users_email_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users_followers"
    ADD CONSTRAINT "users_followers_follower_id_fkey" FOREIGN KEY ("follower_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users_followers"
    ADD CONSTRAINT "users_followers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users_referred"
    ADD CONSTRAINT "users_referred_referral_id_fkey" FOREIGN KEY ("referral_id") REFERENCES "public"."referrals"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users_referred"
    ADD CONSTRAINT "users_referred_referred_id_fkey" FOREIGN KEY ("referred_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users_referred"
    ADD CONSTRAINT "users_referred_referrer_id_fkey" FOREIGN KEY ("referrer_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



CREATE POLICY "service role full access" ON "public"."users" TO "service_role" USING (true) WITH CHECK (true);





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."action_plan_tasks";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."admin_email";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."app_icons";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."bucket_list_filter";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."buckets";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."buckets_categories";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."buckets_comments";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."buckets_explore_buckets";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."buckets_partner_experts";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."buckets_story_board_items";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."buckets_tags";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."category_os";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."collaborators";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."colours";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."comments";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."conversations";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."conversations_users";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."default_goals";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."desc_placeholder_os";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."do_you_already_have_a_bucket_list";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."doc_extensions";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."dummies";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."email_type";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."errors";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."feed_comments";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."file_type";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."follow";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."follows";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."how_did_you_hear_about_us";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."image_extension";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."index_tab";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."likes";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."links";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."message_recs_os";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."message_recs_os_2";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."messages";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."notifications";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."novels";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."onboarding_qna";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."os_buckets";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."pages";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."partner_experts";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."partner_experts_pictures";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."popup_goal_tabs";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."post_type_os";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."posts";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."posts_comments";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."posts_likes";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."posts_multi_goals";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."range_os";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."recommendations";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."recommendations_buckets";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."referrals";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."referrals_joined_users";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."sample_file_csv";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."status_bar";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."story_board_items";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."story_board_items_links";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."story_board_qs";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."sub_pointers";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."subscription_plan";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."testimonials";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."tests";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."title_placeholder_os";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."type_of_notifications";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."users";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."users_buckets";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."users_cover_photos";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."users_email_preferences";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."users_followers";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."users_referred";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."vid_extensions";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."what_inspired_you_to_sign_up";






GRANT USAGE ON SCHEMA "public" TO "service_role";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";

















































































































































































GRANT ALL ON TABLE "public"."collaborators" TO "service_role";
GRANT ALL ON TABLE "public"."collaborators" TO "anon";
GRANT ALL ON TABLE "public"."collaborators" TO "authenticated";



GRANT ALL ON FUNCTION "public"."add_collaborators_to_bucket"("p_bucket_id" bigint, "p_user_ids" bigint[]) TO "anon";
GRANT ALL ON FUNCTION "public"."add_collaborators_to_bucket"("p_bucket_id" bigint, "p_user_ids" bigint[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_collaborators_to_bucket"("p_bucket_id" bigint, "p_user_ids" bigint[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_collaborators_to_bucket"("p_bucket_id" bigint, "p_user_ids" bigint[], "p_sender_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."add_collaborators_to_bucket"("p_bucket_id" bigint, "p_user_ids" bigint[], "p_sender_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_collaborators_to_bucket"("p_bucket_id" bigint, "p_user_ids" bigint[], "p_sender_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."check_or_create_conversation"("p_user1" bigint, "p_user2" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."check_or_create_conversation"("p_user1" bigint, "p_user2" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_or_create_conversation"("p_user1" bigint, "p_user2" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."clone_and_add_bucket"("p_original_bucket_id" bigint, "p_current_user_id" bigint, "p_mark_completed" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."clone_and_add_bucket"("p_original_bucket_id" bigint, "p_current_user_id" bigint, "p_mark_completed" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."clone_and_add_bucket"("p_original_bucket_id" bigint, "p_current_user_id" bigint, "p_mark_completed" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."exec_sql"("sql" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."exec_sql"("sql" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."exec_sql"("sql" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_slug_from_email"("p_email" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_slug_from_email"("p_email" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_slug_from_email"("p_email" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_user_slug"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_user_slug"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_user_slug"() TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "service_role";
GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";



GRANT ALL ON FUNCTION "public"."get_bucket_approved_collaborator_users"("p_bucket_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_bucket_approved_collaborator_users"("p_bucket_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_bucket_approved_collaborator_users"("p_bucket_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_bucket_collaborator_users"("p_bucket_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_bucket_collaborator_users"("p_bucket_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_bucket_collaborator_users"("p_bucket_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_bucket_partner_experts"("p_bucket_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_bucket_partner_experts"("p_bucket_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_bucket_partner_experts"("p_bucket_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_buckets_sorted_for_user"("p_user_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_buckets_sorted_for_user"("p_user_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_buckets_sorted_for_user"("p_user_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_collaborators_by_bucket"("p_bucket_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_collaborators_by_bucket"("p_bucket_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_collaborators_by_bucket"("p_bucket_id" bigint) TO "service_role";



GRANT ALL ON TABLE "public"."buckets" TO "service_role";
GRANT ALL ON TABLE "public"."buckets" TO "anon";
GRANT ALL ON TABLE "public"."buckets" TO "authenticated";



GRANT ALL ON TABLE "public"."posts" TO "service_role";
GRANT ALL ON TABLE "public"."posts" TO "anon";
GRANT ALL ON TABLE "public"."posts" TO "authenticated";



GRANT ALL ON FUNCTION "public"."get_post_by_id"("p_post_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_post_by_id"("p_post_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_post_by_id"("p_post_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_posts_feed"("p_current_user_id" bigint, "p_limit" integer, "p_before_id" bigint, "p_related_bucket_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_posts_feed"("p_current_user_id" bigint, "p_limit" integer, "p_before_id" bigint, "p_related_bucket_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_posts_feed"("p_current_user_id" bigint, "p_limit" integer, "p_before_id" bigint, "p_related_bucket_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_random_users"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_random_users"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_random_users"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_random_users"("p_current_user_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_random_users"("p_current_user_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_random_users"("p_current_user_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_recommended_users"("p_current_user_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_recommended_users"("p_current_user_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_recommended_users"("p_current_user_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_storyboard_and_links"("p_bucket_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_storyboard_and_links"("p_bucket_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_storyboard_and_links"("p_bucket_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_conversations"("p_user_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_conversations"("p_user_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_conversations"("p_user_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_notifications"("p_user_id" bigint, "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_notifications"("p_user_id" bigint, "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_notifications"("p_user_id" bigint, "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_partner_experts"("p_user_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_partner_experts"("p_user_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_partner_experts"("p_user_id" bigint) TO "service_role";



REVOKE ALL ON FUNCTION "public"."handle_signup_merged"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."handle_signup_merged"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_signup_onboarding"("p_user_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."handle_signup_onboarding"("p_user_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_signup_onboarding"("p_user_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."match_buckets_by_title_simple"("p_bucket_id" bigint, "p_current_user_id" bigint, "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."match_buckets_by_title_simple"("p_bucket_id" bigint, "p_current_user_id" bigint, "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."match_buckets_by_title_simple"("p_bucket_id" bigint, "p_current_user_id" bigint, "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."match_buckets_for_user"("p_current_user_id" bigint, "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."match_buckets_for_user"("p_current_user_id" bigint, "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."match_buckets_for_user"("p_current_user_id" bigint, "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."match_buckets_simple"("p_bucket_id" bigint, "p_current_user_id" bigint, "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."match_buckets_simple"("p_bucket_id" bigint, "p_current_user_id" bigint, "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."match_buckets_simple"("p_bucket_id" bigint, "p_current_user_id" bigint, "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."reorder_novels_values"("new_order" bigint[]) TO "anon";
GRANT ALL ON FUNCTION "public"."reorder_novels_values"("new_order" bigint[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."reorder_novels_values"("new_order" bigint[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."search_buckets_by_title"("p_search" "text", "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."search_buckets_by_title"("p_search" "text", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_buckets_by_title"("p_search" "text", "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."search_posts_feed"("p_current_user_id" bigint, "p_search_string" "text", "p_limit" integer, "p_before_id" bigint, "p_related_bucket_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."search_posts_feed"("p_current_user_id" bigint, "p_search_string" "text", "p_limit" integer, "p_before_id" bigint, "p_related_bucket_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_posts_feed"("p_current_user_id" bigint, "p_search_string" "text", "p_limit" integer, "p_before_id" bigint, "p_related_bucket_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."search_users_by_full_name"("p_search_string" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."search_users_by_full_name"("p_search_string" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_users_by_full_name"("p_search_string" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."start_bucket_email_flow"("p_user_id" bigint, "p_bucket_id" bigint, "p_base_time" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."start_bucket_email_flow"("p_user_id" bigint, "p_bucket_id" bigint, "p_base_time" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."start_bucket_email_flow"("p_user_id" bigint, "p_bucket_id" bigint, "p_base_time" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."start_or_continue_conversation"("p_sender" bigint, "p_receiver" bigint, "p_body" "text", "p_bucket_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."start_or_continue_conversation"("p_sender" bigint, "p_receiver" bigint, "p_body" "text", "p_bucket_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."start_or_continue_conversation"("p_sender" bigint, "p_receiver" bigint, "p_body" "text", "p_bucket_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_user_email_preferences"("p_user_id" bigint, "p_email_type_ids" bigint[]) TO "anon";
GRANT ALL ON FUNCTION "public"."sync_user_email_preferences"("p_user_id" bigint, "p_email_type_ids" bigint[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_user_email_preferences"("p_user_id" bigint, "p_email_type_ids" bigint[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_novel_order"("id_list" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_novel_order"("id_list" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_novel_order"("id_list" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_story_board_items_order_by_bucket"("id_list" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_story_board_items_order_by_bucket"("id_list" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_story_board_items_order_by_bucket"("id_list" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_users_buckets_order"("id_list" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_users_buckets_order"("id_list" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_users_buckets_order"("id_list" "text") TO "service_role";
























GRANT ALL ON TABLE "public"."action_plan_tasks" TO "service_role";
GRANT ALL ON TABLE "public"."action_plan_tasks" TO "anon";
GRANT ALL ON TABLE "public"."action_plan_tasks" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."action_plan_tasks_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."action_plan_tasks_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."action_plan_tasks_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."admin_email" TO "service_role";
GRANT ALL ON TABLE "public"."admin_email" TO "anon";
GRANT ALL ON TABLE "public"."admin_email" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."admin_email_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."admin_email_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."admin_email_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."app_icons" TO "service_role";
GRANT ALL ON TABLE "public"."app_icons" TO "anon";
GRANT ALL ON TABLE "public"."app_icons" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."app_icons_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."app_icons_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."app_icons_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."bucket_list_filter" TO "service_role";
GRANT ALL ON TABLE "public"."bucket_list_filter" TO "anon";
GRANT ALL ON TABLE "public"."bucket_list_filter" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."bucket_list_filter_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."bucket_list_filter_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."bucket_list_filter_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."buckets_categories" TO "service_role";
GRANT ALL ON TABLE "public"."buckets_categories" TO "anon";
GRANT ALL ON TABLE "public"."buckets_categories" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."buckets_categories_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."buckets_categories_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."buckets_categories_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."buckets_comments" TO "service_role";
GRANT ALL ON TABLE "public"."buckets_comments" TO "anon";
GRANT ALL ON TABLE "public"."buckets_comments" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."buckets_comments_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."buckets_comments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."buckets_comments_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."buckets_explore_buckets" TO "service_role";
GRANT ALL ON TABLE "public"."buckets_explore_buckets" TO "anon";
GRANT ALL ON TABLE "public"."buckets_explore_buckets" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."buckets_explore_buckets_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."buckets_explore_buckets_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."buckets_explore_buckets_id_seq" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."buckets_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."buckets_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."buckets_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."buckets_partner_experts" TO "service_role";
GRANT ALL ON TABLE "public"."buckets_partner_experts" TO "anon";
GRANT ALL ON TABLE "public"."buckets_partner_experts" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."buckets_partner_experts_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."buckets_partner_experts_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."buckets_partner_experts_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."buckets_story_board_items" TO "service_role";
GRANT ALL ON TABLE "public"."buckets_story_board_items" TO "anon";
GRANT ALL ON TABLE "public"."buckets_story_board_items" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."buckets_story_board_items_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."buckets_story_board_items_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."buckets_story_board_items_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."buckets_tags" TO "service_role";
GRANT ALL ON TABLE "public"."buckets_tags" TO "anon";
GRANT ALL ON TABLE "public"."buckets_tags" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."buckets_tags_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."buckets_tags_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."buckets_tags_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."category_os" TO "service_role";
GRANT ALL ON TABLE "public"."category_os" TO "anon";
GRANT ALL ON TABLE "public"."category_os" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."category_os_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."category_os_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."category_os_id_seq" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."collaborators_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."collaborators_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."collaborators_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."colours" TO "service_role";
GRANT ALL ON TABLE "public"."colours" TO "anon";
GRANT ALL ON TABLE "public"."colours" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."colours_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."colours_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."colours_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."comments" TO "service_role";
GRANT ALL ON TABLE "public"."comments" TO "anon";
GRANT ALL ON TABLE "public"."comments" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."comments_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."comments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."comments_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."conversations" TO "service_role";
GRANT ALL ON TABLE "public"."conversations" TO "anon";
GRANT ALL ON TABLE "public"."conversations" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."conversations_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."conversations_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."conversations_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."conversations_users" TO "service_role";
GRANT ALL ON TABLE "public"."conversations_users" TO "anon";
GRANT ALL ON TABLE "public"."conversations_users" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."conversations_users_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."conversations_users_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."conversations_users_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."default_goals" TO "service_role";
GRANT ALL ON TABLE "public"."default_goals" TO "anon";
GRANT ALL ON TABLE "public"."default_goals" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."default_goals_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."default_goals_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."default_goals_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."desc_placeholder_os" TO "service_role";
GRANT ALL ON TABLE "public"."desc_placeholder_os" TO "anon";
GRANT ALL ON TABLE "public"."desc_placeholder_os" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."desc_placeholder_os_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."desc_placeholder_os_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."desc_placeholder_os_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."do_you_already_have_a_bucket_list" TO "service_role";
GRANT ALL ON TABLE "public"."do_you_already_have_a_bucket_list" TO "anon";
GRANT ALL ON TABLE "public"."do_you_already_have_a_bucket_list" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."do_you_already_have_a_bucket_list_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."do_you_already_have_a_bucket_list_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."do_you_already_have_a_bucket_list_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."doc_extensions" TO "service_role";
GRANT ALL ON TABLE "public"."doc_extensions" TO "anon";
GRANT ALL ON TABLE "public"."doc_extensions" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."doc_extensions_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."doc_extensions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."doc_extensions_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."dummies" TO "service_role";
GRANT ALL ON TABLE "public"."dummies" TO "anon";
GRANT ALL ON TABLE "public"."dummies" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."dummies_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."dummies_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."dummies_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."email_logs" TO "anon";
GRANT ALL ON TABLE "public"."email_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."email_logs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."email_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."email_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."email_logs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."email_type" TO "service_role";
GRANT ALL ON TABLE "public"."email_type" TO "anon";
GRANT ALL ON TABLE "public"."email_type" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."email_type_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."email_type_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."email_type_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."errors" TO "service_role";
GRANT ALL ON TABLE "public"."errors" TO "anon";
GRANT ALL ON TABLE "public"."errors" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."errors_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."errors_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."errors_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."feed_comments" TO "service_role";
GRANT ALL ON TABLE "public"."feed_comments" TO "anon";
GRANT ALL ON TABLE "public"."feed_comments" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."feed_comments_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."feed_comments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."feed_comments_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."file_type" TO "service_role";
GRANT ALL ON TABLE "public"."file_type" TO "anon";
GRANT ALL ON TABLE "public"."file_type" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."file_type_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."file_type_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."file_type_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."follow" TO "service_role";
GRANT ALL ON TABLE "public"."follow" TO "anon";
GRANT ALL ON TABLE "public"."follow" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."follow_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."follow_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."follow_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."follows" TO "service_role";
GRANT ALL ON TABLE "public"."follows" TO "anon";
GRANT ALL ON TABLE "public"."follows" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."follows_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."follows_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."follows_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."handle_new_auth_user_debug" TO "anon";
GRANT ALL ON TABLE "public"."handle_new_auth_user_debug" TO "authenticated";
GRANT ALL ON TABLE "public"."handle_new_auth_user_debug" TO "service_role";



GRANT ALL ON SEQUENCE "public"."handle_new_auth_user_debug_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."handle_new_auth_user_debug_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."handle_new_auth_user_debug_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."how_did_you_hear_about_us" TO "service_role";
GRANT ALL ON TABLE "public"."how_did_you_hear_about_us" TO "anon";
GRANT ALL ON TABLE "public"."how_did_you_hear_about_us" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."how_did_you_hear_about_us_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."how_did_you_hear_about_us_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."how_did_you_hear_about_us_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."image_extension" TO "service_role";
GRANT ALL ON TABLE "public"."image_extension" TO "anon";
GRANT ALL ON TABLE "public"."image_extension" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."image_extension_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."image_extension_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."image_extension_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."index_tab" TO "service_role";
GRANT ALL ON TABLE "public"."index_tab" TO "anon";
GRANT ALL ON TABLE "public"."index_tab" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."index_tab_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."index_tab_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."index_tab_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."likes" TO "service_role";
GRANT ALL ON TABLE "public"."likes" TO "anon";
GRANT ALL ON TABLE "public"."likes" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."likes_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."likes_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."likes_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."links" TO "service_role";
GRANT ALL ON TABLE "public"."links" TO "anon";
GRANT ALL ON TABLE "public"."links" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."links_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."links_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."links_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."message_recs_os" TO "service_role";
GRANT ALL ON TABLE "public"."message_recs_os" TO "anon";
GRANT ALL ON TABLE "public"."message_recs_os" TO "authenticated";



GRANT ALL ON TABLE "public"."message_recs_os_2" TO "service_role";
GRANT ALL ON TABLE "public"."message_recs_os_2" TO "anon";
GRANT ALL ON TABLE "public"."message_recs_os_2" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."message_recs_os_2_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."message_recs_os_2_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."message_recs_os_2_id_seq" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."message_recs_os_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."message_recs_os_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."message_recs_os_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."messages" TO "service_role";
GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."notifications" TO "service_role";
GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."novels" TO "service_role";
GRANT ALL ON TABLE "public"."novels" TO "anon";
GRANT ALL ON TABLE "public"."novels" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."novels_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."novels_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."novels_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."onboarding_qna" TO "service_role";
GRANT ALL ON TABLE "public"."onboarding_qna" TO "anon";
GRANT ALL ON TABLE "public"."onboarding_qna" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."onboarding_qna_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."onboarding_qna_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."onboarding_qna_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."os_buckets" TO "service_role";
GRANT ALL ON TABLE "public"."os_buckets" TO "anon";
GRANT ALL ON TABLE "public"."os_buckets" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."os_buckets_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."os_buckets_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."os_buckets_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pages" TO "service_role";
GRANT ALL ON TABLE "public"."pages" TO "anon";
GRANT ALL ON TABLE "public"."pages" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pages_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pages_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."partner_experts" TO "service_role";
GRANT ALL ON TABLE "public"."partner_experts" TO "anon";
GRANT ALL ON TABLE "public"."partner_experts" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."partner_experts_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."partner_experts_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."partner_experts_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."partner_experts_pictures" TO "service_role";
GRANT ALL ON TABLE "public"."partner_experts_pictures" TO "anon";
GRANT ALL ON TABLE "public"."partner_experts_pictures" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."partner_experts_pictures_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."partner_experts_pictures_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."partner_experts_pictures_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."popup_goal_tabs" TO "service_role";
GRANT ALL ON TABLE "public"."popup_goal_tabs" TO "anon";
GRANT ALL ON TABLE "public"."popup_goal_tabs" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."popup_goal_tabs_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."popup_goal_tabs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."popup_goal_tabs_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."post_type_os" TO "service_role";
GRANT ALL ON TABLE "public"."post_type_os" TO "anon";
GRANT ALL ON TABLE "public"."post_type_os" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."post_type_os_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."post_type_os_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."post_type_os_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."posts_comments" TO "service_role";
GRANT ALL ON TABLE "public"."posts_comments" TO "anon";
GRANT ALL ON TABLE "public"."posts_comments" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."posts_comments_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."posts_comments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."posts_comments_id_seq" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."posts_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."posts_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."posts_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."posts_likes" TO "service_role";
GRANT ALL ON TABLE "public"."posts_likes" TO "anon";
GRANT ALL ON TABLE "public"."posts_likes" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."posts_likes_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."posts_likes_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."posts_likes_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."posts_multi_goals" TO "service_role";
GRANT ALL ON TABLE "public"."posts_multi_goals" TO "anon";
GRANT ALL ON TABLE "public"."posts_multi_goals" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."posts_multi_goals_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."posts_multi_goals_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."posts_multi_goals_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_buckets_categories" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_buckets_categories" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_buckets_categories" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_buckets_categories_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_buckets_categories_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_buckets_categories_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_buckets_comments" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_buckets_comments" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_buckets_comments" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_buckets_comments_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_buckets_comments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_buckets_comments_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_buckets_explore_buckets" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_buckets_explore_buckets" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_buckets_explore_buckets" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_buckets_explore_buckets_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_buckets_explore_buckets_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_buckets_explore_buckets_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_buckets_partner_experts" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_buckets_partner_experts" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_buckets_partner_experts" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_buckets_partner_experts_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_buckets_partner_experts_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_buckets_partner_experts_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_buckets_story_board_items" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_buckets_story_board_items" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_buckets_story_board_items" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_buckets_story_board_items_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_buckets_story_board_items_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_buckets_story_board_items_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_buckets_tags" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_buckets_tags" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_buckets_tags" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_buckets_tags_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_buckets_tags_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_buckets_tags_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_conversations_users" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_conversations_users" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_conversations_users" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_conversations_users_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_conversations_users_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_conversations_users_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_partner_experts_pictures" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_partner_experts_pictures" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_partner_experts_pictures" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_partner_experts_pictures_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_partner_experts_pictures_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_partner_experts_pictures_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_posts_comments" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_posts_comments" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_posts_comments" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_posts_comments_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_posts_comments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_posts_comments_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_posts_likes" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_posts_likes" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_posts_likes" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_posts_likes_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_posts_likes_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_posts_likes_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_posts_multi_goals" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_posts_multi_goals" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_posts_multi_goals" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_posts_multi_goals_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_posts_multi_goals_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_posts_multi_goals_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_recommendations_buckets" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_recommendations_buckets" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_recommendations_buckets" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_recommendations_buckets_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_recommendations_buckets_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_recommendations_buckets_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_referrals_joined_users" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_referrals_joined_users" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_referrals_joined_users" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_referrals_joined_users_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_referrals_joined_users_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_referrals_joined_users_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_story_board_items_links" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_story_board_items_links" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_story_board_items_links" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_story_board_items_links_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_story_board_items_links_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_story_board_items_links_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_users_buckets" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_users_buckets" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_users_buckets" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_users_buckets_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_users_buckets_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_users_buckets_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_users_cover_photos" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_users_cover_photos" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_users_cover_photos" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_users_cover_photos_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_users_cover_photos_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_users_cover_photos_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_users_email_preferences" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_users_email_preferences" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_users_email_preferences" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_users_email_preferences_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_users_email_preferences_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_users_email_preferences_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_users_followers" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_users_followers" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_users_followers" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_users_followers_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_users_followers_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_users_followers_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."pseudos_users_referred" TO "service_role";
GRANT ALL ON TABLE "public"."pseudos_users_referred" TO "anon";
GRANT ALL ON TABLE "public"."pseudos_users_referred" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."pseudos_users_referred_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."pseudos_users_referred_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."pseudos_users_referred_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."range_os" TO "service_role";
GRANT ALL ON TABLE "public"."range_os" TO "anon";
GRANT ALL ON TABLE "public"."range_os" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."range_os_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."range_os_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."range_os_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."recommendations" TO "service_role";
GRANT ALL ON TABLE "public"."recommendations" TO "anon";
GRANT ALL ON TABLE "public"."recommendations" TO "authenticated";



GRANT ALL ON TABLE "public"."recommendations_buckets" TO "service_role";
GRANT ALL ON TABLE "public"."recommendations_buckets" TO "anon";
GRANT ALL ON TABLE "public"."recommendations_buckets" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."recommendations_buckets_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."recommendations_buckets_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."recommendations_buckets_id_seq" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."recommendations_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."recommendations_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."recommendations_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."referrals" TO "service_role";
GRANT ALL ON TABLE "public"."referrals" TO "anon";
GRANT ALL ON TABLE "public"."referrals" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."referrals_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."referrals_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."referrals_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."referrals_joined_users" TO "service_role";
GRANT ALL ON TABLE "public"."referrals_joined_users" TO "anon";
GRANT ALL ON TABLE "public"."referrals_joined_users" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."referrals_joined_users_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."referrals_joined_users_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."referrals_joined_users_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."sample_file_csv" TO "service_role";
GRANT ALL ON TABLE "public"."sample_file_csv" TO "anon";
GRANT ALL ON TABLE "public"."sample_file_csv" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."sample_file_csv_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."sample_file_csv_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."sample_file_csv_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."scheduled_tasks" TO "anon";
GRANT ALL ON TABLE "public"."scheduled_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."scheduled_tasks" TO "service_role";



GRANT ALL ON SEQUENCE "public"."scheduled_tasks_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."scheduled_tasks_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."scheduled_tasks_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."status_bar" TO "service_role";
GRANT ALL ON TABLE "public"."status_bar" TO "anon";
GRANT ALL ON TABLE "public"."status_bar" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."status_bar_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."status_bar_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."status_bar_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."story_board_items" TO "service_role";
GRANT ALL ON TABLE "public"."story_board_items" TO "anon";
GRANT ALL ON TABLE "public"."story_board_items" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."story_board_items_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."story_board_items_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."story_board_items_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."story_board_items_links" TO "service_role";
GRANT ALL ON TABLE "public"."story_board_items_links" TO "anon";
GRANT ALL ON TABLE "public"."story_board_items_links" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."story_board_items_links_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."story_board_items_links_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."story_board_items_links_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."story_board_qs" TO "service_role";
GRANT ALL ON TABLE "public"."story_board_qs" TO "anon";
GRANT ALL ON TABLE "public"."story_board_qs" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."story_board_qs_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."story_board_qs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."story_board_qs_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."sub_pointers" TO "service_role";
GRANT ALL ON TABLE "public"."sub_pointers" TO "anon";
GRANT ALL ON TABLE "public"."sub_pointers" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."sub_pointers_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."sub_pointers_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."sub_pointers_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."subscription_plan" TO "service_role";
GRANT ALL ON TABLE "public"."subscription_plan" TO "anon";
GRANT ALL ON TABLE "public"."subscription_plan" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."subscription_plan_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."subscription_plan_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."subscription_plan_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."testimonials" TO "service_role";
GRANT ALL ON TABLE "public"."testimonials" TO "anon";
GRANT ALL ON TABLE "public"."testimonials" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."testimonials_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."testimonials_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."testimonials_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."tests" TO "service_role";
GRANT ALL ON TABLE "public"."tests" TO "anon";
GRANT ALL ON TABLE "public"."tests" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."tests_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."tests_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tests_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."title_placeholder_os" TO "service_role";
GRANT ALL ON TABLE "public"."title_placeholder_os" TO "anon";
GRANT ALL ON TABLE "public"."title_placeholder_os" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."title_placeholder_os_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."title_placeholder_os_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."title_placeholder_os_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."type_of_notifications" TO "service_role";
GRANT ALL ON TABLE "public"."type_of_notifications" TO "anon";
GRANT ALL ON TABLE "public"."type_of_notifications" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."type_of_notifications_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."type_of_notifications_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."type_of_notifications_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."user_metadata_sync" TO "anon";
GRANT ALL ON TABLE "public"."user_metadata_sync" TO "authenticated";
GRANT ALL ON TABLE "public"."user_metadata_sync" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_metadata_sync_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_metadata_sync_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_metadata_sync_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."user_sync_queue" TO "anon";
GRANT ALL ON TABLE "public"."user_sync_queue" TO "authenticated";
GRANT ALL ON TABLE "public"."user_sync_queue" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_sync_queue_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_sync_queue_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_sync_queue_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."users_buckets" TO "service_role";
GRANT ALL ON TABLE "public"."users_buckets" TO "anon";
GRANT ALL ON TABLE "public"."users_buckets" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."users_buckets_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."users_buckets_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."users_buckets_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."users_cover_photos" TO "service_role";
GRANT ALL ON TABLE "public"."users_cover_photos" TO "anon";
GRANT ALL ON TABLE "public"."users_cover_photos" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."users_cover_photos_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."users_cover_photos_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."users_cover_photos_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."users_email_preferences" TO "service_role";
GRANT ALL ON TABLE "public"."users_email_preferences" TO "anon";
GRANT ALL ON TABLE "public"."users_email_preferences" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."users_email_preferences_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."users_email_preferences_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."users_email_preferences_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."users_followers" TO "service_role";
GRANT ALL ON TABLE "public"."users_followers" TO "anon";
GRANT ALL ON TABLE "public"."users_followers" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."users_followers_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."users_followers_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."users_followers_id_seq" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."users_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."users_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."users_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."users_referred" TO "service_role";
GRANT ALL ON TABLE "public"."users_referred" TO "anon";
GRANT ALL ON TABLE "public"."users_referred" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."users_referred_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."users_referred_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."users_referred_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."vid_extensions" TO "service_role";
GRANT ALL ON TABLE "public"."vid_extensions" TO "anon";
GRANT ALL ON TABLE "public"."vid_extensions" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."vid_extensions_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."vid_extensions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."vid_extensions_id_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."what_inspired_you_to_sign_up" TO "service_role";
GRANT ALL ON TABLE "public"."what_inspired_you_to_sign_up" TO "anon";
GRANT ALL ON TABLE "public"."what_inspired_you_to_sign_up" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."what_inspired_you_to_sign_up_id_seq" TO "service_role";
GRANT ALL ON SEQUENCE "public"."what_inspired_you_to_sign_up_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."what_inspired_you_to_sign_up_id_seq" TO "authenticated";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";




























drop extension if exists "pg_net";

create extension if not exists "pg_net" with schema "public";


  create policy "allow_authenticator_update_last_sign_in"
  on "auth"."users"
  as permissive
  for update
  to authenticator
using ((( SELECT auth.uid() AS uid) = id))
with check ((( SELECT auth.uid() AS uid) = id));



  create policy "authenticated_read_own"
  on "auth"."users"
  as permissive
  for select
  to authenticated
using ((id = ( SELECT auth.uid() AS uid)));


CREATE TRIGGER trg_handle_signup_merged_on_auth_identities AFTER INSERT ON auth.identities FOR EACH ROW EXECUTE FUNCTION public.handle_signup_merged();

CREATE TRIGGER trg_handle_signup_merged_on_auth_users AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_signup_merged();


  create policy "Allow All 1a0v5f_0"
  on "storage"."objects"
  as permissive
  for update
  to public
using ((bucket_id = 'Posts'::text));



  create policy "Allow All 1a0v5f_1"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'Posts'::text));



  create policy "Allow All 1dunbox_0"
  on "storage"."objects"
  as permissive
  for update
  to public
using ((bucket_id = 'Message Images'::text));



  create policy "Allow All 1dunbox_1"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'Message Images'::text));



  create policy "Allow All 1gw6z7f_0"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'Story Board'::text));



  create policy "Allow All 1gw6z7f_1"
  on "storage"."objects"
  as permissive
  for update
  to public
using ((bucket_id = 'Story Board'::text));



  create policy "Allow All 1qzkwhu_0"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'Users Cover Photos'::text));



  create policy "Allow All 1qzkwhu_1"
  on "storage"."objects"
  as permissive
  for update
  to public
using ((bucket_id = 'Users Cover Photos'::text));



  create policy "Allow All v99vah_0"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'Buckets'::text));



  create policy "Allow All v99vah_1"
  on "storage"."objects"
  as permissive
  for update
  to public
using ((bucket_id = 'Buckets'::text));



  create policy "Allow All xn03j2_0"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'Message Files'::text));



  create policy "Allow All xn03j2_1"
  on "storage"."objects"
  as permissive
  for update
  to public
using ((bucket_id = 'Message Files'::text));



  create policy "allow all 6zyf20_0"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'Users Profile Pics'::text));



  create policy "allow all 6zyf20_1"
  on "storage"."objects"
  as permissive
  for update
  to public
using ((bucket_id = 'Users Profile Pics'::text));



