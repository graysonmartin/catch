-- 013_follow_notifications.sql
-- Add follow notification support (MBA-210)

-- =============================================================================
-- UPDATE CHECK CONSTRAINT: add new_follower type
-- =============================================================================

ALTER TABLE notifications
    DROP CONSTRAINT chk_notifications_notification_type;

ALTER TABLE notifications
    ADD CONSTRAINT chk_notifications_notification_type
    CHECK (notification_type IN ('encounter_liked', 'encounter_commented', 'new_follower'));

-- =============================================================================
-- ADD follows_enabled preference
-- =============================================================================

ALTER TABLE notification_preferences
    ADD COLUMN follows_enabled BOOLEAN NOT NULL DEFAULT true;

-- =============================================================================
-- NULLABLE encounter_id COLUMN
-- =============================================================================

-- Add a dedicated nullable encounter_id column for the PostgREST encounter join.
-- For encounter notifications this mirrors entity_id; for follow notifications it is NULL.
-- The existing entity_id stays as the generic reference (encounter or profile UUID).

ALTER TABLE notifications
    ADD COLUMN encounter_id UUID;

ALTER TABLE notifications
    ADD CONSTRAINT notifications_encounter_id_fkey
    FOREIGN KEY (encounter_id) REFERENCES encounters(id) ON DELETE CASCADE;

-- Backfill: copy entity_id into encounter_id for existing encounter notifications.
UPDATE notifications
SET encounter_id = entity_id
WHERE notification_type IN ('encounter_liked', 'encounter_commented');

-- Drop the old FK from entity_id to encounters (added in migration 012).
-- entity_id is now a generic UUID that may reference encounters or profiles.
ALTER TABLE notifications
    DROP CONSTRAINT notifications_encounter_fkey;

CREATE INDEX IF NOT EXISTS idx_notifications_encounter_id ON notifications(encounter_id);

-- =============================================================================
-- TRIGGER FUNCTION: create notification on follow
-- =============================================================================

CREATE OR REPLACE FUNCTION create_notification_on_follow()
RETURNS TRIGGER AS $$
DECLARE
    v_actor_display_name TEXT;
    v_collapse_key TEXT;
    v_pref_enabled BOOLEAN;
