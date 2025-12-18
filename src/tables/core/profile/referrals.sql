create table public.referrals (
  id bigserial not null,
  uid text null,
  code text null,
  joined_count integer null default 0,
  related_user_id bigint null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  related_user_email text null,
  constraint referrals_pkey primary key (id),
  constraint referrals_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint referrals_related_user_id_fkey foreign KEY (related_user_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;