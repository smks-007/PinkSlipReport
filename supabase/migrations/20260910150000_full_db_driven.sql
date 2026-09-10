-- ═══════════════════════════════════════════════════════════════════
-- Migration: Full Database-Driven App — New Tables & Seed Data
-- Date: 2026-09-10
-- Description: Create promotions, alumni_archive, academic_calendar
--              tables and seed with real data for Sep-Dec 2026.
-- ═══════════════════════════════════════════════════════════════════

-- ──────────────── 1. Academic Calendar ────────────────

CREATE TABLE IF NOT EXISTS academic_calendar (
    calendar_id SERIAL PRIMARY KEY,
    event_date DATE NOT NULL UNIQUE,
    event_type VARCHAR(30) NOT NULL CHECK (event_type IN ('HOLIDAY', 'EXAM', 'REVISION', 'WORKING', 'SPECIAL')),
    event_name VARCHAR(200) NOT NULL,
    is_working_day BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed: 2026 Sep-Dec College Holidays
INSERT INTO academic_calendar (event_date, event_type, event_name, is_working_day) VALUES
('2026-09-04', 'HOLIDAY', 'Ganesh Chaturthi (State Holiday)', FALSE),
('2026-09-16', 'HOLIDAY', 'Milad-un-Nabi (Govt Holiday)', FALSE),
('2026-10-02', 'HOLIDAY', 'Gandhi Jayanti (National Holiday)', FALSE),
('2026-10-19', 'HOLIDAY', 'Ayudha Puja (Festival Leave)', FALSE),
('2026-10-20', 'HOLIDAY', 'Vijayadasami (Festival Holiday)', FALSE),
('2026-11-08', 'HOLIDAY', 'Diwali Celebration (College Leave)', FALSE),
('2026-12-21', 'EXAM', 'End Semester Exam Begins', TRUE),
('2026-12-25', 'HOLIDAY', 'Christmas (National Holiday)', FALSE),
('2026-12-31', 'EXAM', 'End Semester Exam Ends', TRUE)
ON CONFLICT (event_date) DO NOTHING;

-- ──────────────── 2. Promotions ────────────────

CREATE TABLE IF NOT EXISTS promotions (
    promotion_id SERIAL PRIMARY KEY,
    from_year INT NOT NULL CHECK (from_year BETWEEN 1 AND 4),
    to_year INT NOT NULL CHECK (to_year BETWEEN 2 AND 5),
    section VARCHAR(5) NOT NULL,
    batch_year VARCHAR(20) NOT NULL,
    semester_completed INT NOT NULL,
    semester_end_date DATE NOT NULL,
    grace_transition_days INT NOT NULL DEFAULT 7,
    eligible_promotion_date DATE NOT NULL,
    total_students INT NOT NULL,
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

-- Seed: 3 existing promotion requests
INSERT INTO promotions (from_year, to_year, section, batch_year, semester_completed, semester_end_date, grace_transition_days, eligible_promotion_date, total_students, status, advisor_name, advisor_remarks, date_forwarded_by_advisor) VALUES
(2, 3, 'A', '2025 BATCH', 4, '2026-08-30', 8, '2026-09-07', 63, 'PENDING_ADVISOR',
 'Dr. D. Anandhan', 'All 63 students have cleared practical assessments and attendance minimum (75%+ average). Ready to forward to HOD.', NULL),
(3, 4, 'B', '2024 BATCH', 6, '2026-08-28', 10, '2026-09-07', 61, 'FORWARDED_TO_HOD',
 'Dr. R. Murugesan', 'Verified 6th Semester credits, mini-project submissions, and Anna University exam registrations. Strongly recommended for final year promotion.', '2026-09-06 10:00:00+05:30'),
(4, 5, 'A', '2023 BATCH', 8, '2026-06-15', 14, '2026-06-29', 59, 'FORWARDED_TO_HOD',
 'Dr. P. Muthusamy', 'All 59 students completed 8th Semester project viva and external exams. Full cohort eligible for degree conferral.', '2026-09-01 10:00:00+05:30')
ON CONFLICT DO NOTHING;

-- ──────────────── 3. Alumni Archive ────────────────

CREATE TABLE IF NOT EXISTS alumni_archive (
    archive_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id) ON DELETE SET NULL,
    student_name VARCHAR(100) NOT NULL,
    roll_number VARCHAR(20) NOT NULL,
    section VARCHAR(5) NOT NULL,
    batch_year VARCHAR(20) NOT NULL,
    graduation_date DATE NOT NULL,
    retention_period_years INT NOT NULL DEFAULT 2,
    retention_expiry_date DATE NOT NULL,
    cumulative_attendance NUMERIC(5,2) DEFAULT 0.0,
    total_ods_attended INT DEFAULT 0,
    is_purged BOOLEAN DEFAULT FALSE,
    purged_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed: Example alumni records (2024 graduated batch — already expired per 2-year retention)
INSERT INTO alumni_archive (student_name, roll_number, section, batch_year, graduation_date, retention_period_years, retention_expiry_date, cumulative_attendance, total_ods_attended, is_purged, purged_at) VALUES
('ARUN KUMAR S', '22243001', 'A', '2022 BATCH', '2024-06-15', 2, '2026-06-15', 91.5, 4, TRUE, '2026-06-16 00:00:00+05:30'),
('DIVYA R', '22243010', 'A', '2022 BATCH', '2024-06-15', 2, '2026-06-15', 88.2, 2, TRUE, '2026-06-16 00:00:00+05:30'),
('KARTHIK M', '22243025', 'B', '2022 BATCH', '2024-06-15', 2, '2026-06-15', 94.0, 5, TRUE, '2026-06-16 00:00:00+05:30'),
-- 2025 graduated batch — still within retention window
('PRIYA S', '22243040', 'A', '2025 BATCH', '2025-06-15', 2, '2027-06-15', 92.1, 3, FALSE, NULL),
('SATHISH R', '22243055', 'B', '2025 BATCH', '2025-06-15', 2, '2027-06-15', 89.8, 1, FALSE, NULL)
ON CONFLICT DO NOTHING;

-- ──────────────── 4. Indexes ────────────────

CREATE INDEX IF NOT EXISTS idx_academic_calendar_date ON academic_calendar(event_date);
CREATE INDEX IF NOT EXISTS idx_promotions_status ON promotions(status);
CREATE INDEX IF NOT EXISTS idx_alumni_batch ON alumni_archive(batch_year);
CREATE INDEX IF NOT EXISTS idx_alumni_purged ON alumni_archive(is_purged);

-- ──────────────── 5. Auto-update triggers ────────────────

CREATE OR REPLACE FUNCTION update_promotions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_promotions_updated_at ON promotions;
CREATE TRIGGER trg_promotions_updated_at
    BEFORE UPDATE ON promotions
    FOR EACH ROW EXECUTE FUNCTION update_promotions_updated_at();
