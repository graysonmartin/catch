-- 002_rls_policies.sql
-- Row Level Security policies for Catch
-- Part of MBA-146: CloudKit → Supabase migration

-- =============================================================================
-- HELPER FUNCTION: can_view_user()
-- =============================================================================

-- Returns true if the current user can view the target user's content.
-- True when: target is self, target is public, or current user actively follows target.
-- SECURITY DEFINER so it can read profiles/follows regardless of caller's RLS context.
CREATE OR REPLACE FUNCTION can_view_user(target_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- always can view own content
    IF target_user_id = auth.uid() THEN
        RETURN TRUE;
    END IF;

    -- public profiles are visible to everyone
    IF EXISTS (
        SELECT 1 FROM profiles
        WHERE id = target_user_id AND is_private = FALSE
    ) THEN
        RETURN TRUE;
    END IF;

    -- active followers can view private profiles
    IF EXISTS (
        SELECT 1 FROM follows
        WHERE follower_id = auth.uid()
          AND followee_id = target_user_id
          AND status = 'active'
    ) THEN
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- =============================================================================
-- ENABLE RLS ON ALL TABLES
-- =============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cats ENABLE ROW LEVEL SECURITY;
ALTER TABLE encounters ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE encounter_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE encounter_comments ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- PROFILES
-- =============================================================================

-- anyone can see profiles (name, avatar, etc. are public metadata)
CREATE POLICY profiles_select ON profiles
    FOR SELECT USING (TRUE);

-- users can only insert their own profile
CREATE POLICY profiles_insert ON profiles
    FOR INSERT WITH CHECK (id = auth.uid());

-- users can only update their own profile
CREATE POLICY profiles_update ON profiles
    FOR UPDATE USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- users can only delete their own profile (cascade cleans up everything)
CREATE POLICY profiles_delete ON profiles
    FOR DELETE USING (id = auth.uid());

-- =============================================================================
-- CATS
-- =============================================================================

-- viewable if own OR (can view user AND user has show_cats enabled)
CREATE POLICY cats_select ON cats
    FOR SELECT USING (
        owner_id = auth.uid()
        OR (
            can_view_user(owner_id)
            AND EXISTS (
                SELECT 1 FROM profiles
                WHERE id = owner_id AND show_cats = TRUE
            )
        )
    );

CREATE POLICY cats_insert ON cats
    FOR INSERT WITH CHECK (owner_id = auth.uid());

CREATE POLICY cats_update ON cats
    FOR UPDATE USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY cats_delete ON cats
    FOR DELETE USING (owner_id = auth.uid());

-- =============================================================================
-- ENCOUNTERS
-- =============================================================================

-- viewable if own OR (can view user AND user has show_encounters enabled)
CREATE POLICY encounters_select ON encounters
    FOR SELECT USING (
        owner_id = auth.uid()
        OR (
            can_view_user(owner_id)
            AND EXISTS (
                SELECT 1 FROM profiles
                WHERE id = owner_id AND show_encounters = TRUE
            )
        )
    );

CREATE POLICY encounters_insert ON encounters
    FOR INSERT WITH CHECK (owner_id = auth.uid());

CREATE POLICY encounters_update ON encounters
    FOR UPDATE USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY encounters_delete ON encounters
    FOR DELETE USING (owner_id = auth.uid());

-- =============================================================================
-- FOLLOWS
-- =============================================================================

-- visible to either party in the follow relationship
CREATE POLICY follows_select ON follows
    FOR SELECT USING (
        follower_id = auth.uid() OR followee_id = auth.uid()
    );

-- users can only create follows where they are the follower
CREATE POLICY follows_insert ON follows
    FOR INSERT WITH CHECK (follower_id = auth.uid());

-- followee can update status (approve/decline pending requests)
CREATE POLICY follows_update ON follows
    FOR UPDATE USING (followee_id = auth.uid())
    WITH CHECK (followee_id = auth.uid());

-- follower can unfollow, followee can remove a follower
CREATE POLICY follows_delete ON follows
    FOR DELETE USING (
        follower_id = auth.uid() OR followee_id = auth.uid()
    );

-- =============================================================================
-- ENCOUNTER LIKES
-- =============================================================================

-- viewable if the parent encounter is viewable
CREATE POLICY encounter_likes_select ON encounter_likes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM encounters
            WHERE id = encounter_id
        )
    );

-- authenticated users can like (must use own user_id)
CREATE POLICY encounter_likes_insert ON encounter_likes
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- users can only remove their own likes
CREATE POLICY encounter_likes_delete ON encounter_likes
    FOR DELETE USING (user_id = auth.uid());

-- =============================================================================
-- ENCOUNTER COMMENTS
-- =============================================================================

-- viewable if the parent encounter is viewable
CREATE POLICY encounter_comments_select ON encounter_comments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM encounters
            WHERE id = encounter_id
        )
    );

-- authenticated users can comment (must use own user_id)
CREATE POLICY encounter_comments_insert ON encounter_comments
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- users can only edit their own comments
CREATE POLICY encounter_comments_update ON encounter_comments
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- users can only delete their own comments
CREATE POLICY encounter_comments_delete ON encounter_comments
    FOR DELETE USING (user_id = auth.uid());
