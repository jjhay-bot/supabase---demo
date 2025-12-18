create table public.follows (
  id bigserial not null,
  uid text null,
  following_id bigint null,
  followed_by_id bigint null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  following_email text null,
  followed_by_email text null,
  constraint follows_pkey primary key (id),
  constraint follows_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint follows_followed_by_id_fkey foreign KEY (followed_by_id) references users (id) on delete CASCADE,
  constraint follows_following_id_fkey foreign KEY (following_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;