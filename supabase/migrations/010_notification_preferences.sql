-- 010_notification_preferences.sql
-- Notification preferences and eligibility checks (MBA-207)

-- =============================================================================
-- TABLE
-- =============================================================================

CREATE TABLE notification_preferences (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    likes_enabled    BOOLEAN NOT NULL DEFAULT true,
    comments_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- CONSTRAINTS
-- =============================================================================

ALTER TABLE notification_preferences
    ADD CONSTRAINT notification_preferences_user_unique UNIQUE (user_id);

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY notification_preferences_select ON notification_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY notification_preferences_insert ON notification_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY notification_preferences_update ON notification_preferences
    FOR UPDATE USING (auth.uid() = user_id);

-- =============================================================================
-- TRIGGER: updated_at (reuse existing set_updated_at function from 001)
-- =============================================================================

CREATE TRIGGER trg_notification_preferences_updated_at
    BEFORE UPDATE ON notification_preferences
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- UPDATE NOTIFICATION TRIGGER: add preference checks
-- =============================================================================

-- Replace the notification trigger function to include preference eligibility.
-- If the recipient has preferences set and the relevant type is disabled, skip.
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
