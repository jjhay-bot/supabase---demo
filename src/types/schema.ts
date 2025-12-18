// TypeScript type definition for the collaborators table

export interface Collaborator {
  id: number;
  uid?: string | null;
  related_user_id?: number | null;
  related_bucket_id?: number | null;
  approved_by_creator?: boolean | null;
  approved_by_collaborator?: boolean | null;
  creator?: string | null;
  created_by?: number | null;
  created_at?: string | null; // ISO timestamp
  updated_at?: string | null; // ISO timestamp
  related_user_email?: string | null;
  related_bucket_uid?: string | null;
}
