-- 006_link_apple_signin.sql
-- Link Apple Sign-In with pre-migrated accounts
-- Part of MBA-160: Edge function to link Apple Sign-In with pre-migrated accounts
--
-- Beta tester accounts were migrated from CloudKit to Supabase by pre-creating
-- email-based auth entries and inserting profiles + follow relationships. When
-- these users sign in with Apple, Supabase creates a new OAuth auth entry with
-- a different UUID, orphaning the pre-created profile and follows.
--
-- This migration creates a function + trigger that fires on new auth.users
-- inserts. If the new user's email matches an existing pre-created (email
-- provider) auth entry, it reassigns the old profile and follows to the new
-- UUID and deletes the orphaned auth entry — all within a single transaction.
--
-- APPROACH: Since FKs use ON DELETE CASCADE but not ON UPDATE CASCADE, we
-- cannot simply UPDATE profiles.id. Instead we:
--   1. Temporarily clear the UNIQUE username on the old profile
--   2. Insert a new profile row with the new UUID (copying old profile data)
--   3. Reassign all child-table FK references from old UUID to new UUID
--   4. Delete the old profile (now has no children, cascade is harmless)
--   5. Delete the orphaned pre-created auth entry

-- =============================================================================
-- FUNCTION: link_precreated_account()
-- =============================================================================

CREATE OR REPLACE FUNCTION link_precreated_account()
RETURNS TRIGGER AS $$
DECLARE
    v_old_id       UUID;
    v_new_id       UUID := NEW.id;
    v_email        TEXT := NEW.email;
    v_old_username TEXT;
BEGIN
    -- Only act on OAuth sign-ups (Apple, Google) — not email/password sign-ups.
    -- Pre-created accounts use the 'email' provider, so we skip those.
    IF NEW.raw_app_meta_data->>'provider' = 'email' THEN
        RETURN NEW;
    END IF;

    -- Skip if no email (shouldn't happen for Apple Sign-In but defensive)
    IF v_email IS NULL OR v_email = '' THEN
        RETURN NEW;
    END IF;

    -- Find a pre-created auth entry with the same email and 'email' provider.
    -- Exclude the current row (the newly inserted OAuth user).
    SELECT id INTO v_old_id
    FROM auth.users
    WHERE email = v_email
      AND id != v_new_id
      AND raw_app_meta_data->>'provider' = 'email'
    LIMIT 1;

    -- No matching pre-created account — nothing to link
    IF v_old_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Check if the old ID actually has a profile to migrate.
    -- If there's no profile, the pre-created entry has no data worth linking.
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = v_old_id) THEN
        RETURN NEW;
    END IF;

    -- Already linked: the new user already has a profile (shouldn't happen,
    -- but defensive)
    IF EXISTS (SELECT 1 FROM public.profiles WHERE id = v_new_id) THEN
        RETURN NEW;
    END IF;

    -- =========================================================================
    -- REASSIGN: move all data from old UUID to new UUID
    -- =========================================================================

    -- 1. Save and temporarily clear the username on the old profile to avoid
    --    UNIQUE constraint violation when inserting the new profile
    SELECT username INTO v_old_username
    FROM public.profiles WHERE id = v_old_id;

    UPDATE public.profiles
    SET username = '__migrating_' || v_old_id::TEXT
    WHERE id = v_old_id;

    -- 2. Create new profile with the new UUID, copying all fields from old
    INSERT INTO public.profiles (
        id, display_name, username, bio, is_private,
        show_cats, show_encounters, avatar_url,
        follower_count, following_count, created_at, updated_at
    )
    SELECT
        v_new_id, display_name, v_old_username, bio, is_private,
        show_cats, show_encounters, avatar_url,
        follower_count, following_count, created_at, now()
    FROM public.profiles
    WHERE id = v_old_id;

    -- 3. Reassign cats to new profile
    UPDATE public.cats SET owner_id = v_new_id WHERE owner_id = v_old_id;

    -- 4. Reassign encounters to new profile
    UPDATE public.encounters SET owner_id = v_new_id WHERE owner_id = v_old_id;

    -- 5. Reassign follow relationships (both directions)
    UPDATE public.follows SET follower_id = v_new_id WHERE follower_id = v_old_id;
    UPDATE public.follows SET followee_id = v_new_id WHERE followee_id = v_old_id;

    -- 6. Reassign encounter likes
    UPDATE public.encounter_likes SET user_id = v_new_id WHERE user_id = v_old_id;

    -- 7. Reassign encounter comments
    UPDATE public.encounter_comments SET user_id = v_new_id WHERE user_id = v_old_id;

    -- 8. Delete old profile (no children reference it anymore)
    DELETE FROM public.profiles WHERE id = v_old_id;

    -- 9. Delete the orphaned pre-created auth entry
    DELETE FROM auth.users WHERE id = v_old_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = auth, public;

