create table public.links (
  id bigserial not null,
  uid text null,
  url text null,
  text_to_display text null,
  related_bucket_id bigint null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  related_bucket_uid text null,
  constraint links_pkey primary key (id),
  constraint links_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint links_related_bucket_id_fkey foreign KEY (related_bucket_id) references buckets (id) on delete CASCADE
) TABLESPACE pg_default;