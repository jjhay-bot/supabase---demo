# Quick Table Reference: Main Entities

## users
- Represents a person with an account in the system.
- Primary key: id
- Used as the main reference for ownership, creation, and relationships.

## buckets
- Represents a wish, goal, or project (e.g., "Travel to Japan").
- Primary key: id
- Key fields: related_user_id (owner), created_by (creator)
- Can have many collaborators.

## collaborators
- Represents a user collaborating on a specific bucket.
- Primary key: id
- related_user_id: The user who is a collaborator.
- related_bucket_id: The bucket they are collaborating on.
- created_by: The user who added the collaborator.
- A user is only a collaborator if there is a row linking them to a bucket.

## posts
- Represents a post or update, usually linked to a bucket and a user.
- Primary key: id
- related_user_id: The user who made the post.
- related_bucket_id: The bucket the post is about.

## follows
- Represents a user following another user.
- Primary key: id
- following_id: The user being followed.
- followed_by_id: The user who is following.
- Many-to-many self-referencing relationship on users.

---

### Relationship Symbols (Mermaid ERD)
- `||--o{` : One-to-many (one user, many collaborators)
- `o{--||` : Many-to-one (many collaborators, one user)
- `|o--o|` : One-to-one (rare)

---

For lookup tables (like *_os, *_type, etc.), these are usually static lists referenced by other tables via foreign keys.

Add more details as your schema evolves!
