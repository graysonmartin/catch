-- 012_notifications_fk_to_profiles_encounters.sql
-- Add foreign keys so PostgREST can resolve joins for the in-app notification query.

-- actor_id currently references auth.users; add a parallel FK to profiles
-- so `profiles!notifications_actor_profile_fkey` works in select queries.
ALTER TABLE notifications
    ADD CONSTRAINT notifications_actor_profile_fkey
    FOREIGN KEY (actor_id) REFERENCES profiles(id) ON DELETE SET NULL;

-- entity_id has no FK; add one to encounters for the thumbnail join.
ALTER TABLE notifications
    ADD CONSTRAINT notifications_encounter_fkey
    FOREIGN KEY (entity_id) REFERENCES encounters(id) ON DELETE CASCADE;
