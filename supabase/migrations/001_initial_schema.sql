-- 001_initial_schema.sql
-- Initial PostgreSQL schema for Catch (replaces CloudKit record types)
-- Part of MBA-146: CloudKit → Supabase migration

-- =============================================================================
-- TABLES
-- =============================================================================

-- profiles: user identity and settings (PK = auth.uid())
CREATE TABLE profiles (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL DEFAULT '',
    username    TEXT NOT NULL UNIQUE,
    bio         TEXT NOT NULL DEFAULT '',
    is_private  BOOLEAN NOT NULL DEFAULT FALSE,
    show_cats   BOOLEAN NOT NULL DEFAULT TRUE,
    show_encounters BOOLEAN NOT NULL DEFAULT TRUE,
    avatar_url  TEXT,
    follower_count  INT NOT NULL DEFAULT 0,
    following_count INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- cats: registered cats belonging to a user
CREATE TABLE cats (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    breed       TEXT,
    estimated_age TEXT,
    location_name TEXT,
    location_lat  DOUBLE PRECISION,
    location_lng  DOUBLE PRECISION,
    notes       TEXT,
    is_owned    BOOLEAN NOT NULL DEFAULT FALSE,
    photo_urls  TEXT[] NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- encounters: sighting/interaction logs tied to a cat
CREATE TABLE encounters (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    cat_id      UUID NOT NULL REFERENCES cats(id) ON DELETE CASCADE,
    date        TIMESTAMPTZ NOT NULL DEFAULT now(),
    location_name TEXT,
    location_lat  DOUBLE PRECISION,
    location_lng  DOUBLE PRECISION,
    notes       TEXT,
    photo_urls  TEXT[] NOT NULL DEFAULT '{}',
    like_count  INT NOT NULL DEFAULT 0,
    comment_count INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- follows: follower/followee relationships with pending/active status
CREATE TABLE follows (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    followee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status      TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'pending')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (follower_id, followee_id),
    CHECK (follower_id != followee_id)
);

-- encounter_likes: one like per user per encounter
CREATE TABLE encounter_likes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id UUID NOT NULL REFERENCES encounters(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (encounter_id, user_id)
);

-- encounter_comments: threaded comments on encounters
CREATE TABLE encounter_comments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id UUID NOT NULL REFERENCES encounters(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    text        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- INDEXES
-- =============================================================================

-- feed query: user's encounters sorted by date
CREATE INDEX idx_encounters_owner_date ON encounters (owner_id, date DESC);

-- cat detail: all encounters for a cat
CREATE INDEX idx_encounters_cat_id ON encounters (cat_id);

-- user's cat list
CREATE INDEX idx_cats_owner_id ON cats (owner_id);

-- "who do I follow?" (active follows only)
CREATE INDEX idx_follows_follower_status ON follows (follower_id, status);

-- "who follows me?" (active follows only)
CREATE INDEX idx_follows_followee_status ON follows (followee_id, status);

-- like aggregation per encounter
CREATE INDEX idx_encounter_likes_encounter ON encounter_likes (encounter_id);

-- paginated comments per encounter
CREATE INDEX idx_encounter_comments_encounter_date ON encounter_comments (encounter_id, created_at);

-- feed pagination sort across all owners
CREATE INDEX idx_encounters_date_id_desc ON encounters (date DESC, id DESC);

-- is_first_encounter subquery: first encounter per cat by date
CREATE INDEX idx_encounters_cat_date_asc ON encounters (cat_id, date ASC, id);

-- =============================================================================
-- TRIGGERS: updated_at auto-update
-- =============================================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_cats_updated_at
    BEFORE UPDATE ON cats
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_encounters_updated_at
    BEFORE UPDATE ON encounters
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_follows_updated_at
    BEFORE UPDATE ON follows
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_encounter_comments_updated_at
    BEFORE UPDATE ON encounter_comments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- TRIGGERS: denormalized like_count on encounters
-- =============================================================================

CREATE OR REPLACE FUNCTION adjust_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE encounters SET like_count = like_count + 1
        WHERE id = NEW.encounter_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE encounters SET like_count = GREATEST(0, like_count - 1)
        WHERE id = OLD.encounter_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER trg_like_count
    AFTER INSERT OR DELETE ON encounter_likes
    FOR EACH ROW EXECUTE FUNCTION adjust_like_count();

-- =============================================================================
-- TRIGGERS: denormalized comment_count on encounters
-- =============================================================================

CREATE OR REPLACE FUNCTION adjust_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE encounters SET comment_count = comment_count + 1
        WHERE id = NEW.encounter_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE encounters SET comment_count = GREATEST(0, comment_count - 1)
        WHERE id = OLD.encounter_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER trg_comment_count
    AFTER INSERT OR DELETE ON encounter_comments
    FOR EACH ROW EXECUTE FUNCTION adjust_comment_count();

-- =============================================================================
-- TRIGGERS: denormalized follower_count / following_count on profiles
-- =============================================================================

CREATE OR REPLACE FUNCTION adjust_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.status = 'active' THEN
            UPDATE profiles SET following_count = following_count + 1
            WHERE id = NEW.follower_id;
            UPDATE profiles SET follower_count = follower_count + 1
            WHERE id = NEW.followee_id;
        END IF;
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.status = 'active' THEN
            UPDATE profiles SET following_count = GREATEST(0, following_count - 1)
            WHERE id = OLD.follower_id;
            UPDATE profiles SET follower_count = GREATEST(0, follower_count - 1)
            WHERE id = OLD.followee_id;
        END IF;
        RETURN OLD;

    ELSIF TG_OP = 'UPDATE' THEN
        -- pending → active: increment both counts
        IF OLD.status = 'pending' AND NEW.status = 'active' THEN
            UPDATE profiles SET following_count = following_count + 1
            WHERE id = NEW.follower_id;
            UPDATE profiles SET follower_count = follower_count + 1
            WHERE id = NEW.followee_id;
        -- active → pending: decrement both counts (unlikely but defensive)
        ELSIF OLD.status = 'active' AND NEW.status = 'pending' THEN
            UPDATE profiles SET following_count = GREATEST(0, following_count - 1)
            WHERE id = NEW.follower_id;
            UPDATE profiles SET follower_count = GREATEST(0, follower_count - 1)
            WHERE id = NEW.followee_id;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER trg_follow_counts
    AFTER INSERT OR UPDATE OR DELETE ON follows
    FOR EACH ROW EXECUTE FUNCTION adjust_follow_counts();
