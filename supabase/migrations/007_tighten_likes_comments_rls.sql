-- 007_tighten_likes_comments_rls.sql
-- Tighten RLS on encounter_likes and encounter_comments
-- Part of MBA-166: Supabase security audit
--
-- Previously, the SELECT policies only checked that the parent encounter existed.
-- This allowed reading likes/comments on encounters belonging to private users
-- if the encounter ID was known. Now the policies reuse the same visibility logic
-- as the encounters table: own content, OR can_view_user() + show_encounters.

-- =============================================================================
-- ENCOUNTER LIKES — replace SELECT policy
-- =============================================================================

DROP POLICY encounter_likes_select ON encounter_likes;

CREATE POLICY encounter_likes_select ON encounter_likes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM encounters e
            WHERE e.id = encounter_id
              AND (
                  e.owner_id = auth.uid()
                  OR (
                      can_view_user(e.owner_id)
                      AND EXISTS (
                          SELECT 1 FROM profiles p
                          WHERE p.id = e.owner_id AND p.show_encounters = TRUE
                      )
                  )
              )
        )
    );

-- =============================================================================
-- ENCOUNTER COMMENTS — replace SELECT policy
-- =============================================================================

DROP POLICY encounter_comments_select ON encounter_comments;

CREATE POLICY encounter_comments_select ON encounter_comments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM encounters e
            WHERE e.id = encounter_id
              AND (
                  e.owner_id = auth.uid()
                  OR (
                      can_view_user(e.owner_id)
                      AND EXISTS (
                          SELECT 1 FROM profiles p
                          WHERE p.id = e.owner_id AND p.show_encounters = TRUE
                      )
                  )
              )
        )
    );
