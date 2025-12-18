create table public.users (
  id bigserial not null,
  uid text null,
  city text null,
  profile_picture_url text null,
  bio text null,
  state_us_only text null,
  country text null,
  tiktok text null,
  linkedin text null,
  full_name text null,
  instagram text null,
  goal_count_trigger integer null default 0,
  welcome_email_sent boolean null default false,
  first_goal_added boolean null default false,
  is_confirmed boolean null default false,
  is_onboarded boolean null default false,
  onboarding_step integer null default 0,
  welcome_message_sent boolean null default false,
  email text null,
  slug text null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  auth_user_id uuid null,
  last_personalized_bucket_flow_at timestamp with time zone null,
  constraint users_pkey primary key (id),
  constraint users_auth_user_id_key unique (auth_user_id),
  constraint users_email_key unique (email),
  constraint users_auth_user_id_fkey foreign KEY (auth_user_id) references auth.users (id)
) TABLESPACE pg_default;

create index IF not exists idx_public_users_lower_email on public.users using btree (lower(email)) TABLESPACE pg_default;

create unique INDEX IF not exists idx_users_email_lower_unique on public.users using btree (lower(email)) TABLESPACE pg_default;

create index IF not exists idx_users_lower_email on public.users using btree (lower(email)) TABLESPACE pg_default;

create index IF not exists idx_users_lower_slug on public.users using btree (lower(slug)) TABLESPACE pg_default;

create unique INDEX IF not exists idx_users_slug_unique on public.users using btree (slug) TABLESPACE pg_default
where
  (slug is not null);

create trigger generate_user_slug_trg BEFORE INSERT on users for EACH row
execute FUNCTION generate_user_slug ();

create trigger trg_handle_signup_merged_on_public_users
after INSERT on users for EACH row
execute FUNCTION handle_signup_merged ();