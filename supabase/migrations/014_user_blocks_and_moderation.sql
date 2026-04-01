-- 014_user_blocks_and_moderation.sql
-- User blocking, content hiding on report, and admin moderation (MBA-218)

-- =============================================================================
-- TABLE: user_blocks
-- =============================================================================

CREATE TABLE user_blocks (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    blocked_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (blocker_id, blocked_id)
);

ALTER TABLE user_blocks
    ADD CONSTRAINT chk_no_self_block
    CHECK (blocker_id != blocked_id);

CREATE INDEX idx_user_blocks_blocker ON user_blocks(blocker_id);
CREATE INDEX idx_user_blocks_blocked ON user_blocks(blocked_id);

-- =============================================================================
-- TABLE: hidden_encounters
-- =============================================================================

CREATE TABLE hidden_encounters (
    user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    encounter_id UUID NOT NULL REFERENCES encounters(id) ON DELETE CASCADE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, encounter_id)
);

-- =============================================================================
-- HELPER: is_blocked (bidirectional check)
-- =============================================================================

CREATE OR REPLACE FUNCTION is_blocked(user_a UUID, user_b UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_blocks
        WHERE (blocker_id = user_a AND blocked_id = user_b)
           OR (blocker_id = user_b AND blocked_id = user_a)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public;

-- =============================================================================
-- UPDATE: can_view_user() — add block check
-- =============================================================================

CREATE OR REPLACE FUNCTION can_view_user(target_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- always can view own content
    IF target_user_id = auth.uid() THEN
        RETURN TRUE;
    END IF;

    -- blocked users cannot see each other
    IF is_blocked(auth.uid(), target_user_id) THEN
        RETURN FALSE;
    END IF;

    -- suspended users are hidden from everyone
    IF EXISTS (
        SELECT 1 FROM profiles
        WHERE id = target_user_id AND is_suspended = TRUE
    ) THEN
        RETURN FALSE;
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
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public;

-- =============================================================================
-- UPDATE: get_feed() — filter blocked users and hidden encounters
-- =============================================================================

CREATE OR REPLACE FUNCTION get_feed(
    p_cursor TIMESTAMPTZ DEFAULT NULL,
    p_cursor_id UUID DEFAULT NULL,
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
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF (p_cursor IS NULL) != (p_cursor_id IS NULL) THEN
        RAISE EXCEPTION 'p_cursor and p_cursor_id must both be provided or both be NULL';
    END IF;

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
              AND el.user_id = v_uid
        )                   AS is_liked,
        (e.id = (
            SELECT e2.id FROM encounters e2
            WHERE e2.cat_id = e.cat_id
            ORDER BY e2.date ASC
            LIMIT 1
        ))                  AS is_first_encounter,
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
        e.owner_id = v_uid
        OR (
            EXISTS (
                SELECT 1 FROM follows f
                WHERE f.follower_id = v_uid
                  AND f.followee_id = e.owner_id
                  AND f.status = 'active'
            )
            AND p.show_encounters = TRUE
        )
    )
    -- exclude blocked users
    AND NOT is_blocked(v_uid, e.owner_id)
    -- exclude suspended users (except own content)
    AND (e.owner_id = v_uid OR p.is_suspended = FALSE)
    -- exclude encounters hidden by this user
    AND NOT EXISTS (
        SELECT 1 FROM hidden_encounters he
        WHERE he.user_id = v_uid
          AND he.encounter_id = e.id
    )
    AND (p_cursor IS NULL OR (e.date, e.id) < (p_cursor, p_cursor_id))
    ORDER BY e.date DESC, e.id DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public;

-- =============================================================================
-- PROFILES: add is_suspended column
-- =============================================================================

ALTER TABLE profiles ADD COLUMN is_suspended BOOLEAN NOT NULL DEFAULT FALSE;

-- =============================================================================
-- ENCOUNTER_REPORTS: add admin moderation columns
-- =============================================================================

-- Expand allowed status values
ALTER TABLE encounter_reports DROP CONSTRAINT chk_report_status;

ALTER TABLE encounter_reports
    ADD CONSTRAINT chk_report_status
    CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed'));

ALTER TABLE encounter_reports ADD COLUMN admin_action TEXT;
ALTER TABLE encounter_reports ADD COLUMN admin_notes TEXT NOT NULL DEFAULT '';
ALTER TABLE encounter_reports ADD COLUMN resolved_at TIMESTAMPTZ;

ALTER TABLE encounter_reports
    ADD CONSTRAINT chk_admin_action
    CHECK (admin_action IS NULL OR admin_action IN ('dismiss', 'hide_content', 'warn_user', 'suspend_user'));

-- =============================================================================
-- AUTO-HIDE: trigger to hide encounters with 3+ reports
-- =============================================================================

CREATE OR REPLACE FUNCTION auto_hide_reported_encounter()
RETURNS TRIGGER AS $$
DECLARE
    v_report_count INT;
BEGIN
    SELECT COUNT(*) INTO v_report_count
    FROM encounter_reports
    WHERE encounter_id = NEW.encounter_id;

    IF v_report_count >= 3 THEN
        -- Mark all existing reports as reviewed with auto-hide action
        UPDATE encounter_reports
        SET status = 'reviewed',
            admin_action = 'hide_content',
            admin_notes = 'auto-hidden: reached 3 report threshold',
            resolved_at = now()
        WHERE encounter_id = NEW.encounter_id
          AND status = 'pending';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER trg_auto_hide_reported_encounter
    AFTER INSERT ON encounter_reports
    FOR EACH ROW
    EXECUTE FUNCTION auto_hide_reported_encounter();

-- =============================================================================
-- RLS: user_blocks
-- =============================================================================

ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_blocks_select ON user_blocks
    FOR SELECT USING (blocker_id = auth.uid());

CREATE POLICY user_blocks_insert ON user_blocks
    FOR INSERT WITH CHECK (blocker_id = auth.uid());

CREATE POLICY user_blocks_delete ON user_blocks
    FOR DELETE USING (blocker_id = auth.uid());

-- =============================================================================
-- RLS: hidden_encounters
-- =============================================================================

ALTER TABLE hidden_encounters ENABLE ROW LEVEL SECURITY;

CREATE POLICY hidden_encounters_select ON hidden_encounters
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY hidden_encounters_insert ON hidden_encounters
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY hidden_encounters_delete ON hidden_encounters
    FOR DELETE USING (user_id = auth.uid());
