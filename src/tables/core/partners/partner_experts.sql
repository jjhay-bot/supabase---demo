create table public.partner_experts (
  id bigserial not null,
  uid text null,
  name text null,
  logo_url text null,
  ai_detail text null,
  expert boolean null default false,
  related_user_id bigint null,
  affiliate_link text null,
  short_description text null,
  creator text null,
  created_by bigint null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  related_user text null,
  constraint partner_experts_pkey primary key (id),
  constraint partner_experts_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint partner_experts_related_user_id_fkey foreign KEY (related_user_id) references users (id) on delete set null
) TABLESPACE pg_default;