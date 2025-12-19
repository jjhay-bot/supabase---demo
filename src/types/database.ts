// export type Database = {
//   // Allows to automatically instantiate createClient with right options
//   // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
//   __InternalSupabase: {
//     PostgrestVersion: "13.0.5"
//   }
//   public: {
//     Tables: {
//       action_plan_tasks: {
//         Row: {
//           completion_date: string | null
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           description: string | null
//           id: number
//           is_completed: boolean | null
//           related_bucket_id: number | null
//           related_bucket_uid: string | null
//           title: string | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           completion_date?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           description?: string | null
//           id?: number
//           is_completed?: boolean | null
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           title?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           completion_date?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           description?: string | null
//           id?: number
//           is_completed?: boolean | null
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           title?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "action_plan_tasks_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "action_plan_tasks_related_bucket_id_fkey"
//             columns: ["related_bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       admin_email: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       app_icons: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           img: string | null
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           img?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           img?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       bucket_list_filter: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           ui: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           ui?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           ui?: string | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       buckets: {
//         Row: {
//           added_count: number | null
//           category: number | null
//           comment_count: number | null
//           completion_date: string | null
//           completion_range: string | null
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           custom_explore: boolean | null
//           description: string | null
//           display_picture_url: string | null
//           experts_added: boolean | null
//           id: number
//           is_completed: boolean | null
//           is_private: boolean | null
//           is_system_bucket: boolean | null
//           like_count: number | null
//           location: string | null
//           personalized_email: boolean | null
//           related_user_email: string | null
//           related_user_id: number | null
//           services_added: boolean | null
//           storyboard: boolean | null
//           title: string | null
//           uid: string | null
//           updated_at: string | null
//           user_name: string | null
//         }
//         Insert: {
//           added_count?: number | null
//           category?: number | null
//           comment_count?: number | null
//           completion_date?: string | null
//           completion_range?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           custom_explore?: boolean | null
//           description?: string | null
//           display_picture_url?: string | null
//           experts_added?: boolean | null
//           id?: number
//           is_completed?: boolean | null
//           is_private?: boolean | null
//           is_system_bucket?: boolean | null
//           like_count?: number | null
//           location?: string | null
//           personalized_email?: boolean | null
//           related_user_email?: string | null
//           related_user_id?: number | null
//           services_added?: boolean | null
//           storyboard?: boolean | null
//           title?: string | null
//           uid?: string | null
//           updated_at?: string | null
//           user_name?: string | null
//         }
//         Update: {
//           added_count?: number | null
//           category?: number | null
//           comment_count?: number | null
//           completion_date?: string | null
//           completion_range?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           custom_explore?: boolean | null
//           description?: string | null
//           display_picture_url?: string | null
//           experts_added?: boolean | null
//           id?: number
//           is_completed?: boolean | null
//           is_private?: boolean | null
//           is_system_bucket?: boolean | null
//           like_count?: number | null
//           location?: string | null
//           personalized_email?: boolean | null
//           related_user_email?: string | null
//           related_user_id?: number | null
//           services_added?: boolean | null
//           storyboard?: boolean | null
//           title?: string | null
//           uid?: string | null
//           updated_at?: string | null
//           user_name?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "buckets_category_fkey"
//             columns: ["category"]
//             isOneToOne: false
//             referencedRelation: "category_os"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "buckets_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "buckets_related_user_id_fkey"
//             columns: ["related_user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       buckets_categories: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           category: number | null
//           category_name: string | null
//           id: number
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           category?: number | null
//           category_name?: string | null
//           id?: number
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           category?: number | null
//           category_name?: string | null
//           id?: number
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "buckets_categories_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "buckets_categories_category_fkey"
//             columns: ["category"]
//             isOneToOne: false
//             referencedRelation: "category_os"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       buckets_comments: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           comment_id: number | null
//           comment_uid: string | null
//           id: number
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           comment_id?: number | null
//           comment_uid?: string | null
//           id?: number
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           comment_id?: number | null
//           comment_uid?: string | null
//           id?: number
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "buckets_comments_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "buckets_comments_comment_id_fkey"
//             columns: ["comment_id"]
//             isOneToOne: false
//             referencedRelation: "comments"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       buckets_explore_buckets: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           explore_bucket_id: number | null
//           explore_bucket_uid: string | null
//           id: number
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           explore_bucket_id?: number | null
//           explore_bucket_uid?: string | null
//           id?: number
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           explore_bucket_id?: number | null
//           explore_bucket_uid?: string | null
//           id?: number
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "buckets_explore_buckets_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "buckets_explore_buckets_explore_bucket_id_fkey"
//             columns: ["explore_bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       buckets_partner_experts: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           id: number
//           partner_expert_id: number | null
//           partner_expert_uid: string | null
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           partner_expert_id?: number | null
//           partner_expert_uid?: string | null
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           partner_expert_id?: number | null
//           partner_expert_uid?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "buckets_partner_experts_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "buckets_partner_experts_partner_expert_id_fkey"
//             columns: ["partner_expert_id"]
//             isOneToOne: false
//             referencedRelation: "partner_experts"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       buckets_story_board_items: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           id: number
//           story_board_item_id: number | null
//           story_board_item_uid: string | null
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           story_board_item_id?: number | null
//           story_board_item_uid?: string | null
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           story_board_item_id?: number | null
//           story_board_item_uid?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "buckets_story_board_items_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "buckets_story_board_items_story_board_item_id_fkey"
//             columns: ["story_board_item_id"]
//             isOneToOne: false
//             referencedRelation: "story_board_items"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       buckets_tags: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           id: number
//           tag: string | null
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           tag?: string | null
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           tag?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "buckets_tags_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       category_os: {
//         Row: {
//           created_at: string | null
//           display: string
//           emoji: string | null
//           id: number
//           img: string | null
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           emoji?: string | null
//           id?: number
//           img?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           emoji?: string | null
//           id?: number
//           img?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       collaborators: {
//         Row: {
//           approved_by_collaborator: boolean | null
//           approved_by_creator: boolean | null
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           related_bucket_id: number | null
//           related_bucket_uid: string | null
//           related_user_email: string | null
//           related_user_id: number | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           approved_by_collaborator?: boolean | null
//           approved_by_creator?: boolean | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           related_user_email?: string | null
//           related_user_id?: number | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           approved_by_collaborator?: boolean | null
//           approved_by_creator?: boolean | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           related_user_email?: string | null
//           related_user_id?: number | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "collaborators_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "collaborators_related_bucket_id_fkey"
//             columns: ["related_bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "collaborators_related_user_id_fkey"
//             columns: ["related_user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       colours: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       comments: {
//         Row: {
//           content: string | null
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           related_bucket_id: number | null
//           related_bucket_uid: string | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           content?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           content?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "comments_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "comments_related_bucket_id_fkey"
//             columns: ["related_bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       conversations: {
//         Row: {
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           draft: boolean | null
//           id: number
//           last_updated: string | null
//           related_bucket_id: number | null
//           related_bucket_uid: string | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           draft?: boolean | null
//           id?: number
//           last_updated?: string | null
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           draft?: boolean | null
//           id?: number
//           last_updated?: string | null
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "conversations_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "conversations_related_bucket_id_fkey"
//             columns: ["related_bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       conversations_users: {
//         Row: {
//           conversation_id: number | null
//           conversation_uid: string | null
//           id: number
//           uid: string | null
//           user_id: number | null
//           user_uid: string | null
//         }
//         Insert: {
//           conversation_id?: number | null
//           conversation_uid?: string | null
//           id?: number
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Update: {
//           conversation_id?: number | null
//           conversation_uid?: string | null
//           id?: number
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "conversations_users_conversation_id_fkey"
//             columns: ["conversation_id"]
//             isOneToOne: false
//             referencedRelation: "conversations"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "conversations_users_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       default_goals: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           img: string | null
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           img?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           img?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       desc_placeholder_os: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       do_you_already_have_a_bucket_list: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       doc_extensions: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       dummies: {
//         Row: {
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           post_maker_id: number | null
//           post_title: string | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           post_maker_id?: number | null
//           post_title?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           post_maker_id?: number | null
//           post_title?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "dummies_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "dummies_post_maker_id_fkey"
//             columns: ["post_maker_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       email_logs: {
//         Row: {
//           category: string | null
//           id: number
//           inserted_at: string | null
//           payload: Json | null
//           response: string | null
//           status: string | null
//           template_id: string
//           to_email: string
//           type: string | null
//         }
//         Insert: {
//           category?: string | null
//           id?: number
//           inserted_at?: string | null
//           payload?: Json | null
//           response?: string | null
//           status?: string | null
//           template_id: string
//           to_email: string
//           type?: string | null
//         }
//         Update: {
//           category?: string | null
//           id?: number
//           inserted_at?: string | null
//           payload?: Json | null
//           response?: string | null
//           status?: string | null
//           template_id?: string
//           to_email?: string
//           type?: string | null
//         }
//         Relationships: []
//       }
//       email_type: {
//         Row: {
//           created_at: string | null
//           description: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           description?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           description?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       errors: {
//         Row: {
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           log: string | null
//           uid: string | null
//           updated_at: string | null
//           user_id: number | null
//         }
//         Insert: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           log?: string | null
//           uid?: string | null
//           updated_at?: string | null
//           user_id?: number | null
//         }
//         Update: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           log?: string | null
//           uid?: string | null
//           updated_at?: string | null
//           user_id?: number | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "errors_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "errors_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       feed_comments: {
//         Row: {
//           context: string | null
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           post_id: number | null
//           post_uid: string | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           context?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           post_id?: number | null
//           post_uid?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           context?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           post_id?: number | null
//           post_uid?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "feed_comments_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "feed_comments_post_id_fkey"
//             columns: ["post_id"]
//             isOneToOne: false
//             referencedRelation: "posts"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       file_type: {
//         Row: {
//           created_at: string | null
//           deleted: boolean | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           deleted?: boolean | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           deleted?: boolean | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       follow: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           ui: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           ui?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           ui?: string | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       follows: {
//         Row: {
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           followed_by_email: string | null
//           followed_by_id: number | null
//           following_email: string | null
//           following_id: number | null
//           id: number
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           followed_by_email?: string | null
//           followed_by_id?: number | null
//           following_email?: string | null
//           following_id?: number | null
//           id?: number
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           followed_by_email?: string | null
//           followed_by_id?: number | null
//           following_email?: string | null
//           following_id?: number | null
//           id?: number
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "follows_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "follows_followed_by_id_fkey"
//             columns: ["followed_by_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "follows_following_id_fkey"
//             columns: ["following_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       handle_new_auth_user_debug: {
//         Row: {
//           created_at: string | null
//           error_message: string | null
//           id: number
//           new_email: string | null
//           new_id_text: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           error_message?: string | null
//           id?: number
//           new_email?: string | null
//           new_id_text?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           error_message?: string | null
//           id?: number
//           new_email?: string | null
//           new_id_text?: string | null
//         }
//         Relationships: []
//       }
//       how_did_you_hear_about_us: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       image_extension: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       index_tab: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       likes: {
//         Row: {
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           on_bucket_id: number | null
//           related_bucket_uid: string | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           on_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           on_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "likes_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "likes_on_bucket_id_fkey"
//             columns: ["on_bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       links: {
//         Row: {
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           related_bucket_id: number | null
//           related_bucket_uid: string | null
//           text_to_display: string | null
//           uid: string | null
//           updated_at: string | null
//           url: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           text_to_display?: string | null
//           uid?: string | null
//           updated_at?: string | null
//           url?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           text_to_display?: string | null
//           uid?: string | null
//           updated_at?: string | null
//           url?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "links_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "links_related_bucket_id_fkey"
//             columns: ["related_bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       message_recs_os: {
//         Row: {
//           buddy: boolean | null
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           buddy?: boolean | null
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           buddy?: boolean | null
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       message_recs_os_2: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       messages: {
//         Row: {
//           attachment_url: string | null
//           content: string | null
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           picture_url: string | null
//           read: boolean | null
//           receiver_id: number | null
//           reciever_email: string | null
//           referenced_bucket_id: number | null
//           referenced_bucket_uid: string | null
//           related_conversation_id: number | null
//           related_conversation_uid: string | null
//           sender_email: string | null
//           sender_id: number | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           attachment_url?: string | null
//           content?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           picture_url?: string | null
//           read?: boolean | null
//           receiver_id?: number | null
//           reciever_email?: string | null
//           referenced_bucket_id?: number | null
//           referenced_bucket_uid?: string | null
//           related_conversation_id?: number | null
//           related_conversation_uid?: string | null
//           sender_email?: string | null
//           sender_id?: number | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           attachment_url?: string | null
//           content?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           picture_url?: string | null
//           read?: boolean | null
//           receiver_id?: number | null
//           reciever_email?: string | null
//           referenced_bucket_id?: number | null
//           referenced_bucket_uid?: string | null
//           related_conversation_id?: number | null
//           related_conversation_uid?: string | null
//           sender_email?: string | null
//           sender_id?: number | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "messages_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "messages_receiver_id_fkey"
//             columns: ["receiver_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "messages_referenced_bucket_id_fkey"
//             columns: ["referenced_bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "messages_related_conversation_id_fkey"
//             columns: ["related_conversation_id"]
//             isOneToOne: false
//             referencedRelation: "conversations"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "messages_sender_id_fkey"
//             columns: ["sender_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       notifications: {
//         Row: {
//           content: string | null
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           read: boolean | null
//           reciever_email: string | null
//           recipient_id: number | null
//           referenced_bucket_id: number | null
//           referenced_bucket_uid: string | null
//           referenced_post_id: number | null
//           referenced_post_uid: string | null
//           sender_email: string | null
//           sender_id: number | null
//           type: number | null
//           type_text: string | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           content?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           read?: boolean | null
//           reciever_email?: string | null
//           recipient_id?: number | null
//           referenced_bucket_id?: number | null
//           referenced_bucket_uid?: string | null
//           referenced_post_id?: number | null
//           referenced_post_uid?: string | null
//           sender_email?: string | null
//           sender_id?: number | null
//           type?: number | null
//           type_text?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           content?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           read?: boolean | null
//           reciever_email?: string | null
//           recipient_id?: number | null
//           referenced_bucket_id?: number | null
//           referenced_bucket_uid?: string | null
//           referenced_post_id?: number | null
//           referenced_post_uid?: string | null
//           sender_email?: string | null
//           sender_id?: number | null
//           type?: number | null
//           type_text?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "notifications_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "notifications_recipient_id_fkey"
//             columns: ["recipient_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "notifications_referenced_bucket_id_fkey"
//             columns: ["referenced_bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "notifications_referenced_post_id_fkey"
//             columns: ["referenced_post_id"]
//             isOneToOne: false
//             referencedRelation: "posts"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "notifications_sender_id_fkey"
//             columns: ["sender_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "notifications_type_fkey"
//             columns: ["type"]
//             isOneToOne: false
//             referencedRelation: "type_of_notifications"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       novels: {
//         Row: {
//           author_name: string
//           id: number
//           sort_factor: number | null
//           title_name: string
//         }
//         Insert: {
//           author_name: string
//           id: number
//           sort_factor?: number | null
//           title_name: string
//         }
//         Update: {
//           author_name?: string
//           id?: number
//           sort_factor?: number | null
//           title_name?: string
//         }
//         Relationships: []
//       }
//       onboarding_qna: {
//         Row: {
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           do_you_already_have_a_bucket_list: string | null
//           how_did_you_hear_about_us: string | null
//           id: number
//           uid: string | null
//           updated_at: string | null
//           user_id: number | null
//           what_inspired_you_to_sign_up: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           do_you_already_have_a_bucket_list?: string | null
//           how_did_you_hear_about_us?: string | null
//           id?: number
//           uid?: string | null
//           updated_at?: string | null
//           user_id?: number | null
//           what_inspired_you_to_sign_up?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           do_you_already_have_a_bucket_list?: string | null
//           how_did_you_hear_about_us?: string | null
//           id?: number
//           uid?: string | null
//           updated_at?: string | null
//           user_id?: number | null
//           what_inspired_you_to_sign_up?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "onboarding_qna_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "onboarding_qna_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       os_buckets: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           picture: string | null
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           picture?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           picture?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       pages: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           not_url: string | null
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           not_url?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           not_url?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       partner_experts: {
//         Row: {
//           affiliate_link: string | null
//           ai_detail: string | null
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           expert: boolean | null
//           id: number
//           logo_url: string | null
//           name: string | null
//           related_user: string | null
//           related_user_id: number | null
//           short_description: string | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           affiliate_link?: string | null
//           ai_detail?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           expert?: boolean | null
//           id?: number
//           logo_url?: string | null
//           name?: string | null
//           related_user?: string | null
//           related_user_id?: number | null
//           short_description?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           affiliate_link?: string | null
//           ai_detail?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           expert?: boolean | null
//           id?: number
//           logo_url?: string | null
//           name?: string | null
//           related_user?: string | null
//           related_user_id?: number | null
//           short_description?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "partner_experts_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "partner_experts_related_user_id_fkey"
//             columns: ["related_user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       partner_experts_pictures: {
//         Row: {
//           id: number
//           partner_expert_id: number | null
//           partner_expert_uid: string | null
//           picture_url: string | null
//           uid: string | null
//         }
//         Insert: {
//           id?: number
//           partner_expert_id?: number | null
//           partner_expert_uid?: string | null
//           picture_url?: string | null
//           uid?: string | null
//         }
//         Update: {
//           id?: number
//           partner_expert_id?: number | null
//           partner_expert_uid?: string | null
//           picture_url?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "partner_experts_pictures_partner_expert_id_fkey"
//             columns: ["partner_expert_id"]
//             isOneToOne: false
//             referencedRelation: "partner_experts"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       popup_goal_tabs: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       post_type_os: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       posts: {
//         Row: {
//           context: string | null
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           image_url: string | null
//           name: string | null
//           related_bucket_id: number | null
//           related_bucket_uid: string | null
//           related_user_email: string | null
//           related_user_id: number | null
//           title: string | null
//           type: number | null
//           type_text: string | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           context?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           image_url?: string | null
//           name?: string | null
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           related_user_email?: string | null
//           related_user_id?: number | null
//           title?: string | null
//           type?: number | null
//           type_text?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           context?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           image_url?: string | null
//           name?: string | null
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           related_user_email?: string | null
//           related_user_id?: number | null
//           title?: string | null
//           type?: number | null
//           type_text?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "posts_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "posts_related_bucket_id_fkey"
//             columns: ["related_bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "posts_related_user_id_fkey"
//             columns: ["related_user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "posts_type_fkey"
//             columns: ["type"]
//             isOneToOne: false
//             referencedRelation: "post_type_os"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       posts_comments: {
//         Row: {
//           comment_id: number | null
//           comment_uid: string | null
//           id: number
//           post_id: number | null
//           post_uid: string | null
//           uid: string | null
//         }
//         Insert: {
//           comment_id?: number | null
//           comment_uid?: string | null
//           id?: number
//           post_id?: number | null
//           post_uid?: string | null
//           uid?: string | null
//         }
//         Update: {
//           comment_id?: number | null
//           comment_uid?: string | null
//           id?: number
//           post_id?: number | null
//           post_uid?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "posts_comments_comment_id_fkey"
//             columns: ["comment_id"]
//             isOneToOne: false
//             referencedRelation: "comments"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "posts_comments_post_id_fkey"
//             columns: ["post_id"]
//             isOneToOne: false
//             referencedRelation: "posts"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       posts_likes: {
//         Row: {
//           created_at: string | null
//           id: number
//           post_id: number | null
//           post_uid: string | null
//           uid: string | null
//           user_id: number | null
//           user_uid: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           id?: number
//           post_id?: number | null
//           post_uid?: string | null
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           id?: number
//           post_id?: number | null
//           post_uid?: string | null
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "posts_likes_post_id_fkey"
//             columns: ["post_id"]
//             isOneToOne: false
//             referencedRelation: "posts"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "posts_likes_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       posts_multi_goals: {
//         Row: {
//           goal_text: string | null
//           id: number
//           post_id: number | null
//           post_uid: string | null
//           uid: string | null
//         }
//         Insert: {
//           goal_text?: string | null
//           id?: number
//           post_id?: number | null
//           post_uid?: string | null
//           uid?: string | null
//         }
//         Update: {
//           goal_text?: string | null
//           id?: number
//           post_id?: number | null
//           post_uid?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "posts_multi_goals_post_id_fkey"
//             columns: ["post_id"]
//             isOneToOne: false
//             referencedRelation: "posts"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_buckets_categories: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           category: string | null
//           id: number
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           category?: string | null
//           id?: number
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           category?: string | null
//           id?: number
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_buckets_categories_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_buckets_comments: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           comment_id: number | null
//           comment_uid: string | null
//           id: number
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           comment_id?: number | null
//           comment_uid?: string | null
//           id?: number
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           comment_id?: number | null
//           comment_uid?: string | null
//           id?: number
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_buckets_comments_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "pseudos_buckets_comments_comment_id_fkey"
//             columns: ["comment_id"]
//             isOneToOne: false
//             referencedRelation: "comments"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_buckets_explore_buckets: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           explore_bucket_uids: string | null
//           id: number
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           explore_bucket_uids?: string | null
//           id?: number
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           explore_bucket_uids?: string | null
//           id?: number
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_buckets_explore_buckets_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_buckets_partner_experts: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           id: number
//           partner_expert_uids: string | null
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           partner_expert_uids?: string | null
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           partner_expert_uids?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_buckets_partner_experts_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_buckets_story_board_items: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           id: number
//           story_board_items_uid: string | null
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           story_board_items_uid?: string | null
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           story_board_items_uid?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_buckets_story_board_items_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_buckets_tags: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           id: number
//           tags: string | null
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           tags?: string | null
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           tags?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_buckets_tags_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_conversations_users: {
//         Row: {
//           conversation_id: number | null
//           conversation_uid: string | null
//           id: number
//           uid: string | null
//           user_emails: string | null
//           user_id: number | null
//         }
//         Insert: {
//           conversation_id?: number | null
//           conversation_uid?: string | null
//           id?: number
//           uid?: string | null
//           user_emails?: string | null
//           user_id?: number | null
//         }
//         Update: {
//           conversation_id?: number | null
//           conversation_uid?: string | null
//           id?: number
//           uid?: string | null
//           user_emails?: string | null
//           user_id?: number | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_conversations_users_conversation_id_fkey"
//             columns: ["conversation_id"]
//             isOneToOne: false
//             referencedRelation: "conversations"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "pseudos_conversations_users_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_partner_experts_pictures: {
//         Row: {
//           id: number
//           partner_expert_id: number | null
//           partner_expert_uid: string | null
//           picture_urls: string | null
//           uid: string | null
//         }
//         Insert: {
//           id?: number
//           partner_expert_id?: number | null
//           partner_expert_uid?: string | null
//           picture_urls?: string | null
//           uid?: string | null
//         }
//         Update: {
//           id?: number
//           partner_expert_id?: number | null
//           partner_expert_uid?: string | null
//           picture_urls?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_partner_experts_pictures_partner_expert_id_fkey"
//             columns: ["partner_expert_id"]
//             isOneToOne: false
//             referencedRelation: "partner_experts"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_posts_comments: {
//         Row: {
//           comment_id: number | null
//           comment_uid: string | null
//           id: number
//           post_id: number | null
//           post_uid: string | null
//         }
//         Insert: {
//           comment_id?: number | null
//           comment_uid?: string | null
//           id?: number
//           post_id?: number | null
//           post_uid?: string | null
//         }
//         Update: {
//           comment_id?: number | null
//           comment_uid?: string | null
//           id?: number
//           post_id?: number | null
//           post_uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_posts_comments_comment_id_fkey"
//             columns: ["comment_id"]
//             isOneToOne: false
//             referencedRelation: "comments"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "pseudos_posts_comments_post_id_fkey"
//             columns: ["post_id"]
//             isOneToOne: false
//             referencedRelation: "posts"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_posts_likes: {
//         Row: {
//           created_at: string | null
//           id: number
//           post_id: number | null
//           post_uid: string | null
//           uid: string | null
//           user_emails: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           id?: number
//           post_id?: number | null
//           post_uid?: string | null
//           uid?: string | null
//           user_emails?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           id?: number
//           post_id?: number | null
//           post_uid?: string | null
//           uid?: string | null
//           user_emails?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_posts_likes_post_id_fkey"
//             columns: ["post_id"]
//             isOneToOne: false
//             referencedRelation: "posts"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_posts_multi_goals: {
//         Row: {
//           id: number
//           multi_goal_text: string | null
//           post_id: number | null
//           post_uid: string | null
//           uid: string | null
//         }
//         Insert: {
//           id?: number
//           multi_goal_text?: string | null
//           post_id?: number | null
//           post_uid?: string | null
//           uid?: string | null
//         }
//         Update: {
//           id?: number
//           multi_goal_text?: string | null
//           post_id?: number | null
//           post_uid?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_posts_multi_goals_post_id_fkey"
//             columns: ["post_id"]
//             isOneToOne: false
//             referencedRelation: "posts"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_recommendations_buckets: {
//         Row: {
//           bucket_uids: string | null
//           id: number
//           recommendation_id: number | null
//           recommendation_uid: string | null
//         }
//         Insert: {
//           bucket_uids?: string | null
//           id?: number
//           recommendation_id?: number | null
//           recommendation_uid?: string | null
//         }
//         Update: {
//           bucket_uids?: string | null
//           id?: number
//           recommendation_id?: number | null
//           recommendation_uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_recommendations_buckets_recommendation_id_fkey"
//             columns: ["recommendation_id"]
//             isOneToOne: false
//             referencedRelation: "recommendations"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_referrals_joined_users: {
//         Row: {
//           id: number
//           referral_id: number | null
//           referral_uid: string | null
//           uid: string | null
//           user_emails: string | null
//         }
//         Insert: {
//           id?: number
//           referral_id?: number | null
//           referral_uid?: string | null
//           uid?: string | null
//           user_emails?: string | null
//         }
//         Update: {
//           id?: number
//           referral_id?: number | null
//           referral_uid?: string | null
//           uid?: string | null
//           user_emails?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_referrals_joined_users_referral_id_fkey"
//             columns: ["referral_id"]
//             isOneToOne: false
//             referencedRelation: "referrals"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_story_board_items_links: {
//         Row: {
//           id: number
//           links_uid: string | null
//           story_board_item_id: number | null
//           story_board_item_uid: string | null
//           uid: string | null
//         }
//         Insert: {
//           id?: number
//           links_uid?: string | null
//           story_board_item_id?: number | null
//           story_board_item_uid?: string | null
//           uid?: string | null
//         }
//         Update: {
//           id?: number
//           links_uid?: string | null
//           story_board_item_id?: number | null
//           story_board_item_uid?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_story_board_items_links_story_board_item_id_fkey"
//             columns: ["story_board_item_id"]
//             isOneToOne: false
//             referencedRelation: "story_board_items"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_users_buckets: {
//         Row: {
//           bucket_id: number | null
//           buckets_uid: string | null
//           id: number
//           uid: string | null
//           user_email: string | null
//           user_id: number | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           buckets_uid?: string | null
//           id?: number
//           uid?: string | null
//           user_email?: string | null
//           user_id?: number | null
//         }
//         Update: {
//           bucket_id?: number | null
//           buckets_uid?: string | null
//           id?: number
//           uid?: string | null
//           user_email?: string | null
//           user_id?: number | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_users_buckets_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "pseudos_users_buckets_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_users_cover_photos: {
//         Row: {
//           cover_photos: string | null
//           id: number
//           uid: string | null
//           user_email: string | null
//           user_id: number | null
//         }
//         Insert: {
//           cover_photos?: string | null
//           id?: number
//           uid?: string | null
//           user_email?: string | null
//           user_id?: number | null
//         }
//         Update: {
//           cover_photos?: string | null
//           id?: number
//           uid?: string | null
//           user_email?: string | null
//           user_id?: number | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_users_cover_photos_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_users_email_preferences: {
//         Row: {
//           email_type: string | null
//           id: number
//           uid: string | null
//           user_email: string | null
//           user_id: number | null
//         }
//         Insert: {
//           email_type?: string | null
//           id?: number
//           uid?: string | null
//           user_email?: string | null
//           user_id?: number | null
//         }
//         Update: {
//           email_type?: string | null
//           id?: number
//           uid?: string | null
//           user_email?: string | null
//           user_id?: number | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_users_email_preferences_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_users_followers: {
//         Row: {
//           follower_uids: string | null
//           id: number
//           uid: string | null
//           user_email: string | null
//           user_id: number | null
//         }
//         Insert: {
//           follower_uids?: string | null
//           id?: number
//           uid?: string | null
//           user_email?: string | null
//           user_id?: number | null
//         }
//         Update: {
//           follower_uids?: string | null
//           id?: number
//           uid?: string | null
//           user_email?: string | null
//           user_id?: number | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_users_followers_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       pseudos_users_referred: {
//         Row: {
//           id: number
//           referral_id: number | null
//           referral_uid: string | null
//           referred_id: number | null
//           referred_uid: string | null
//           referrer_id: number | null
//           referrer_uid: string | null
//         }
//         Insert: {
//           id?: number
//           referral_id?: number | null
//           referral_uid?: string | null
//           referred_id?: number | null
//           referred_uid?: string | null
//           referrer_id?: number | null
//           referrer_uid?: string | null
//         }
//         Update: {
//           id?: number
//           referral_id?: number | null
//           referral_uid?: string | null
//           referred_id?: number | null
//           referred_uid?: string | null
//           referrer_id?: number | null
//           referrer_uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "pseudos_users_referred_referral_id_fkey"
//             columns: ["referral_id"]
//             isOneToOne: false
//             referencedRelation: "referrals"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "pseudos_users_referred_referred_id_fkey"
//             columns: ["referred_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "pseudos_users_referred_referrer_id_fkey"
//             columns: ["referrer_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       range_os: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           img: string | null
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           img?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           img?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       recommendations: {
//         Row: {
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           last_updated: string | null
//           related_user_email: string | null
//           related_user_id: number | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           last_updated?: string | null
//           related_user_email?: string | null
//           related_user_id?: number | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           last_updated?: string | null
//           related_user_email?: string | null
//           related_user_id?: number | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "recommendations_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "recommendations_related_user_id_fkey"
//             columns: ["related_user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       recommendations_buckets: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           id: number
//           recommendation_id: number | null
//           recommendation_uid: string | null
//           uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           recommendation_id?: number | null
//           recommendation_uid?: string | null
//           uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           recommendation_id?: number | null
//           recommendation_uid?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "recommendations_buckets_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "recommendations_buckets_recommendation_id_fkey"
//             columns: ["recommendation_id"]
//             isOneToOne: false
//             referencedRelation: "recommendations"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       referrals: {
//         Row: {
//           code: string | null
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           joined_count: number | null
//           related_user_email: string | null
//           related_user_id: number | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           code?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           joined_count?: number | null
//           related_user_email?: string | null
//           related_user_id?: number | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           code?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           joined_count?: number | null
//           related_user_email?: string | null
//           related_user_id?: number | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "referrals_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "referrals_related_user_id_fkey"
//             columns: ["related_user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       referrals_joined_users: {
//         Row: {
//           id: number
//           referral_id: number | null
//           referral_uid: string | null
//           uid: string | null
//           user_id: number | null
//           user_uid: string | null
//         }
//         Insert: {
//           id?: number
//           referral_id?: number | null
//           referral_uid?: string | null
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Update: {
//           id?: number
//           referral_id?: number | null
//           referral_uid?: string | null
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "referrals_joined_users_referral_id_fkey"
//             columns: ["referral_id"]
//             isOneToOne: false
//             referencedRelation: "referrals"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "referrals_joined_users_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       sample_file_csv: {
//         Row: {
//           created_at: string | null
//           display: string
//           file: string | null
//           id: number
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           file?: string | null
//           id?: number
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           file?: string | null
//           id?: number
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       scheduled_tasks: {
//         Row: {
//           bucket_id: number | null
//           created_at: string
//           executed_at: string | null
//           id: number
//           is_executed: boolean
//           payload: Json | null
//           run_at: string
//           task_type: string
//           user_id: number
//         }
//         Insert: {
//           bucket_id?: number | null
//           created_at?: string
//           executed_at?: string | null
//           id?: never
//           is_executed?: boolean
//           payload?: Json | null
//           run_at: string
//           task_type: string
//           user_id: number
//         }
//         Update: {
//           bucket_id?: number | null
//           created_at?: string
//           executed_at?: string | null
//           id?: never
//           is_executed?: boolean
//           payload?: Json | null
//           run_at?: string
//           task_type?: string
//           user_id?: number
//         }
//         Relationships: [
//           {
//             foreignKeyName: "scheduled_tasks_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "scheduled_tasks_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       status_bar: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       story_board_items: {
//         Row: {
//           answer: string | null
//           colour: number | null
//           colour_text: string | null
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           link: boolean | null
//           picture_url: string | null
//           question: number | null
//           question_text: string | null
//           random: string | null
//           related_bucket_id: number | null
//           related_bucket_uid: string | null
//           sort_factor: number | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           answer?: string | null
//           colour?: number | null
//           colour_text?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           link?: boolean | null
//           picture_url?: string | null
//           question?: number | null
//           question_text?: string | null
//           random?: string | null
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           sort_factor?: number | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           answer?: string | null
//           colour?: number | null
//           colour_text?: string | null
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           link?: boolean | null
//           picture_url?: string | null
//           question?: number | null
//           question_text?: string | null
//           random?: string | null
//           related_bucket_id?: number | null
//           related_bucket_uid?: string | null
//           sort_factor?: number | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "story_board_items_colour_fkey"
//             columns: ["colour"]
//             isOneToOne: false
//             referencedRelation: "colours"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "story_board_items_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "story_board_items_question_fkey"
//             columns: ["question"]
//             isOneToOne: false
//             referencedRelation: "story_board_qs"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "story_board_items_related_bucket_id_fkey"
//             columns: ["related_bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       story_board_items_links: {
//         Row: {
//           id: number
//           link_id: number | null
//           link_uid: string | null
//           story_board_item_id: number | null
//           story_board_item_uid: string | null
//           uid: string | null
//         }
//         Insert: {
//           id?: number
//           link_id?: number | null
//           link_uid?: string | null
//           story_board_item_id?: number | null
//           story_board_item_uid?: string | null
//           uid?: string | null
//         }
//         Update: {
//           id?: number
//           link_id?: number | null
//           link_uid?: string | null
//           story_board_item_id?: number | null
//           story_board_item_uid?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "story_board_items_links_link_id_fkey"
//             columns: ["link_id"]
//             isOneToOne: false
//             referencedRelation: "links"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "story_board_items_links_story_board_item_id_fkey"
//             columns: ["story_board_item_id"]
//             isOneToOne: false
//             referencedRelation: "story_board_items"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       story_board_qs: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       sub_pointers: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       subscription_plan: {
//         Row: {
//           created_at: string | null
//           discounted_price: string | null
//           display: string
//           id: number
//           price: string | null
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           discounted_price?: string | null
//           display: string
//           id?: number
//           price?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           discounted_price?: string | null
//           display?: string
//           id?: number
//           price?: string | null
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       testimonials: {
//         Row: {
//           c_address: string | null
//           c_name: string | null
//           content: string | null
//           created_at: string | null
//           creater_img: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           c_address?: string | null
//           c_name?: string | null
//           content?: string | null
//           created_at?: string | null
//           creater_img?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           c_address?: string | null
//           c_name?: string | null
//           content?: string | null
//           created_at?: string | null
//           creater_img?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       tests: {
//         Row: {
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           id: number
//           image_url: string | null
//           text_content: string | null
//           uid: string | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           image_url?: string | null
//           text_content?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           created_by?: number | null
//           creator?: string | null
//           id?: number
//           image_url?: string | null
//           text_content?: string | null
//           uid?: string | null
//           updated_at?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "tests_created_by_fkey"
//             columns: ["created_by"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       title_placeholder_os: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       type_of_notifications: {
//         Row: {
//           content: string | null
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           content?: string | null
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           content?: string | null
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       user_metadata_sync: {
//         Row: {
//           auth_user_id: string
//           created_at: string
//           id: number
//           last_error: string | null
//           payload: Json
//           status: string
//           updated_at: string
//           user_id: number
//         }
//         Insert: {
//           auth_user_id: string
//           created_at?: string
//           id?: number
//           last_error?: string | null
//           payload: Json
//           status?: string
//           updated_at?: string
//           user_id: number
//         }
//         Update: {
//           auth_user_id?: string
//           created_at?: string
//           id?: number
//           last_error?: string | null
//           payload?: Json
//           status?: string
//           updated_at?: string
//           user_id?: number
//         }
//         Relationships: []
//       }
//       user_sync_queue: {
//         Row: {
//           attempts: number | null
//           auth_user_id: string | null
//           created_at: string | null
//           id: number
//           last_error: string | null
//           payload: Json | null
//           public_user_id: number | null
//           status: string | null
//           updated_at: string | null
//           user_id: string | null
//         }
//         Insert: {
//           attempts?: number | null
//           auth_user_id?: string | null
//           created_at?: string | null
//           id?: number
//           last_error?: string | null
//           payload?: Json | null
//           public_user_id?: number | null
//           status?: string | null
//           updated_at?: string | null
//           user_id?: string | null
//         }
//         Update: {
//           attempts?: number | null
//           auth_user_id?: string | null
//           created_at?: string | null
//           id?: number
//           last_error?: string | null
//           payload?: Json | null
//           public_user_id?: number | null
//           status?: string | null
//           updated_at?: string | null
//           user_id?: string | null
//         }
//         Relationships: []
//       }
//       users: {
//         Row: {
//           auth_user_id: string | null
//           bio: string | null
//           city: string | null
//           country: string | null
//           created_at: string | null
//           email: string | null
//           first_goal_added: boolean | null
//           full_name: string | null
//           goal_count_trigger: number | null
//           id: number
//           instagram: string | null
//           is_confirmed: boolean | null
//           is_onboarded: boolean | null
//           last_personalized_bucket_flow_at: string | null
//           linkedin: string | null
//           onboarding_step: number | null
//           profile_picture_url: string | null
//           slug: string | null
//           state_us_only: string | null
//           tiktok: string | null
//           uid: string | null
//           updated_at: string | null
//           welcome_email_sent: boolean | null
//           welcome_message_sent: boolean | null
//         }
//         Insert: {
//           auth_user_id?: string | null
//           bio?: string | null
//           city?: string | null
//           country?: string | null
//           created_at?: string | null
//           email?: string | null
//           first_goal_added?: boolean | null
//           full_name?: string | null
//           goal_count_trigger?: number | null
//           id?: number
//           instagram?: string | null
//           is_confirmed?: boolean | null
//           is_onboarded?: boolean | null
//           last_personalized_bucket_flow_at?: string | null
//           linkedin?: string | null
//           onboarding_step?: number | null
//           profile_picture_url?: string | null
//           slug?: string | null
//           state_us_only?: string | null
//           tiktok?: string | null
//           uid?: string | null
//           updated_at?: string | null
//           welcome_email_sent?: boolean | null
//           welcome_message_sent?: boolean | null
//         }
//         Update: {
//           auth_user_id?: string | null
//           bio?: string | null
//           city?: string | null
//           country?: string | null
//           created_at?: string | null
//           email?: string | null
//           first_goal_added?: boolean | null
//           full_name?: string | null
//           goal_count_trigger?: number | null
//           id?: number
//           instagram?: string | null
//           is_confirmed?: boolean | null
//           is_onboarded?: boolean | null
//           last_personalized_bucket_flow_at?: string | null
//           linkedin?: string | null
//           onboarding_step?: number | null
//           profile_picture_url?: string | null
//           slug?: string | null
//           state_us_only?: string | null
//           tiktok?: string | null
//           uid?: string | null
//           updated_at?: string | null
//           welcome_email_sent?: boolean | null
//           welcome_message_sent?: boolean | null
//         }
//         Relationships: []
//       }
//       users_buckets: {
//         Row: {
//           bucket_id: number | null
//           bucket_uid: string | null
//           id: number
//           sort_factor: number | null
//           uid: string | null
//           user_id: number | null
//           user_uid: string | null
//         }
//         Insert: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           sort_factor?: number | null
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Update: {
//           bucket_id?: number | null
//           bucket_uid?: string | null
//           id?: number
//           sort_factor?: number | null
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "users_buckets_bucket_id_fkey"
//             columns: ["bucket_id"]
//             isOneToOne: false
//             referencedRelation: "buckets"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "users_buckets_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       users_cover_photos: {
//         Row: {
//           cover_photo_url: string | null
//           id: number
//           uid: string | null
//           user_id: number | null
//           user_uid: string | null
//         }
//         Insert: {
//           cover_photo_url?: string | null
//           id?: number
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Update: {
//           cover_photo_url?: string | null
//           id?: number
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "users_cover_photos_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       users_email_preferences: {
//         Row: {
//           email_type: number | null
//           email_type_text: string | null
//           id: number
//           uid: string | null
//           user_id: number | null
//           user_uid: string | null
//         }
//         Insert: {
//           email_type?: number | null
//           email_type_text?: string | null
//           id?: number
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Update: {
//           email_type?: number | null
//           email_type_text?: string | null
//           id?: number
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "users_email_preferences_email_type_fkey"
//             columns: ["email_type"]
//             isOneToOne: false
//             referencedRelation: "email_type"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "users_email_preferences_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       users_followers: {
//         Row: {
//           follower_id: number | null
//           follower_uid: string | null
//           id: number
//           uid: string | null
//           user_id: number | null
//           user_uid: string | null
//         }
//         Insert: {
//           follower_id?: number | null
//           follower_uid?: string | null
//           id?: number
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Update: {
//           follower_id?: number | null
//           follower_uid?: string | null
//           id?: number
//           uid?: string | null
//           user_id?: number | null
//           user_uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "users_followers_follower_id_fkey"
//             columns: ["follower_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "users_followers_user_id_fkey"
//             columns: ["user_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       users_referred: {
//         Row: {
//           id: number
//           referral_id: number | null
//           referral_uid: string | null
//           referred_id: number | null
//           referred_uid: string | null
//           referrer_id: number | null
//           referrer_uid: string | null
//           uid: string | null
//         }
//         Insert: {
//           id?: number
//           referral_id?: number | null
//           referral_uid?: string | null
//           referred_id?: number | null
//           referred_uid?: string | null
//           referrer_id?: number | null
//           referrer_uid?: string | null
//           uid?: string | null
//         }
//         Update: {
//           id?: number
//           referral_id?: number | null
//           referral_uid?: string | null
//           referred_id?: number | null
//           referred_uid?: string | null
//           referrer_id?: number | null
//           referrer_uid?: string | null
//           uid?: string | null
//         }
//         Relationships: [
//           {
//             foreignKeyName: "users_referred_referral_id_fkey"
//             columns: ["referral_id"]
//             isOneToOne: false
//             referencedRelation: "referrals"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "users_referred_referred_id_fkey"
//             columns: ["referred_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//           {
//             foreignKeyName: "users_referred_referrer_id_fkey"
//             columns: ["referrer_id"]
//             isOneToOne: false
//             referencedRelation: "users"
//             referencedColumns: ["id"]
//           },
//         ]
//       }
//       vid_extensions: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//       what_inspired_you_to_sign_up: {
//         Row: {
//           created_at: string | null
//           display: string
//           id: number
//           sort_factor: number | null
//           updated_at: string | null
//         }
//         Insert: {
//           created_at?: string | null
//           display: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Update: {
//           created_at?: string | null
//           display?: string
//           id?: number
//           sort_factor?: number | null
//           updated_at?: string | null
//         }
//         Relationships: []
//       }
//     }
//     Views: {
//       [_ in never]: never
//     }
//     Functions: {
//       add_collaborators_to_bucket:
//         | {
//             Args: { p_bucket_id: number; p_user_ids: number[] }
//             Returns: {
//               approved_by_collaborator: boolean | null
//               approved_by_creator: boolean | null
//               created_at: string | null
//               created_by: number | null
//               creator: string | null
//               id: number
//               related_bucket_id: number | null
//               related_bucket_uid: string | null
//               related_user_email: string | null
//               related_user_id: number | null
//               uid: string | null
//               updated_at: string | null
//             }[]
//             SetofOptions: {
//               from: "*"
//               to: "collaborators"
//               isOneToOne: false
//               isSetofReturn: true
//             }
//           }
//         | {
//             Args: {
//               p_bucket_id: number
//               p_sender_id: number
//               p_user_ids: number[]
//             }
//             Returns: undefined
//           }
//       check_or_create_conversation: {
//         Args: { p_user1: number; p_user2: number }
//         Returns: number
//       }
//       clone_and_add_bucket: {
//         Args: {
//           p_current_user_id: number
//           p_mark_completed: boolean
//           p_original_bucket_id: number
//         }
//         Returns: number
//       }
//       exec_sql: { Args: { sql: string }; Returns: undefined }
//       generate_slug_from_email: { Args: { p_email: string }; Returns: string }
//       get_bucket_approved_collaborator_users: {
//         Args: { p_bucket_id: number }
//         Returns: {
//           auth_user_id: string | null
//           bio: string | null
//           city: string | null
//           country: string | null
//           created_at: string | null
//           email: string | null
//           first_goal_added: boolean | null
//           full_name: string | null
//           goal_count_trigger: number | null
//           id: number
//           instagram: string | null
//           is_confirmed: boolean | null
//           is_onboarded: boolean | null
//           last_personalized_bucket_flow_at: string | null
//           linkedin: string | null
//           onboarding_step: number | null
//           profile_picture_url: string | null
//           slug: string | null
//           state_us_only: string | null
//           tiktok: string | null
//           uid: string | null
//           updated_at: string | null
//           welcome_email_sent: boolean | null
//           welcome_message_sent: boolean | null
//         }[]
//         SetofOptions: {
//           from: "*"
//           to: "users"
//           isOneToOne: false
//           isSetofReturn: true
//         }
//       }
//       get_bucket_collaborator_users: {
//         Args: { p_bucket_id: number }
//         Returns: {
//           auth_user_id: string | null
//           bio: string | null
//           city: string | null
//           country: string | null
//           created_at: string | null
//           email: string | null
//           first_goal_added: boolean | null
//           full_name: string | null
//           goal_count_trigger: number | null
//           id: number
//           instagram: string | null
//           is_confirmed: boolean | null
//           is_onboarded: boolean | null
//           last_personalized_bucket_flow_at: string | null
//           linkedin: string | null
//           onboarding_step: number | null
//           profile_picture_url: string | null
//           slug: string | null
//           state_us_only: string | null
//           tiktok: string | null
//           uid: string | null
//           updated_at: string | null
//           welcome_email_sent: boolean | null
//           welcome_message_sent: boolean | null
//         }[]
//         SetofOptions: {
//           from: "*"
//           to: "users"
//           isOneToOne: false
//           isSetofReturn: true
//         }
//       }
//       get_bucket_partner_experts: {
//         Args: { p_bucket_id: number }
//         Returns: Json[]
//       }
//       get_buckets_sorted_for_user: {
//         Args: { p_user_id: number }
//         Returns: {
//           added_count: number
//           category: number
//           comment_count: number
//           completion_date: string
//           completion_range: string
//           created_at: string
//           created_by: number
//           creator: string
//           custom_explore: boolean
//           description: string
//           display_picture_url: string
//           experts_added: boolean
//           id: number
//           is_completed: boolean
//           is_private: boolean
//           like_count: number
//           location: string
//           related_user_email: string
//           related_user_id: number
//           services_added: boolean
//           sort_factor: number
//           storyboard: boolean
//           title: string
//           uid: string
//           updated_at: string
//           user_name: string
//         }[]
//       }
//       get_collaborators_by_bucket: {
//         Args: { p_bucket_id: number }
//         Returns: {
//           approved_by_collaborator: boolean
//           approved_by_creator: boolean
//           collaborator_id: number
//           created_at: string
//           full_name: string
//           profile_picture_url: string
//           related_user_id: number
//           slug: string
//         }[]
//       }
//       get_post_by_id: {
//         Args: { p_post_id: number }
//         Returns: {
//           goals: string[]
//           post: Database["public"]["Tables"]["posts"]["Row"]
//           related_bucket_row: Database["public"]["Tables"]["buckets"]["Row"]
//           related_user_row: Database["public"]["Tables"]["users"]["Row"]
//         }[]
//       }
//       get_posts_feed: {
//         Args: {
//           p_before_id?: number
//           p_current_user_id: number
//           p_limit?: number
//           p_related_bucket_id?: number
//         }
//         Returns: {
//           goals: string[]
//           post: Database["public"]["Tables"]["posts"]["Row"]
//           related_bucket_row: Database["public"]["Tables"]["buckets"]["Row"]
//           related_user_row: Database["public"]["Tables"]["users"]["Row"]
//         }[]
//       }
//       get_random_users:
//         | {
//             Args: never
//             Returns: {
//               completed_goal_count: number
//               total_goal_count: number
//               user_id: number
//             }[]
//           }
//         | {
//             Args: { p_current_user_id: number }
//             Returns: {
//               completed_goal_count: number
//               total_goal_count: number
//               user_id: number
//             }[]
//           }
//       get_recommended_users: {
//         Args: { p_current_user_id: number }
//         Returns: {
//           completed_goal_count: number
//           mutual_count: number
//           mutual_names: string[]
//           recommended_user_row: Json
//           total_goal_count: number
//         }[]
//       }
//       get_storyboard_and_links: {
//         Args: { p_bucket_id: number }
//         Returns: {
//           items: Json
//           links: Json
//         }[]
//       }
//       get_user_conversations: { Args: { p_user_id: number }; Returns: Json[] }
//       get_user_notifications: {
//         Args: { p_limit?: number; p_offset?: number; p_user_id: number }
//         Returns: Json[]
//       }
//       get_user_partner_experts: { Args: { p_user_id: number }; Returns: Json[] }
//       handle_signup_onboarding: {
//         Args: { p_user_id: number }
//         Returns: undefined
//       }
//       match_buckets_by_title_simple: {
//         Args: {
//           p_bucket_id: number
//           p_current_user_id: number
//           p_limit?: number
//           p_offset?: number
//         }
//         Returns: {
//           bucket_id: number
//           bucket_is_completed: boolean
//           bucket_title: string
//           creator_follows_current: boolean
//           creator_name: string
//           creator_profile_picture_url: string
//           creator_slug: string
//           creator_user_id: number
//           current_user_follows_creator: boolean
//         }[]
//       }
//       match_buckets_for_user: {
//         Args: { p_current_user_id: number; p_limit?: number; p_offset?: number }
//         Returns: {
//           bucket_id: number
//           bucket_is_completed: boolean
//           bucket_title: string
//           creator_follows_current: boolean
//           creator_name: string
//           creator_profile_picture_url: string
//           creator_slug: string
//           creator_user_id: number
//           current_user_follows_creator: boolean
//         }[]
//       }
//       match_buckets_simple: {
//         Args: {
//           p_bucket_id: number
//           p_current_user_id: number
//           p_limit?: number
//           p_offset?: number
//         }
//         Returns: {
//           bucket_id: number
//           bucket_is_completed: boolean
//           bucket_title: string
//           creator_follows_current: boolean
//           creator_name: string
//           creator_profile_picture_url: string
//           creator_slug: string
//           creator_user_id: number
//           current_user_follows_creator: boolean
//         }[]
//       }
//       reorder_novels_values: {
//         Args: { new_order: number[] }
//         Returns: undefined
//       }
//       search_buckets_by_title: {
//         Args: { p_limit?: number; p_offset?: number; p_search: string }
//         Returns: {
//           added_count: number | null
//           category: number | null
//           comment_count: number | null
//           completion_date: string | null
//           completion_range: string | null
//           created_at: string | null
//           created_by: number | null
//           creator: string | null
//           custom_explore: boolean | null
//           description: string | null
//           display_picture_url: string | null
//           experts_added: boolean | null
//           id: number
//           is_completed: boolean | null
//           is_private: boolean | null
//           is_system_bucket: boolean | null
//           like_count: number | null
//           location: string | null
//           personalized_email: boolean | null
//           related_user_email: string | null
//           related_user_id: number | null
//           services_added: boolean | null
//           storyboard: boolean | null
//           title: string | null
//           uid: string | null
//           updated_at: string | null
//           user_name: string | null
//         }[]
//         SetofOptions: {
//           from: "*"
//           to: "buckets"
//           isOneToOne: false
//           isSetofReturn: true
//         }
//       }
//       search_posts_feed: {
//         Args: {
//           p_before_id?: number
//           p_current_user_id: number
//           p_limit?: number
//           p_related_bucket_id?: number
//           p_search_string: string
//         }
//         Returns: {
//           goals: string[]
//           post: Database["public"]["Tables"]["posts"]["Row"]
//           related_bucket_row: Database["public"]["Tables"]["buckets"]["Row"]
//           related_user_row: Database["public"]["Tables"]["users"]["Row"]
//         }[]
//       }
//       search_users_by_full_name: {
//         Args: { p_search_string: string }
//         Returns: {
//           auth_user_id: string | null
//           bio: string | null
//           city: string | null
//           country: string | null
//           created_at: string | null
//           email: string | null
//           first_goal_added: boolean | null
//           full_name: string | null
//           goal_count_trigger: number | null
//           id: number
//           instagram: string | null
//           is_confirmed: boolean | null
//           is_onboarded: boolean | null
//           last_personalized_bucket_flow_at: string | null
//           linkedin: string | null
//           onboarding_step: number | null
//           profile_picture_url: string | null
//           slug: string | null
//           state_us_only: string | null
//           tiktok: string | null
//           uid: string | null
//           updated_at: string | null
//           welcome_email_sent: boolean | null
//           welcome_message_sent: boolean | null
//         }[]
//         SetofOptions: {
//           from: "*"
//           to: "users"
//           isOneToOne: false
//           isSetofReturn: true
//         }
//       }
//       start_bucket_email_flow: {
//         Args: { p_base_time?: string; p_bucket_id: number; p_user_id: number }
//         Returns: undefined
//       }
//       start_or_continue_conversation: {
//         Args: {
//           p_body: string
//           p_bucket_id: number
//           p_receiver: number
//           p_sender: number
//         }
//         Returns: undefined
//       }
//       unaccent: { Args: { "": string }; Returns: string }
//       update_novel_order: { Args: { id_list: string }; Returns: undefined }
//       update_story_board_items_order_by_bucket: {
//         Args: { id_list: string }
//         Returns: Json
//       }
//       update_users_buckets_order: { Args: { id_list: string }; Returns: Json }
//     }
//     Enums: {
//       [_ in never]: never
//     }
//     CompositeTypes: {
//       [_ in never]: never
//     }
//   }
// }

// type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

// type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

// export type Tables<
//   DefaultSchemaTableNameOrOptions extends
//     | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
//     | { schema: keyof DatabaseWithoutInternals },
//   TableName extends DefaultSchemaTableNameOrOptions extends {
//     schema: keyof DatabaseWithoutInternals
//   }
//     ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
//         DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
//     : never = never,
// > = DefaultSchemaTableNameOrOptions extends {
//   schema: keyof DatabaseWithoutInternals
// }
//   ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
//       DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
//       Row: infer R
//     }
//     ? R
//     : never
//   : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
//         DefaultSchema["Views"])
//     ? (DefaultSchema["Tables"] &
//         DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
//         Row: infer R
//       }
//       ? R
//       : never
//     : never

// export type TablesInsert<
//   DefaultSchemaTableNameOrOptions extends
//     | keyof DefaultSchema["Tables"]
//     | { schema: keyof DatabaseWithoutInternals },
//   TableName extends DefaultSchemaTableNameOrOptions extends {
//     schema: keyof DatabaseWithoutInternals
//   }
//     ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
//     : never = never,
// > = DefaultSchemaTableNameOrOptions extends {
//   schema: keyof DatabaseWithoutInternals
// }
//   ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
//       Insert: infer I
//     }
//     ? I
//     : never
//   : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
//     ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
//         Insert: infer I
//       }
//       ? I
//       : never
//     : never

// export type TablesUpdate<
//   DefaultSchemaTableNameOrOptions extends
//     | keyof DefaultSchema["Tables"]
//     | { schema: keyof DatabaseWithoutInternals },
//   TableName extends DefaultSchemaTableNameOrOptions extends {
//     schema: keyof DatabaseWithoutInternals
//   }
//     ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
//     : never = never,
// > = DefaultSchemaTableNameOrOptions extends {
//   schema: keyof DatabaseWithoutInternals
// }
//   ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
//       Update: infer U
//     }
//     ? U
//     : never
//   : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
//     ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
//         Update: infer U
//       }
//       ? U
//       : never
//     : never

// export type Enums<
//   DefaultSchemaEnumNameOrOptions extends
//     | keyof DefaultSchema["Enums"]
//     | { schema: keyof DatabaseWithoutInternals },
//   EnumName extends DefaultSchemaEnumNameOrOptions extends {
//     schema: keyof DatabaseWithoutInternals
//   }
//     ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
//     : never = never,
// > = DefaultSchemaEnumNameOrOptions extends {
//   schema: keyof DatabaseWithoutInternals
// }
//   ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
//   : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
//     ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
//     : never

// export type CompositeTypes<
//   PublicCompositeTypeNameOrOptions extends
//     | keyof DefaultSchema["CompositeTypes"]
//     | { schema: keyof DatabaseWithoutInternals },
//   CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
//     schema: keyof DatabaseWithoutInternals
//   }
//     ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
//     : never = never,
// > = PublicCompositeTypeNameOrOptions extends {
//   schema: keyof DatabaseWithoutInternals
// }
//   ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
//   : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
//     ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
//     : never

// export const Constants = {
//   public: {
//     Enums: {},
//   },
// } as const
