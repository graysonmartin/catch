-- 008_device_tokens.sql
-- APNs device token storage for push notifications (MBA-204)

-- =============================================================================
-- TABLE
-- =============================================================================

CREATE TABLE device_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token       TEXT NOT NULL,
    environment TEXT NOT NULL DEFAULT 'sandbox',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- CONSTRAINTS
-- =============================================================================

ALTER TABLE device_tokens
    ADD CONSTRAINT device_tokens_token_unique UNIQUE (token);

ALTER TABLE device_tokens
    ADD CONSTRAINT chk_device_tokens_environment
    CHECK (environment IN ('sandbox', 'production'));

-- =============================================================================
-- INDEXES
-- =============================================================================

CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Users can manage their own tokens
CREATE POLICY device_tokens_select ON device_tokens
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY device_tokens_insert ON device_tokens
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY device_tokens_update ON device_tokens
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY device_tokens_delete ON device_tokens
    FOR DELETE USING (auth.uid() = user_id);

-- Service role bypasses RLS automatically for delivery function reads

-- =============================================================================
-- TRIGGER: updated_at (reuse existing set_updated_at function from 001)
-- =============================================================================

CREATE TRIGGER trg_device_tokens_updated_at
    BEFORE UPDATE ON device_tokens
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
