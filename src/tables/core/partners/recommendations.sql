create table public.recommendations (
  id bigserial not null,
  uid text null,
  last_updated date null default CURRENT_DATE,
  related_user_id bigint null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  related_user_email text null,
  constraint recommendations_pkey primary key (id),
  constraint recommendations_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint recommendations_related_user_id_fkey foreign KEY (related_user_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;