create table public.likes (
  id bigserial not null,
  uid text null,
  on_bucket_id bigint null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  related_bucket_uid text null,
  constraint likes_pkey primary key (id),
  constraint likes_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint likes_on_bucket_id_fkey foreign KEY (on_bucket_id) references buckets (id) on delete CASCADE
) TABLESPACE pg_default;