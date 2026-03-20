-- 009_notifications.sql
-- Notifications table and event-to-notification pipeline triggers (MBA-205)

-- =============================================================================
-- TABLE
-- =============================================================================

CREATE TABLE notifications (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_user_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_type  TEXT NOT NULL,
    entity_type        TEXT NOT NULL,
    entity_id          UUID NOT NULL,
    actor_id           UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    collapse_key       TEXT,
    payload            JSONB NOT NULL DEFAULT '{}'::jsonb,
    delivery_status    TEXT NOT NULL DEFAULT 'pending',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    delivered_at       TIMESTAMPTZ
);

-- =============================================================================
-- CONSTRAINTS
-- =============================================================================

ALTER TABLE notifications
    ADD CONSTRAINT chk_notifications_delivery_status
    CHECK (delivery_status IN ('pending', 'sent', 'failed', 'invalid_token'));

ALTER TABLE notifications
    ADD CONSTRAINT chk_notifications_notification_type
    CHECK (notification_type IN ('encounter_liked', 'encounter_commented'));

-- =============================================================================
-- INDEXES
-- =============================================================================

CREATE INDEX idx_notifications_recipient ON notifications(recipient_user_id);
CREATE INDEX idx_notifications_delivery_status ON notifications(delivery_status);
CREATE INDEX idx_notifications_collapse_key ON notifications(collapse_key);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY notifications_select ON notifications
    FOR SELECT USING (auth.uid() = recipient_user_id);

CREATE POLICY notifications_update ON notifications
    FOR UPDATE USING (auth.uid() = recipient_user_id);

-- =============================================================================
-- TRIGGER FUNCTION: create notification on like/comment
-- =============================================================================

-- Creates a notification row when a like or comment is inserted.
-- Self-actions are filtered out (no notification when you like your own encounter).
-- Collapse-key deduplication prevents duplicate notifications within a 5-minute window.
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

    -- Insert the notification
    INSERT INTO notifications (
        recipient_user_id,
        notification_type,
        entity_type,
        entity_id,
        actor_id,
        collapse_key,
        payload
    ) VALUES (
        v_encounter_owner_id,
        v_notification_type,
        v_entity_type,
        v_encounter_id,
        NEW.user_id,
        v_collapse_key,
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

-- =============================================================================
-- TRIGGERS: fire on like/comment insert
-- =============================================================================

CREATE TRIGGER trg_notify_on_like
    AFTER INSERT ON encounter_likes
    FOR EACH ROW EXECUTE FUNCTION create_notification_on_social_event();

CREATE TRIGGER trg_notify_on_comment
    AFTER INSERT ON encounter_comments
    FOR EACH ROW EXECUTE FUNCTION create_notification_on_social_event();
