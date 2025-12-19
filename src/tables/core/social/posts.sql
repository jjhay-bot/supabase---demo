create table public.posts (
  id bigserial not null,
  uid text null,
  name text null,
  title text null,
  image_url text null,
  context text null,
  related_user_id bigint null,
  related_bucket_id bigint null,
  type bigint null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  related_user_email text null,
  related_bucket_uid text null,
  type_text text null,
  constraint posts_pkey primary key (id),
  constraint posts_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint posts_related_bucket_id_fkey foreign KEY (related_bucket_id) references buckets (id) on delete CASCADE,
  constraint posts_related_user_id_fkey foreign KEY (related_user_id) references users (id) on delete CASCADE,
  constraint posts_type_fkey foreign KEY (type) references post_type_os (id)
) TABLESPACE pg_default;

create index IF not exists posts_bucket_created_at_id_desc_idx on public.posts using btree (related_bucket_id, created_at desc, id desc) TABLESPACE pg_default;

create index IF not exists posts_created_at_id_desc_idx on public.posts using btree (created_at desc, id desc) TABLESPACE pg_default;