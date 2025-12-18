create table public.collaborators (
  id bigserial not null,
  uid text null,
  related_user_id bigint null,
  related_bucket_id bigint null,
  approved_by_creator boolean null default false,
  approved_by_collaborator boolean null default false,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  related_user_email text null,
  related_bucket_uid text null,
  constraint collaborators_pkey primary key (id),
  constraint unique_user_bucket unique (related_user_id, related_bucket_id),
  constraint collaborators_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint collaborators_related_bucket_id_fkey foreign KEY (related_bucket_id) references buckets (id) on delete CASCADE,
  constraint collaborators_related_user_id_fkey foreign KEY (related_user_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;