-- =============================================================================
-- TRIGGER: fire after a new auth user is created
-- =============================================================================

CREATE TRIGGER trg_link_precreated_account
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION link_precreated_account();

-- =============================================================================
-- RPC: link_precreated_account_rpc()
-- =============================================================================
-- Callable from the Edge Function for manual/remediation linking.
-- Returns a JSON object with the result of the linking operation.

CREATE OR REPLACE FUNCTION link_precreated_account_rpc(
    p_new_id UUID,
    p_email  TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_old_id       UUID;
    v_old_username TEXT;
BEGIN
    -- Find a pre-created auth entry with the same email and 'email' provider
    SELECT id INTO v_old_id
    FROM auth.users
    WHERE email = p_email
      AND id != p_new_id
      AND raw_app_meta_data->>'provider' = 'email'
    LIMIT 1;

    -- No matching pre-created account
    IF v_old_id IS NULL THEN
        RETURN jsonb_build_object(
            'linked', FALSE,
            'new_id', p_new_id,
            'email', p_email,
            'reason', 'no_matching_precreated_account'
        );
    END IF;

    -- No profile to migrate
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = v_old_id) THEN
        RETURN jsonb_build_object(
            'linked', FALSE,
            'old_id', v_old_id,
            'new_id', p_new_id,
            'email', p_email,
            'reason', 'no_profile_on_precreated_account'
        );
    END IF;

    -- Already has a profile (already linked or concurrent sign-up)
    IF EXISTS (SELECT 1 FROM public.profiles WHERE id = p_new_id) THEN
        RETURN jsonb_build_object(
            'linked', FALSE,
            'old_id', v_old_id,
            'new_id', p_new_id,
            'email', p_email,
            'reason', 'already_linked'
        );
    END IF;

    -- Save and temporarily clear the username to avoid UNIQUE violation
    SELECT username INTO v_old_username
    FROM public.profiles WHERE id = v_old_id;

    UPDATE public.profiles
    SET username = '__migrating_' || v_old_id::TEXT
    WHERE id = v_old_id;

    -- Create new profile with the new UUID
    INSERT INTO public.profiles (
        id, display_name, username, bio, is_private,
        show_cats, show_encounters, avatar_url,
        follower_count, following_count, created_at, updated_at
    )
    SELECT
        p_new_id, display_name, v_old_username, bio, is_private,
        show_cats, show_encounters, avatar_url,
        follower_count, following_count, created_at, now()
    FROM public.profiles
    WHERE id = v_old_id;

    -- Reassign all child-table references
    UPDATE public.cats SET owner_id = p_new_id WHERE owner_id = v_old_id;
    UPDATE public.encounters SET owner_id = p_new_id WHERE owner_id = v_old_id;
    UPDATE public.follows SET follower_id = p_new_id WHERE follower_id = v_old_id;
    UPDATE public.follows SET followee_id = p_new_id WHERE followee_id = v_old_id;
    UPDATE public.encounter_likes SET user_id = p_new_id WHERE user_id = v_old_id;
    UPDATE public.encounter_comments SET user_id = p_new_id WHERE user_id = v_old_id;

    -- Delete old profile and orphaned auth entry
    DELETE FROM public.profiles WHERE id = v_old_id;
    DELETE FROM auth.users WHERE id = v_old_id;

    RETURN jsonb_build_object(
        'linked', TRUE,
        'old_id', v_old_id,
        'new_id', p_new_id,
        'email', p_email,
        'reason', 'successfully_linked'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = auth, public;
