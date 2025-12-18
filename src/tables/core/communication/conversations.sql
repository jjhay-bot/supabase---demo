create table public.conversations (
  id bigserial not null,
  uid text null,
  last_updated timestamp with time zone null default now(),
  draft boolean null default true,
  related_bucket_id bigint null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  related_bucket_uid text null,
  constraint conversations_pkey primary key (id),
  constraint conversations_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint conversations_related_bucket_id_fkey foreign KEY (related_bucket_id) references buckets (id) on delete CASCADE
) TABLESPACE pg_default;