-- 006_encounter_reports.sql
-- Add encounter reporting for App Store guideline 1.2 compliance (MBA-167)

-- =============================================================================
-- TABLE
-- =============================================================================

CREATE TABLE encounter_reports (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id UUID NOT NULL REFERENCES encounters(id) ON DELETE CASCADE,
    reporter_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category     TEXT NOT NULL,
    reason       TEXT NOT NULL DEFAULT '',
    status       TEXT NOT NULL DEFAULT 'pending',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (encounter_id, reporter_id)
);

-- =============================================================================
-- CONSTRAINTS (separated for easy modification)
-- =============================================================================

ALTER TABLE encounter_reports
    ADD CONSTRAINT chk_report_category
    CHECK (category IN ('spam', 'inappropriate', 'harassment', 'other'));

ALTER TABLE encounter_reports
    ADD CONSTRAINT chk_report_status
    CHECK (status IN ('pending', 'reviewed', 'resolved'));

-- =============================================================================
-- INDEXES
-- =============================================================================

CREATE INDEX idx_encounter_reports_status ON encounter_reports(status);
CREATE INDEX idx_encounter_reports_encounter ON encounter_reports(encounter_id);

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE encounter_reports ENABLE ROW LEVEL SECURITY;

-- Users can insert reports (must be their own reporter_id)
CREATE POLICY encounter_reports_insert ON encounter_reports
    FOR INSERT WITH CHECK (reporter_id = auth.uid());

-- Users can only see their own reports
CREATE POLICY encounter_reports_select ON encounter_reports
    FOR SELECT USING (reporter_id = auth.uid());

-- No update/delete by regular users — admin manages via dashboard
