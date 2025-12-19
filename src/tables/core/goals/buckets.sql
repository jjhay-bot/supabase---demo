create table public.buckets (
  id bigserial not null,
  uid text null,
  title text null,
  description text null,
  completion_date date null,
  is_completed boolean null default false,
  is_private boolean null default false,
  related_user_id bigint null,
  user_name text null,
  added_count integer null default 0,
  like_count integer null default 0,
  comment_count integer null default 0,
  storyboard boolean null default false,
  display_picture_url text null,
  location text null,
  custom_explore boolean null default false,
  experts_added boolean null default false,
  services_added boolean null default false,
  personalized_email boolean null default false,
  completion_range text null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  related_user_email text null,
  category bigint null,
  is_system_bucket boolean null default false,
  constraint buckets_pkey primary key (id),
  constraint buckets_category_fkey foreign KEY (category) references category_os (id),
  constraint buckets_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint buckets_related_user_id_fkey foreign KEY (related_user_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_buckets_related_user_id on public.buckets using btree (related_user_id) TABLESPACE pg_default;

create trigger trg_handle_new_bucket_for_first_goal
after INSERT on buckets for EACH row
execute FUNCTION handle_new_bucket_for_first_goal ();