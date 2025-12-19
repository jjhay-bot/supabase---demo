create table public.onboarding_qna (
  id bigserial not null,
  uid text null,
  user_id bigint null,
  how_did_you_hear_about_us text null,
  what_inspired_you_to_sign_up text null,
  do_you_already_have_a_bucket_list text null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint onboarding_qna_pkey primary key (id),
  constraint onboarding_qna_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint onboarding_qna_user_id_fkey foreign KEY (user_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;