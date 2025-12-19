-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.action_plan_tasks (
  id bigint NOT NULL DEFAULT nextval('action_plan_tasks_id_seq'::regclass),
  uid text,
  title text,
  is_completed boolean DEFAULT false,
  description text,
  completion_date date,
  related_bucket_id bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  related_bucket_uid text,
  CONSTRAINT action_plan_tasks_pkey PRIMARY KEY (id),
  CONSTRAINT action_plan_tasks_related_bucket_id_fkey FOREIGN KEY (related_bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT action_plan_tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.admin_email (
  id bigint NOT NULL DEFAULT nextval('admin_email_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT admin_email_pkey PRIMARY KEY (id)
);
CREATE TABLE public.app_icons (
  id bigint NOT NULL DEFAULT nextval('app_icons_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  img text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT app_icons_pkey PRIMARY KEY (id)
);
CREATE TABLE public.bucket_list_filter (
  id bigint NOT NULL DEFAULT nextval('bucket_list_filter_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  ui text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT bucket_list_filter_pkey PRIMARY KEY (id)
);
CREATE TABLE public.buckets (
  id bigint NOT NULL DEFAULT nextval('buckets_id_seq'::regclass),
  uid text,
  title text,
  description text,
  completion_date date,
  is_completed boolean DEFAULT false,
  is_private boolean DEFAULT false,
  related_user_id bigint,
  user_name text,
  added_count integer DEFAULT 0,
  like_count integer DEFAULT 0,
  comment_count integer DEFAULT 0,
  storyboard boolean DEFAULT false,
  display_picture_url text,
  location text,
  custom_explore boolean DEFAULT false,
  experts_added boolean DEFAULT false,
  services_added boolean DEFAULT false,
  personalized_email boolean DEFAULT false,
  completion_range text,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  related_user_email text,
  category bigint,
  is_system_bucket boolean DEFAULT false,
  CONSTRAINT buckets_pkey PRIMARY KEY (id),
  CONSTRAINT buckets_related_user_id_fkey FOREIGN KEY (related_user_id) REFERENCES public.users(id),
  CONSTRAINT buckets_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id),
  CONSTRAINT buckets_category_fkey FOREIGN KEY (category) REFERENCES public.category_os(id)
);
CREATE TABLE public.buckets_categories (
  id bigint NOT NULL DEFAULT nextval('buckets_categories_id_seq'::regclass),
  uid text,
  bucket_id bigint,
  category bigint,
  bucket_uid text,
  category_name text,
  CONSTRAINT buckets_categories_pkey PRIMARY KEY (id),
  CONSTRAINT buckets_categories_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT buckets_categories_category_fkey FOREIGN KEY (category) REFERENCES public.category_os(id)
);
CREATE TABLE public.buckets_comments (
  id bigint NOT NULL DEFAULT nextval('buckets_comments_id_seq'::regclass),
  uid text,
  bucket_id bigint,
  comment_id bigint,
  bucket_uid text,
  comment_uid text,
  CONSTRAINT buckets_comments_pkey PRIMARY KEY (id),
  CONSTRAINT buckets_comments_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT buckets_comments_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(id)
);
CREATE TABLE public.buckets_explore_buckets (
  id bigint NOT NULL DEFAULT nextval('buckets_explore_buckets_id_seq'::regclass),
  uid text,
  bucket_id bigint,
  explore_bucket_id bigint,
  bucket_uid text,
  explore_bucket_uid text,
  CONSTRAINT buckets_explore_buckets_pkey PRIMARY KEY (id),
  CONSTRAINT buckets_explore_buckets_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT buckets_explore_buckets_explore_bucket_id_fkey FOREIGN KEY (explore_bucket_id) REFERENCES public.buckets(id)
);
CREATE TABLE public.buckets_partner_experts (
  id bigint NOT NULL DEFAULT nextval('buckets_partner_experts_id_seq'::regclass),
  uid text,
  bucket_id bigint,
  partner_expert_id bigint,
  bucket_uid text,
  partner_expert_uid text,
  CONSTRAINT buckets_partner_experts_pkey PRIMARY KEY (id),
  CONSTRAINT buckets_partner_experts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT buckets_partner_experts_partner_expert_id_fkey FOREIGN KEY (partner_expert_id) REFERENCES public.partner_experts(id)
);
CREATE TABLE public.buckets_story_board_items (
  id bigint NOT NULL DEFAULT nextval('buckets_story_board_items_id_seq'::regclass),
  uid text,
  bucket_id bigint,
  story_board_item_id bigint,
  bucket_uid text,
  story_board_item_uid text,
  CONSTRAINT buckets_story_board_items_pkey PRIMARY KEY (id),
  CONSTRAINT buckets_story_board_items_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT buckets_story_board_items_story_board_item_id_fkey FOREIGN KEY (story_board_item_id) REFERENCES public.story_board_items(id)
);
CREATE TABLE public.buckets_tags (
  id bigint NOT NULL DEFAULT nextval('buckets_tags_id_seq'::regclass),
  uid text,
  bucket_id bigint,
  tag text,
  bucket_uid text,
  CONSTRAINT buckets_tags_pkey PRIMARY KEY (id),
  CONSTRAINT buckets_tags_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id)
);
CREATE TABLE public.category_os (
  id bigint NOT NULL DEFAULT nextval('category_os_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  emoji text,
  img text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT category_os_pkey PRIMARY KEY (id)
);
CREATE TABLE public.collaborators (
  id bigint NOT NULL DEFAULT nextval('collaborators_id_seq'::regclass),
  uid text,
  related_user_id bigint,
  related_bucket_id bigint,
  approved_by_creator boolean DEFAULT false,
  approved_by_collaborator boolean DEFAULT false,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  related_user_email text,
  related_bucket_uid text,
  CONSTRAINT collaborators_pkey PRIMARY KEY (id),
  CONSTRAINT collaborators_related_user_id_fkey FOREIGN KEY (related_user_id) REFERENCES public.users(id),
  CONSTRAINT collaborators_related_bucket_id_fkey FOREIGN KEY (related_bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT collaborators_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.colours (
  id bigint NOT NULL DEFAULT nextval('colours_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT colours_pkey PRIMARY KEY (id)
);
CREATE TABLE public.comments (
  id bigint NOT NULL DEFAULT nextval('comments_id_seq'::regclass),
  uid text,
  content text,
  related_bucket_id bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  related_bucket_uid text,
  CONSTRAINT comments_pkey PRIMARY KEY (id),
  CONSTRAINT comments_related_bucket_id_fkey FOREIGN KEY (related_bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT comments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.conversations (
  id bigint NOT NULL DEFAULT nextval('conversations_id_seq'::regclass),
  uid text,
  last_updated timestamp with time zone DEFAULT now(),
  draft boolean DEFAULT true,
  related_bucket_id bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  related_bucket_uid text,
  CONSTRAINT conversations_pkey PRIMARY KEY (id),
  CONSTRAINT conversations_related_bucket_id_fkey FOREIGN KEY (related_bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT conversations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.conversations_users (
  id bigint NOT NULL DEFAULT nextval('conversations_users_id_seq'::regclass),
  uid text,
  conversation_id bigint,
  user_id bigint,
  conversation_uid text,
  user_uid text,
  CONSTRAINT conversations_users_pkey PRIMARY KEY (id),
  CONSTRAINT conversations_users_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id),
  CONSTRAINT conversations_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.default_goals (
  id bigint NOT NULL DEFAULT nextval('default_goals_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  img text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT default_goals_pkey PRIMARY KEY (id)
);
CREATE TABLE public.desc_placeholder_os (
  id bigint NOT NULL DEFAULT nextval('desc_placeholder_os_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT desc_placeholder_os_pkey PRIMARY KEY (id)
);
CREATE TABLE public.do_you_already_have_a_bucket_list (
  id bigint NOT NULL DEFAULT nextval('do_you_already_have_a_bucket_list_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT do_you_already_have_a_bucket_list_pkey PRIMARY KEY (id)
);
CREATE TABLE public.doc_extensions (
  id bigint NOT NULL DEFAULT nextval('doc_extensions_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT doc_extensions_pkey PRIMARY KEY (id)
);
CREATE TABLE public.dummies (
  id bigint NOT NULL DEFAULT nextval('dummies_id_seq'::regclass),
  uid text,
  post_maker_id bigint,
  post_title text,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT dummies_pkey PRIMARY KEY (id),
  CONSTRAINT dummies_post_maker_id_fkey FOREIGN KEY (post_maker_id) REFERENCES public.users(id),
  CONSTRAINT dummies_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.email_logs (
  id bigint NOT NULL DEFAULT nextval('email_logs_id_seq'::regclass),
  to_email text NOT NULL,
  template_id text NOT NULL,
  payload jsonb,
  type text,
  category text,
  status text,
  response text,
  inserted_at timestamp with time zone DEFAULT now(),
  CONSTRAINT email_logs_pkey PRIMARY KEY (id)
);
CREATE TABLE public.email_type (
  id bigint NOT NULL DEFAULT nextval('email_type_id_seq'::regclass),
  display text NOT NULL,
  description text,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT email_type_pkey PRIMARY KEY (id)
);
CREATE TABLE public.errors (
  id bigint NOT NULL DEFAULT nextval('errors_id_seq'::regclass),
  uid text,
  log text,
  user_id bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT errors_pkey PRIMARY KEY (id),
  CONSTRAINT errors_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT errors_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.feed_comments (
  id bigint NOT NULL DEFAULT nextval('feed_comments_id_seq'::regclass),
  uid text,
  context text,
  post_id bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  post_uid text,
  CONSTRAINT feed_comments_pkey PRIMARY KEY (id),
  CONSTRAINT feed_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT feed_comments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.file_type (
  id bigint NOT NULL DEFAULT nextval('file_type_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  deleted boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT file_type_pkey PRIMARY KEY (id)
);
CREATE TABLE public.follow (
  id bigint NOT NULL DEFAULT nextval('follow_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  ui text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT follow_pkey PRIMARY KEY (id)
);
CREATE TABLE public.follows (
  id bigint NOT NULL DEFAULT nextval('follows_id_seq'::regclass),
  uid text,
  following_id bigint,
  followed_by_id bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  following_email text,
  followed_by_email text,
  CONSTRAINT follows_pkey PRIMARY KEY (id),
  CONSTRAINT follows_following_id_fkey FOREIGN KEY (following_id) REFERENCES public.users(id),
  CONSTRAINT follows_followed_by_id_fkey FOREIGN KEY (followed_by_id) REFERENCES public.users(id),
  CONSTRAINT follows_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.handle_new_auth_user_debug (
  id bigint NOT NULL DEFAULT nextval('handle_new_auth_user_debug_id_seq'::regclass),
  created_at timestamp with time zone DEFAULT now(),
  new_id_text text,
  new_email text,
  error_message text,
  CONSTRAINT handle_new_auth_user_debug_pkey PRIMARY KEY (id)
);
CREATE TABLE public.how_did_you_hear_about_us (
  id bigint NOT NULL DEFAULT nextval('how_did_you_hear_about_us_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT how_did_you_hear_about_us_pkey PRIMARY KEY (id)
);
CREATE TABLE public.image_extension (
  id bigint NOT NULL DEFAULT nextval('image_extension_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT image_extension_pkey PRIMARY KEY (id)
);
CREATE TABLE public.index_tab (
  id bigint NOT NULL DEFAULT nextval('index_tab_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT index_tab_pkey PRIMARY KEY (id)
);
CREATE TABLE public.likes (
  id bigint NOT NULL DEFAULT nextval('likes_id_seq'::regclass),
  uid text,
  on_bucket_id bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  related_bucket_uid text,
  CONSTRAINT likes_pkey PRIMARY KEY (id),
  CONSTRAINT likes_on_bucket_id_fkey FOREIGN KEY (on_bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT likes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.links (
  id bigint NOT NULL DEFAULT nextval('links_id_seq'::regclass),
  uid text,
  url text,
  text_to_display text,
  related_bucket_id bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  related_bucket_uid text,
  CONSTRAINT links_pkey PRIMARY KEY (id),
  CONSTRAINT links_related_bucket_id_fkey FOREIGN KEY (related_bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT links_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.message_recs_os (
  id bigint NOT NULL DEFAULT nextval('message_recs_os_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  buddy boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT message_recs_os_pkey PRIMARY KEY (id)
);
CREATE TABLE public.message_recs_os_2 (
  id bigint NOT NULL DEFAULT nextval('message_recs_os_2_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT message_recs_os_2_pkey PRIMARY KEY (id)
);
CREATE TABLE public.messages (
  id bigint NOT NULL DEFAULT nextval('messages_id_seq'::regclass),
  uid text,
  content text,
  sender_id bigint,
  picture_url text,
  receiver_id bigint,
  attachment_url text,
  read boolean DEFAULT false,
  related_conversation_id bigint,
  referenced_bucket_id bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  sender_email text,
  reciever_email text,
  related_conversation_uid text,
  referenced_bucket_uid text,
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id),
  CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(id),
  CONSTRAINT messages_related_conversation_id_fkey FOREIGN KEY (related_conversation_id) REFERENCES public.conversations(id),
  CONSTRAINT messages_referenced_bucket_id_fkey FOREIGN KEY (referenced_bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT messages_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.notifications (
  id bigint NOT NULL DEFAULT nextval('notifications_id_seq'::regclass),
  uid text,
  recipient_id bigint,
  content text,
  read boolean DEFAULT false,
  sender_id bigint,
  referenced_bucket_id bigint,
  referenced_post_id bigint,
  type bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  sender_email text,
  reciever_email text,
  type_text text,
  referenced_bucket_uid text,
  referenced_post_uid text,
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.users(id),
  CONSTRAINT notifications_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id),
  CONSTRAINT notifications_referenced_bucket_id_fkey FOREIGN KEY (referenced_bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT notifications_referenced_post_id_fkey FOREIGN KEY (referenced_post_id) REFERENCES public.posts(id),
  CONSTRAINT notifications_type_fkey FOREIGN KEY (type) REFERENCES public.type_of_notifications(id),
  CONSTRAINT notifications_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.novels (
  id bigint NOT NULL,
  title_name text NOT NULL,
  author_name text NOT NULL,
  sort_factor bigint,
  CONSTRAINT novels_pkey PRIMARY KEY (id)
);
CREATE TABLE public.onboarding_qna (
  id bigint NOT NULL DEFAULT nextval('onboarding_qna_id_seq'::regclass),
  uid text,
  user_id bigint,
  how_did_you_hear_about_us text,
  what_inspired_you_to_sign_up text,
  do_you_already_have_a_bucket_list text,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT onboarding_qna_pkey PRIMARY KEY (id),
  CONSTRAINT onboarding_qna_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT onboarding_qna_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.os_buckets (
  id bigint NOT NULL DEFAULT nextval('os_buckets_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  picture text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT os_buckets_pkey PRIMARY KEY (id)
);
CREATE TABLE public.pages (
  id bigint NOT NULL DEFAULT nextval('pages_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  not_url text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT pages_pkey PRIMARY KEY (id)
);
CREATE TABLE public.partner_experts (
  id bigint NOT NULL DEFAULT nextval('partner_experts_id_seq'::regclass),
  uid text,
  name text,
  logo_url text,
  ai_detail text,
  expert boolean DEFAULT false,
  related_user_id bigint,
  affiliate_link text,
  short_description text,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  related_user text,
  CONSTRAINT partner_experts_pkey PRIMARY KEY (id),
  CONSTRAINT partner_experts_related_user_id_fkey FOREIGN KEY (related_user_id) REFERENCES public.users(id),
  CONSTRAINT partner_experts_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.partner_experts_pictures (
  id bigint NOT NULL DEFAULT nextval('partner_experts_pictures_id_seq'::regclass),
  uid text,
  partner_expert_id bigint,
  picture_url text,
  partner_expert_uid text,
  CONSTRAINT partner_experts_pictures_pkey PRIMARY KEY (id),
  CONSTRAINT partner_experts_pictures_partner_expert_id_fkey FOREIGN KEY (partner_expert_id) REFERENCES public.partner_experts(id)
);
CREATE TABLE public.popup_goal_tabs (
  id bigint NOT NULL DEFAULT nextval('popup_goal_tabs_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT popup_goal_tabs_pkey PRIMARY KEY (id)
);
CREATE TABLE public.post_type_os (
  id bigint NOT NULL DEFAULT nextval('post_type_os_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT post_type_os_pkey PRIMARY KEY (id)
);
CREATE TABLE public.posts (
  id bigint NOT NULL DEFAULT nextval('posts_id_seq'::regclass),
  uid text,
  name text,
  title text,
  image_url text,
  context text,
  related_user_id bigint,
  related_bucket_id bigint,
  type bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  related_user_email text,
  related_bucket_uid text,
  type_text text,
  CONSTRAINT posts_pkey PRIMARY KEY (id),
  CONSTRAINT posts_related_user_id_fkey FOREIGN KEY (related_user_id) REFERENCES public.users(id),
  CONSTRAINT posts_type_fkey FOREIGN KEY (type) REFERENCES public.post_type_os(id),
  CONSTRAINT posts_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id),
  CONSTRAINT posts_related_bucket_id_fkey FOREIGN KEY (related_bucket_id) REFERENCES public.buckets(id)
);
CREATE TABLE public.posts_comments (
  id bigint NOT NULL DEFAULT nextval('posts_comments_id_seq'::regclass),
  uid text,
  post_id bigint,
  comment_id bigint,
  post_uid text,
  comment_uid text,
  CONSTRAINT posts_comments_pkey PRIMARY KEY (id),
  CONSTRAINT posts_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT posts_comments_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(id)
);
CREATE TABLE public.posts_likes (
  id bigint NOT NULL DEFAULT nextval('posts_likes_id_seq'::regclass),
  uid text,
  post_id bigint,
  user_id bigint,
  created_at timestamp with time zone DEFAULT now(),
  post_uid text,
  user_uid text,
  CONSTRAINT posts_likes_pkey PRIMARY KEY (id),
  CONSTRAINT posts_likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT posts_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.posts_multi_goals (
  id bigint NOT NULL DEFAULT nextval('posts_multi_goals_id_seq'::regclass),
  uid text,
  post_id bigint,
  goal_text text,
  post_uid text,
  CONSTRAINT posts_multi_goals_pkey PRIMARY KEY (id),
  CONSTRAINT posts_multi_goals_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id)
);
CREATE TABLE public.pseudos_buckets_categories (
  id bigint NOT NULL DEFAULT nextval('pseudos_buckets_categories_id_seq'::regclass),
  uid text,
  bucket_id bigint,
  bucket_uid text,
  category text,
  CONSTRAINT pseudos_buckets_categories_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_buckets_categories_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id)
);
CREATE TABLE public.pseudos_buckets_comments (
  id bigint NOT NULL DEFAULT nextval('pseudos_buckets_comments_id_seq'::regclass),
  uid text,
  bucket_id bigint,
  bucket_uid text,
  comment_id bigint,
  comment_uid text,
  CONSTRAINT pseudos_buckets_comments_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_buckets_comments_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT pseudos_buckets_comments_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(id)
);
CREATE TABLE public.pseudos_buckets_explore_buckets (
  id bigint NOT NULL DEFAULT nextval('pseudos_buckets_explore_buckets_id_seq'::regclass),
  uid text,
  bucket_id bigint,
  bucket_uid text,
  explore_bucket_uids text,
  CONSTRAINT pseudos_buckets_explore_buckets_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_buckets_explore_buckets_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id)
);
CREATE TABLE public.pseudos_buckets_partner_experts (
  id bigint NOT NULL DEFAULT nextval('pseudos_buckets_partner_experts_id_seq'::regclass),
  uid text,
  bucket_id bigint,
  bucket_uid text,
  partner_expert_uids text,
  CONSTRAINT pseudos_buckets_partner_experts_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_buckets_partner_experts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id)
);
CREATE TABLE public.pseudos_buckets_story_board_items (
  id bigint NOT NULL DEFAULT nextval('pseudos_buckets_story_board_items_id_seq'::regclass),
  uid text,
  bucket_id bigint,
  bucket_uid text,
  story_board_items_uid text,
  CONSTRAINT pseudos_buckets_story_board_items_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_buckets_story_board_items_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id)
);
CREATE TABLE public.pseudos_buckets_tags (
  id bigint NOT NULL DEFAULT nextval('pseudos_buckets_tags_id_seq'::regclass),
  uid text,
  bucket_id bigint,
  bucket_uid text,
  tags text,
  CONSTRAINT pseudos_buckets_tags_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_buckets_tags_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id)
);
CREATE TABLE public.pseudos_conversations_users (
  id bigint NOT NULL DEFAULT nextval('pseudos_conversations_users_id_seq'::regclass),
  uid text,
  conversation_id bigint,
  conversation_uid text,
  user_id bigint,
  user_emails text,
  CONSTRAINT pseudos_conversations_users_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_conversations_users_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id),
  CONSTRAINT pseudos_conversations_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.pseudos_partner_experts_pictures (
  id bigint NOT NULL DEFAULT nextval('pseudos_partner_experts_pictures_id_seq'::regclass),
  uid text,
  partner_expert_id bigint,
  partner_expert_uid text,
  picture_urls text,
  CONSTRAINT pseudos_partner_experts_pictures_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_partner_experts_pictures_partner_expert_id_fkey FOREIGN KEY (partner_expert_id) REFERENCES public.partner_experts(id)
);
CREATE TABLE public.pseudos_posts_comments (
  id bigint NOT NULL DEFAULT nextval('pseudos_posts_comments_id_seq'::regclass),
  post_id bigint,
  post_uid text,
  comment_id bigint,
  comment_uid text,
  CONSTRAINT pseudos_posts_comments_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_posts_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT pseudos_posts_comments_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(id)
);
CREATE TABLE public.pseudos_posts_likes (
  id bigint NOT NULL DEFAULT nextval('pseudos_posts_likes_id_seq'::regclass),
  uid text,
  post_id bigint,
  post_uid text,
  user_emails text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT pseudos_posts_likes_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_posts_likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id)
);
CREATE TABLE public.pseudos_posts_multi_goals (
  id bigint NOT NULL DEFAULT nextval('pseudos_posts_multi_goals_id_seq'::regclass),
  uid text,
  post_id bigint,
  post_uid text,
  multi_goal_text text,
  CONSTRAINT pseudos_posts_multi_goals_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_posts_multi_goals_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id)
);
CREATE TABLE public.pseudos_recommendations_buckets (
  id bigint NOT NULL DEFAULT nextval('pseudos_recommendations_buckets_id_seq'::regclass),
  recommendation_id bigint,
  recommendation_uid text,
  bucket_uids text,
  CONSTRAINT pseudos_recommendations_buckets_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_recommendations_buckets_recommendation_id_fkey FOREIGN KEY (recommendation_id) REFERENCES public.recommendations(id)
);
CREATE TABLE public.pseudos_referrals_joined_users (
  id bigint NOT NULL DEFAULT nextval('pseudos_referrals_joined_users_id_seq'::regclass),
  uid text,
  referral_id bigint,
  referral_uid text,
  user_emails text,
  CONSTRAINT pseudos_referrals_joined_users_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_referrals_joined_users_referral_id_fkey FOREIGN KEY (referral_id) REFERENCES public.referrals(id)
);
CREATE TABLE public.pseudos_story_board_items_links (
  id bigint NOT NULL DEFAULT nextval('pseudos_story_board_items_links_id_seq'::regclass),
  uid text,
  story_board_item_id bigint,
  story_board_item_uid text,
  links_uid text,
  CONSTRAINT pseudos_story_board_items_links_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_story_board_items_links_story_board_item_id_fkey FOREIGN KEY (story_board_item_id) REFERENCES public.story_board_items(id)
);
CREATE TABLE public.pseudos_users_buckets (
  id bigint NOT NULL DEFAULT nextval('pseudos_users_buckets_id_seq'::regclass),
  uid text,
  user_id bigint,
  user_email text,
  bucket_id bigint,
  buckets_uid text,
  CONSTRAINT pseudos_users_buckets_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_users_buckets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT pseudos_users_buckets_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id)
);
CREATE TABLE public.pseudos_users_cover_photos (
  id bigint NOT NULL DEFAULT nextval('pseudos_users_cover_photos_id_seq'::regclass),
  uid text,
  user_id bigint,
  user_email text,
  cover_photos text,
  CONSTRAINT pseudos_users_cover_photos_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_users_cover_photos_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.pseudos_users_email_preferences (
  id bigint NOT NULL DEFAULT nextval('pseudos_users_email_preferences_id_seq'::regclass),
  uid text,
  user_id bigint,
  user_email text,
  email_type text,
  CONSTRAINT pseudos_users_email_preferences_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_users_email_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.pseudos_users_followers (
  id bigint NOT NULL DEFAULT nextval('pseudos_users_followers_id_seq'::regclass),
  uid text,
  user_id bigint,
  user_email text,
  follower_uids text,
  CONSTRAINT pseudos_users_followers_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_users_followers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.pseudos_users_referred (
  id bigint NOT NULL DEFAULT nextval('pseudos_users_referred_id_seq'::regclass),
  referrer_id bigint,
  referrer_uid text,
  referred_id bigint,
  referred_uid text,
  referral_id bigint,
  referral_uid text,
  CONSTRAINT pseudos_users_referred_pkey PRIMARY KEY (id),
  CONSTRAINT pseudos_users_referred_referrer_id_fkey FOREIGN KEY (referrer_id) REFERENCES public.users(id),
  CONSTRAINT pseudos_users_referred_referred_id_fkey FOREIGN KEY (referred_id) REFERENCES public.users(id),
  CONSTRAINT pseudos_users_referred_referral_id_fkey FOREIGN KEY (referral_id) REFERENCES public.referrals(id)
);
CREATE TABLE public.range_os (
  id bigint NOT NULL DEFAULT nextval('range_os_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  img text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT range_os_pkey PRIMARY KEY (id)
);
CREATE TABLE public.recommendations (
  id bigint NOT NULL DEFAULT nextval('recommendations_id_seq'::regclass),
  uid text,
  last_updated date DEFAULT CURRENT_DATE,
  related_user_id bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  related_user_email text,
  CONSTRAINT recommendations_pkey PRIMARY KEY (id),
  CONSTRAINT recommendations_related_user_id_fkey FOREIGN KEY (related_user_id) REFERENCES public.users(id),
  CONSTRAINT recommendations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.recommendations_buckets (
  id bigint NOT NULL DEFAULT nextval('recommendations_buckets_id_seq'::regclass),
  uid text,
  recommendation_id bigint,
  bucket_id bigint,
  recommendation_uid text,
  bucket_uid text,
  CONSTRAINT recommendations_buckets_pkey PRIMARY KEY (id),
  CONSTRAINT recommendations_buckets_recommendation_id_fkey FOREIGN KEY (recommendation_id) REFERENCES public.recommendations(id),
  CONSTRAINT recommendations_buckets_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id)
);
CREATE TABLE public.referrals (
  id bigint NOT NULL DEFAULT nextval('referrals_id_seq'::regclass),
  uid text,
  code text,
  joined_count integer DEFAULT 0,
  related_user_id bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  related_user_email text,
  CONSTRAINT referrals_pkey PRIMARY KEY (id),
  CONSTRAINT referrals_related_user_id_fkey FOREIGN KEY (related_user_id) REFERENCES public.users(id),
  CONSTRAINT referrals_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.referrals_joined_users (
  id bigint NOT NULL DEFAULT nextval('referrals_joined_users_id_seq'::regclass),
  uid text,
  referral_id bigint,
  user_id bigint,
  referral_uid text,
  user_uid text,
  CONSTRAINT referrals_joined_users_pkey PRIMARY KEY (id),
  CONSTRAINT referrals_joined_users_referral_id_fkey FOREIGN KEY (referral_id) REFERENCES public.referrals(id),
  CONSTRAINT referrals_joined_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.sample_file_csv (
  id bigint NOT NULL DEFAULT nextval('sample_file_csv_id_seq'::regclass),
  display text NOT NULL,
  file text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT sample_file_csv_pkey PRIMARY KEY (id)
);
CREATE TABLE public.scheduled_tasks (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id bigint NOT NULL,
  bucket_id bigint,
  task_type text NOT NULL,
  run_at timestamp with time zone NOT NULL,
  is_executed boolean NOT NULL DEFAULT false,
  executed_at timestamp with time zone,
  payload jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT scheduled_tasks_pkey PRIMARY KEY (id),
  CONSTRAINT scheduled_tasks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT scheduled_tasks_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id)
);
CREATE TABLE public.status_bar (
  id bigint NOT NULL DEFAULT nextval('status_bar_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT status_bar_pkey PRIMARY KEY (id)
);
CREATE TABLE public.story_board_items (
  id bigint NOT NULL DEFAULT nextval('story_board_items_id_seq'::regclass),
  uid text,
  answer text,
  random text,
  link boolean DEFAULT false,
  picture_url text,
  colour bigint,
  related_bucket_id bigint,
  question bigint,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  colour_text text,
  question_text text,
  related_bucket_uid text,
  sort_factor integer,
  CONSTRAINT story_board_items_pkey PRIMARY KEY (id),
  CONSTRAINT story_board_items_colour_fkey FOREIGN KEY (colour) REFERENCES public.colours(id),
  CONSTRAINT story_board_items_related_bucket_id_fkey FOREIGN KEY (related_bucket_id) REFERENCES public.buckets(id),
  CONSTRAINT story_board_items_question_fkey FOREIGN KEY (question) REFERENCES public.story_board_qs(id),
  CONSTRAINT story_board_items_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.story_board_items_links (
  id bigint NOT NULL DEFAULT nextval('story_board_items_links_id_seq'::regclass),
  uid text,
  story_board_item_id bigint,
  link_id bigint,
  story_board_item_uid text,
  link_uid text,
  CONSTRAINT story_board_items_links_pkey PRIMARY KEY (id),
  CONSTRAINT story_board_items_links_story_board_item_id_fkey FOREIGN KEY (story_board_item_id) REFERENCES public.story_board_items(id),
  CONSTRAINT story_board_items_links_link_id_fkey FOREIGN KEY (link_id) REFERENCES public.links(id)
);
CREATE TABLE public.story_board_qs (
  id bigint NOT NULL DEFAULT nextval('story_board_qs_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT story_board_qs_pkey PRIMARY KEY (id)
);
CREATE TABLE public.sub_pointers (
  id bigint NOT NULL DEFAULT nextval('sub_pointers_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT sub_pointers_pkey PRIMARY KEY (id)
);
CREATE TABLE public.subscription_plan (
  id bigint NOT NULL DEFAULT nextval('subscription_plan_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  discounted_price text,
  price text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT subscription_plan_pkey PRIMARY KEY (id)
);
CREATE TABLE public.testimonials (
  id bigint NOT NULL DEFAULT nextval('testimonials_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  c_address text,
  c_name text,
  content text,
  creater_img text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT testimonials_pkey PRIMARY KEY (id)
);
CREATE TABLE public.tests (
  id bigint NOT NULL DEFAULT nextval('tests_id_seq'::regclass),
  uid text,
  text_content text,
  image_url text,
  creator text,
  created_by bigint,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tests_pkey PRIMARY KEY (id),
  CONSTRAINT tests_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.title_placeholder_os (
  id bigint NOT NULL DEFAULT nextval('title_placeholder_os_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT title_placeholder_os_pkey PRIMARY KEY (id)
);
CREATE TABLE public.type_of_notifications (
  id bigint NOT NULL DEFAULT nextval('type_of_notifications_id_seq'::regclass),
  display text NOT NULL,
  content text,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT type_of_notifications_pkey PRIMARY KEY (id)
);
CREATE TABLE public.user_metadata_sync (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  auth_user_id uuid NOT NULL,
  user_id bigint NOT NULL,
  payload jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pending'::text,
  last_error text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_metadata_sync_pkey PRIMARY KEY (id)
);
CREATE TABLE public.user_sync_queue (
  id bigint NOT NULL DEFAULT nextval('user_sync_queue_id_seq'::regclass),
  user_id uuid,
  auth_user_id uuid,
  payload jsonb,
  status text DEFAULT 'pending'::text,
  attempts integer DEFAULT 0,
  last_error text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  public_user_id bigint,
  CONSTRAINT user_sync_queue_pkey PRIMARY KEY (id)
);
CREATE TABLE public.users (
  id bigint NOT NULL DEFAULT nextval('users_id_seq'::regclass),
  uid text,
  city text,
  profile_picture_url text,
  bio text,
  state_us_only text,
  country text,
  tiktok text,
  linkedin text,
  full_name text,
  instagram text,
  goal_count_trigger integer DEFAULT 0,
  welcome_email_sent boolean DEFAULT false,
  first_goal_added boolean DEFAULT false,
  is_confirmed boolean DEFAULT false,
  is_onboarded boolean DEFAULT false,
  onboarding_step integer DEFAULT 0,
  welcome_message_sent boolean DEFAULT false,
  email text UNIQUE,
  slug text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  auth_user_id uuid UNIQUE,
  last_personalized_bucket_flow_at timestamp with time zone,
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_auth_user_id_fkey FOREIGN KEY (auth_user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.users_buckets (
  id bigint NOT NULL DEFAULT nextval('users_buckets_id_seq'::regclass),
  uid text,
  user_id bigint,
  bucket_id bigint,
  user_uid text,
  bucket_uid text,
  sort_factor integer,
  CONSTRAINT users_buckets_pkey PRIMARY KEY (id),
  CONSTRAINT users_buckets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT users_buckets_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES public.buckets(id)
);
CREATE TABLE public.users_cover_photos (
  id bigint NOT NULL DEFAULT nextval('users_cover_photos_id_seq'::regclass),
  uid text,
  user_id bigint,
  cover_photo_url text,
  user_uid text,
  CONSTRAINT users_cover_photos_pkey PRIMARY KEY (id),
  CONSTRAINT users_cover_photos_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.users_email_preferences (
  id bigint NOT NULL DEFAULT nextval('users_email_preferences_id_seq'::regclass),
  uid text,
  user_id bigint,
  email_type bigint,
  user_uid text,
  email_type_text text,
  CONSTRAINT users_email_preferences_pkey PRIMARY KEY (id),
  CONSTRAINT users_email_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT users_email_preferences_email_type_fkey FOREIGN KEY (email_type) REFERENCES public.email_type(id)
);
CREATE TABLE public.users_followers (
  id bigint NOT NULL DEFAULT nextval('users_followers_id_seq'::regclass),
  uid text,
  user_id bigint,
  follower_id bigint,
  user_uid text,
  follower_uid text,
  CONSTRAINT users_followers_pkey PRIMARY KEY (id),
  CONSTRAINT users_followers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT users_followers_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.users(id)
);
CREATE TABLE public.users_referred (
  id bigint NOT NULL DEFAULT nextval('users_referred_id_seq'::regclass),
  uid text,
  referrer_id bigint,
  referred_id bigint,
  referral_id bigint,
  referrer_uid text,
  referred_uid text,
  referral_uid text,
  CONSTRAINT users_referred_pkey PRIMARY KEY (id),
  CONSTRAINT users_referred_referrer_id_fkey FOREIGN KEY (referrer_id) REFERENCES public.users(id),
  CONSTRAINT users_referred_referred_id_fkey FOREIGN KEY (referred_id) REFERENCES public.users(id),
  CONSTRAINT users_referred_referral_id_fkey FOREIGN KEY (referral_id) REFERENCES public.referrals(id)
);
CREATE TABLE public.vid_extensions (
  id bigint NOT NULL DEFAULT nextval('vid_extensions_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT vid_extensions_pkey PRIMARY KEY (id)
);
CREATE TABLE public.what_inspired_you_to_sign_up (
  id bigint NOT NULL DEFAULT nextval('what_inspired_you_to_sign_up_id_seq'::regclass),
  display text NOT NULL,
  sort_factor integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT what_inspired_you_to_sign_up_pkey PRIMARY KEY (id)
);