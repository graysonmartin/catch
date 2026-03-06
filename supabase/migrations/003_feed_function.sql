-- 003_feed_function.sql
-- Feed RPC function for Catch
-- Part of MBA-146: CloudKit → Supabase migration

-- Returns a paginated feed of encounters from followed users + self.
-- Uses denormalized counts (no aggregation), cursor-based pagination on date.
-- SECURITY DEFINER to bypass RLS and apply custom visibility logic internally.

CREATE OR REPLACE FUNCTION get_feed(
    p_cursor TIMESTAMPTZ DEFAULT NULL,
    p_limit  INT DEFAULT 20
)
RETURNS TABLE (
    encounter_id    UUID,
    encounter_date  TIMESTAMPTZ,
    encounter_notes TEXT,
    encounter_photo_urls TEXT[],
    encounter_location_name TEXT,
    encounter_location_lat  DOUBLE PRECISION,
    encounter_location_lng  DOUBLE PRECISION,
    encounter_created_at    TIMESTAMPTZ,
    like_count      INT,
    comment_count   INT,
    is_liked        BOOLEAN,
    is_first_encounter BOOLEAN,
    cat_id          UUID,
    cat_name        TEXT,
    cat_breed       TEXT,
    cat_photo_urls  TEXT[],
    owner_id        UUID,
    owner_display_name TEXT,
    owner_username  TEXT,
    owner_avatar_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.id                AS encounter_id,
        e.date              AS encounter_date,
        e.notes             AS encounter_notes,
        e.photo_urls        AS encounter_photo_urls,
        e.location_name     AS encounter_location_name,
        e.location_lat      AS encounter_location_lat,
        e.location_lng      AS encounter_location_lng,
        e.created_at        AS encounter_created_at,
        e.like_count,
        e.comment_count,
        EXISTS (
            SELECT 1 FROM encounter_likes el
            WHERE el.encounter_id = e.id
              AND el.user_id = auth.uid()
        )                   AS is_liked,
        (ROW_NUMBER() OVER (
            PARTITION BY e.cat_id
            ORDER BY e.date ASC
        ) = 1)              AS is_first_encounter,
        c.id                AS cat_id,
        c.name              AS cat_name,
        c.breed             AS cat_breed,
        c.photo_urls        AS cat_photo_urls,
        p.id                AS owner_id,
        p.display_name      AS owner_display_name,
        p.username          AS owner_username,
        p.avatar_url        AS owner_avatar_url
    FROM encounters e
    JOIN cats c ON c.id = e.cat_id
    JOIN profiles p ON p.id = e.owner_id
    WHERE (
        -- own encounters always visible
        e.owner_id = auth.uid()
        OR (
            -- encounters from actively followed users
            EXISTS (
                SELECT 1 FROM follows f
                WHERE f.follower_id = auth.uid()
                  AND f.followee_id = e.owner_id
                  AND f.status = 'active'
            )
            -- respect visibility settings
            AND p.show_encounters = TRUE
        )
    )
    -- cursor-based pagination
    AND (p_cursor IS NULL OR e.date < p_cursor)
    ORDER BY e.date DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
