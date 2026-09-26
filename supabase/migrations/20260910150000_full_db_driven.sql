-- ═══════════════════════════════════════════════════════════════════
-- Migration: Full Database-Driven App — Dynamic Tables & Procedures
-- Date: 2026-09-10
-- Description: Create promotions, alumni_archive, academic_calendar
--              with Google Calendar dynamic sync, procedures & RLS policies.
-- ═══════════════════════════════════════════════════════════════════

-- ──────────────── 1. Academic Calendar (Dynamic Google Calendar Ready) ────────────────

CREATE TABLE IF NOT EXISTS academic_calendar (
    calendar_id SERIAL PRIMARY KEY,
    event_date DATE NOT NULL UNIQUE,
    event_type VARCHAR(30) NOT NULL DEFAULT 'HOLIDAY' CHECK (event_type IN ('HOLIDAY', 'EXAM', 'REVISION', 'WORKING', 'SPECIAL')),
    event_name VARCHAR(200) NOT NULL,
    description TEXT,
    google_event_id VARCHAR(255),
    source VARCHAR(50) DEFAULT 'GOOGLE_CALENDAR',
    is_working_day BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ──────────────── 2. Promotions (Dynamic Schema) ────────────────

CREATE TABLE IF NOT EXISTS promotions (
    promotion_id SERIAL PRIMARY KEY,
    from_year INT NOT NULL CHECK (from_year BETWEEN 1 AND 4),
    to_year INT NOT NULL CHECK (to_year BETWEEN 2 AND 5),
    section VARCHAR(15) NOT NULL,
    batch_year VARCHAR(30) NOT NULL,
    semester_completed INT NOT NULL,
    semester_end_date DATE NOT NULL,
    grace_transition_days INT NOT NULL DEFAULT 7,
    eligible_promotion_date DATE NOT NULL,
    total_students INT NOT NULL DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING_ADVISOR' CHECK (status IN (
        'PENDING_ADVISOR', 'FORWARDED_TO_HOD', 'APPROVED_BY_HOD', 'REJECTED'
    )),
    advisor_name VARCHAR(100),
    advisor_remarks TEXT,
    date_forwarded_by_advisor TIMESTAMP WITH TIME ZONE,
    hod_name VARCHAR(100),
    hod_remarks TEXT,
    date_approved_by_hod TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ──────────────── 3. Alumni Archive (Dynamic Schema) ────────────────

CREATE TABLE IF NOT EXISTS alumni_archive (
    archive_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id) ON DELETE SET NULL,
    student_name VARCHAR(100) NOT NULL,
    roll_number VARCHAR(20) NOT NULL,
    section VARCHAR(15) NOT NULL,
    batch_year VARCHAR(30) NOT NULL,
    graduation_date DATE NOT NULL,
    retention_period_years INT NOT NULL DEFAULT 2,
    retention_expiry_date DATE NOT NULL,
    cumulative_attendance NUMERIC(5,2) DEFAULT 0.0,
    total_ods_attended INT DEFAULT 0,
    is_purged BOOLEAN DEFAULT FALSE,
    purged_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ──────────────── 4. Indexes ────────────────

CREATE INDEX IF NOT EXISTS idx_academic_calendar_date ON academic_calendar(event_date);
CREATE INDEX IF NOT EXISTS idx_academic_calendar_gid ON academic_calendar(google_event_id);
CREATE INDEX IF NOT EXISTS idx_promotions_status ON promotions(status);
CREATE INDEX IF NOT EXISTS idx_alumni_batch ON alumni_archive(batch_year);
CREATE INDEX IF NOT EXISTS idx_alumni_purged ON alumni_archive(is_purged);
CREATE INDEX IF NOT EXISTS idx_alumni_roll ON alumni_archive(roll_number);

-- ──────────────── 5. Auto-update triggers ────────────────

CREATE OR REPLACE FUNCTION update_timestamp_column_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_promotions_updated_at ON promotions;
CREATE TRIGGER trg_promotions_updated_at
    BEFORE UPDATE ON promotions
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column_updated_at();

DROP TRIGGER IF EXISTS trg_calendar_updated_at ON academic_calendar;
CREATE TRIGGER trg_calendar_updated_at
    BEFORE UPDATE ON academic_calendar
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_column_updated_at();

-- ──────────────── 6. Dynamic Procedure: Archive Graduated Cohort ────────────────

CREATE OR REPLACE FUNCTION archive_graduated_cohort(
    p_section_id VARCHAR,
    p_batch_year VARCHAR,
    p_grad_date DATE DEFAULT CURRENT_DATE,
    p_retention_years INT DEFAULT 2
)
RETURNS INT AS $$
DECLARE
    v_count INT := 0;
BEGIN
    INSERT INTO alumni_archive (
        student_id,
        student_name,
        roll_number,
        section,
        batch_year,
        graduation_date,
        retention_period_years,
        retention_expiry_date,
        cumulative_attendance,
        total_ods_attended
    )
    SELECT
        s.student_id,
        s.student_name,
        s.roll_number,
        COALESCE(s.section_id, p_section_id),
        p_batch_year,
        p_grad_date,
        p_retention_years,
        p_grad_date + (p_retention_years || ' years')::INTERVAL,
        -- Calculate real cumulative attendance rate dynamically
        COALESCE(
            ROUND(
                (COUNT(CASE WHEN da.is_present = TRUE THEN 1 END)::NUMERIC /
                 NULLIF(COUNT(da.attendance_id), 0)) * 100,
                2
            ),
            100.0
        ),
        -- Count real approved OD slips dynamically
        COALESCE(
            (SELECT COUNT(*) FROM leave_slips ls
             WHERE ls.student_id = s.student_id AND ls.slip_type = 'OD' AND ls.status = 'APPROVED'),
            0
        )
    FROM students s
    LEFT JOIN daily_attendance da ON s.student_id = da.student_id
    WHERE s.section_id = p_section_id
    GROUP BY s.student_id, s.student_name, s.roll_number, s.section_id
    ON CONFLICT DO NOTHING;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- ──────────────── 7. Row Level Security (RLS) & Permissions ────────────────

ALTER TABLE academic_calendar ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_academic_calendar" ON academic_calendar;
CREATE POLICY "public_all_academic_calendar" ON academic_calendar FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "authenticated_all_promotions" ON promotions;
CREATE POLICY "authenticated_all_promotions" ON promotions FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE alumni_archive ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "authenticated_all_alumni" ON alumni_archive;
CREATE POLICY "authenticated_all_alumni" ON alumni_archive FOR ALL USING (true) WITH CHECK (true);

-- Ensure anon & authenticated roles have full access for PostgREST API
GRANT ALL ON academic_calendar TO anon, authenticated, service_role;
GRANT ALL ON promotions TO anon, authenticated, service_role;
GRANT ALL ON alumni_archive TO anon, authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE academic_calendar_calendar_id_seq TO anon, authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE promotions_promotion_id_seq TO anon, authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE alumni_archive_archive_id_seq TO anon, authenticated, service_role;
