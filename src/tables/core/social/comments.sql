create table public.comments (
  id bigserial not null,
  uid text null,
  content text null,
  related_bucket_id bigint null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  related_bucket_uid text null,
  constraint comments_pkey primary key (id),
  constraint comments_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint comments_related_bucket_id_fkey foreign KEY (related_bucket_id) references buckets (id) on delete CASCADE
) TABLESPACE pg_default;