BEGIN
    -- Only fire on active follows (not pending)
    IF NEW.status != 'active' THEN
        RETURN NEW;
    END IF;

    -- The follows table already has CHECK (follower_id != followee_id),
    -- so self-follow is impossible at the DB level. Guard anyway.
    IF NEW.follower_id = NEW.followee_id THEN
        RETURN NEW;
    END IF;

    -- Check notification preferences (default to enabled if no row exists)
    SELECT follows_enabled INTO v_pref_enabled
    FROM notification_preferences
    WHERE user_id = NEW.followee_id;

    IF v_pref_enabled IS NOT NULL AND v_pref_enabled = FALSE THEN
        RETURN NEW;
    END IF;

    -- Build collapse key: prevent duplicate follow notifications within 5 minutes
    v_collapse_key := NEW.follower_id::TEXT || ':' || NEW.followee_id::TEXT || ':new_follower';

    IF EXISTS (
        SELECT 1 FROM notifications
        WHERE collapse_key = v_collapse_key
          AND created_at > now() - INTERVAL '5 minutes'
    ) THEN
        RETURN NEW;
    END IF;

    -- Get actor display name
    SELECT display_name INTO v_actor_display_name
    FROM profiles
    WHERE id = NEW.follower_id;

    -- Insert the notification (encounter_id is NULL for follow notifications)
    INSERT INTO notifications (
        recipient_user_id,
        notification_type,
        entity_type,
        entity_id,
        actor_id,
        collapse_key,
        encounter_id,
        payload
    ) VALUES (
        NEW.followee_id,
        'new_follower',
        'follow',
        NEW.follower_id,
        NEW.follower_id,
        v_collapse_key,
        NULL,
        jsonb_build_object(
            'actor_display_name', COALESCE(v_actor_display_name, 'someone'),
            'follower_id', NEW.follower_id
        )
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- =============================================================================
-- TRIGGER: fire on follow insert
-- =============================================================================

CREATE TRIGGER trg_notify_on_follow
    AFTER INSERT ON follows
    FOR EACH ROW EXECUTE FUNCTION create_notification_on_follow();

-- =============================================================================
-- UPDATE SOCIAL EVENT TRIGGER: populate encounter_id column
-- =============================================================================

CREATE OR REPLACE FUNCTION create_notification_on_social_event()
RETURNS TRIGGER AS $$
DECLARE
    v_encounter_owner_id UUID;
    v_notification_type TEXT;
    v_entity_type TEXT;
    v_collapse_key TEXT;
    v_actor_display_name TEXT;
    v_cat_name TEXT;
    v_encounter_id UUID;
    v_pref_enabled BOOLEAN;
BEGIN
    -- Determine event type based on source table
    IF TG_TABLE_NAME = 'encounter_likes' THEN
        v_notification_type := 'encounter_liked';
        v_entity_type := 'encounter_like';
        v_encounter_id := NEW.encounter_id;
    ELSIF TG_TABLE_NAME = 'encounter_comments' THEN
        v_notification_type := 'encounter_commented';
        v_entity_type := 'encounter_comment';
        v_encounter_id := NEW.encounter_id;
    ELSE
        RETURN NEW;
    END IF;

    -- Get the encounter owner
    SELECT owner_id INTO v_encounter_owner_id
    FROM encounters
    WHERE id = v_encounter_id;

    -- Skip if encounter not found
    IF v_encounter_owner_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Skip self-actions (don't notify when you interact with your own encounter)
    IF NEW.user_id = v_encounter_owner_id THEN
        RETURN NEW;
    END IF;

    -- Check notification preferences (default to enabled if no row exists)
    IF v_notification_type = 'encounter_liked' THEN
        SELECT likes_enabled INTO v_pref_enabled
        FROM notification_preferences
        WHERE user_id = v_encounter_owner_id;
    ELSIF v_notification_type = 'encounter_commented' THEN
        SELECT comments_enabled INTO v_pref_enabled
        FROM notification_preferences
        WHERE user_id = v_encounter_owner_id;
    END IF;

    -- If preference exists and is disabled, skip notification
    IF v_pref_enabled IS NOT NULL AND v_pref_enabled = FALSE THEN
        RETURN NEW;
    END IF;

    -- Build collapse key: same actor + entity + type within dedup window
    v_collapse_key := NEW.user_id::TEXT || ':' || v_encounter_id::TEXT || ':' || v_notification_type;

    -- Check collapse-key deduplication (same key within 5 minutes = skip)
    IF EXISTS (
        SELECT 1 FROM notifications
        WHERE collapse_key = v_collapse_key
          AND created_at > now() - INTERVAL '5 minutes'
    ) THEN
        RETURN NEW;
    END IF;

    -- Get actor display name for payload
    SELECT display_name INTO v_actor_display_name
    FROM profiles
    WHERE id = NEW.user_id;

    -- Get cat name for payload
    SELECT c.name INTO v_cat_name
    FROM encounters e
    JOIN cats c ON c.id = e.cat_id
    WHERE e.id = v_encounter_id;

    -- Insert the notification (encounter_id is set for encounter-based notifications)
    INSERT INTO notifications (
        recipient_user_id,
        notification_type,
        entity_type,
        entity_id,
        actor_id,
        collapse_key,
        encounter_id,
        payload
    ) VALUES (
        v_encounter_owner_id,
        v_notification_type,
        v_entity_type,
        v_encounter_id,
        NEW.user_id,
        v_collapse_key,
        v_encounter_id,
        jsonb_build_object(
            'actor_display_name', COALESCE(v_actor_display_name, 'someone'),
            'cat_name', COALESCE(v_cat_name, 'a cat'),
            'encounter_id', v_encounter_id
        )
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;
