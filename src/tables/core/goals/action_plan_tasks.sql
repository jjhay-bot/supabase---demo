create table public.action_plan_tasks (
  id bigserial not null,
  uid text null,
  title text null,
  is_completed boolean null default false,
  description text null,
  completion_date date null,
  related_bucket_id bigint null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  related_bucket_uid text null,
  constraint action_plan_tasks_pkey primary key (id),
  constraint action_plan_tasks_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint action_plan_tasks_related_bucket_id_fkey foreign KEY (related_bucket_id) references buckets (id) on delete CASCADE
) TABLESPACE pg_default;