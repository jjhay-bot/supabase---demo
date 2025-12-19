create table public.feed_comments (
  id bigserial not null,
  uid text null,
  context text null,
  post_id bigint null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  post_uid text null,
  constraint feed_comments_pkey primary key (id),
  constraint feed_comments_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint feed_comments_post_id_fkey foreign KEY (post_id) references posts (id) on delete CASCADE
) TABLESPACE pg_default;