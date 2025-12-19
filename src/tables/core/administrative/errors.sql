create table public.errors (
  id bigserial not null,
  uid text null,
  log text null,
  user_id bigint null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint errors_pkey primary key (id),
  constraint errors_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint errors_user_id_fkey foreign KEY (user_id) references users (id) on delete set null
) TABLESPACE pg_default;