-- PinkSlipReport: Official Supabase PostgreSQL DDL, Triggers & RLS Policies
-- PRODUCTION-HARDENED: No anonymous access, role-based enforcement

-- ──────────────────── ENUMS ────────────────────
CREATE TYPE user_role AS ENUM ('HOD', 'ADVISOR', 'STUDENT');
CREATE TYPE leave_type AS ENUM ('INFORMED', 'UNINFORMED', 'OD', 'MEDICAL');
CREATE TYPE slip_status AS ENUM ('SUBMITTED', 'PENDING_HOD', 'APPROVED', 'REJECTED');
CREATE TYPE punch_source AS ENUM ('BIOMETRIC_FINGERPRINT', 'FACE_DETECTION', 'MANUAL_OVERRIDE');

-- ──────────────────── TABLES ────────────────────

CREATE TABLE IF NOT EXISTS sections (
    section_id VARCHAR(15) PRIMARY KEY,
    year INT NOT NULL CHECK (year BETWEEN 1 AND 4),
    section_name CHAR(1) NOT NULL CHECK (section_name IN ('A', 'B', 'C', 'D')),
    department VARCHAR(60) DEFAULT 'Artificial Intelligence and Data Science',
    total_strength INT DEFAULT 0,
    academic_year VARCHAR(20) DEFAULT '2026-2027',
    CONSTRAINT valid_section_distribution CHECK (
        (year IN (1, 2, 3) AND section_name IN ('A', 'B', 'C', 'D')) OR
        (year = 4 AND section_name IN ('A', 'B'))
    )
);

CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    auth_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    full_name VARCHAR(100) NOT NULL,
    role user_role NOT NULL,
    phone_number VARCHAR(20),
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staff_advisors (
    staff_id INT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    staff_code VARCHAR(20) UNIQUE NOT NULL,
    assigned_section VARCHAR(15) REFERENCES sections(section_id) ON DELETE SET NULL,
    designation VARCHAR(50) DEFAULT 'Assistant Professor',
    cabin_location VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS students (
    student_id INT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    roll_number VARCHAR(20) UNIQUE NOT NULL,
    register_number VARCHAR(20) UNIQUE NOT NULL,
    section_id VARCHAR(15) REFERENCES sections(section_id) ON DELETE RESTRICT,
    guardian_name VARCHAR(100),
    guardian_contact VARCHAR(20),
    leaves_taken_ytd INT DEFAULT 0,
    face_encoding TEXT
);

CREATE TABLE IF NOT EXISTS daily_attendance (
    attendance_id BIGSERIAL PRIMARY KEY,
    student_id INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL,
    is_present BOOLEAN NOT NULL DEFAULT FALSE,
    leave_type leave_type DEFAULT NULL,
    in_time TIME,
    out_time TIME,
    punch_method punch_source DEFAULT 'BIOMETRIC_FINGERPRINT',
    marked_by INT NOT NULL REFERENCES users(user_id),
    marked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_student_daily_record UNIQUE (student_id, attendance_date)
);

CREATE TABLE IF NOT EXISTS biometric_punches (
    punch_id BIGSERIAL PRIMARY KEY,
    student_id INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    punch_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    punch_type VARCHAR(10) NOT NULL CHECK (punch_type IN ('IN', 'OUT')),
    source punch_source NOT NULL,
    device_id VARCHAR(50) DEFAULT 'BIO-GATE-01',
    confidence_score NUMERIC(5, 2) DEFAULT 98.50,
    is_overridden BOOLEAN DEFAULT FALSE,
    override_reason TEXT,
    modified_by INT REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS leave_slips (
    slip_id BIGSERIAL PRIMARY KEY,
    student_id INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    from_date DATE NOT NULL,
    to_date DATE NOT NULL,
    is_informed BOOLEAN DEFAULT TRUE,
    letter_document_url TEXT,
    letter_submitted_to_advisor_date TIMESTAMP WITH TIME ZONE,
    forwarded_to_hod_date TIMESTAMP WITH TIME ZONE,
    due_date DATE,
    status slip_status DEFAULT 'SUBMITTED',
    advisor_remarks TEXT,
    hod_remarks TEXT,
    approved_by_hod_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_logs (
    log_id BIGSERIAL PRIMARY KEY,
    actor_id INT NOT NULL REFERENCES users(user_id),
    action VARCHAR(50) NOT NULL,
    target_table VARCHAR(50) NOT NULL,
    target_id VARCHAR(50) NOT NULL,
    old_data JSONB,
    new_data JSONB,
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ──────────────────── INDEXES ────────────────────

CREATE INDEX IF NOT EXISTS idx_attendance_date ON daily_attendance(attendance_date);
CREATE INDEX IF NOT EXISTS idx_attendance_student ON daily_attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_student_date ON daily_attendance(student_id, attendance_date);
CREATE INDEX IF NOT EXISTS idx_leave_slips_student ON leave_slips(student_id);
CREATE INDEX IF NOT EXISTS idx_leave_slips_status ON leave_slips(status);
CREATE INDEX IF NOT EXISTS idx_leave_slips_created ON leave_slips(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_biometric_student_time ON biometric_punches(student_id, punch_timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON audit_logs(actor_id, performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_students_section ON students(section_id);
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON users(auth_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- ──────────────────── ROW LEVEL SECURITY (RLS) ────────────────────
-- PRODUCTION POLICY: No anonymous access. Role-based enforcement.

ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_advisors ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE biometric_punches ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_slips ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Helper function: Get current user's role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role AS $$
  SELECT role FROM users WHERE auth_id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper function: Get current user's assigned section (for advisors)
CREATE OR REPLACE FUNCTION get_advisor_section()
RETURNS VARCHAR(15) AS $$
  SELECT sa.assigned_section
  FROM staff_advisors sa
  JOIN users u ON sa.staff_id = u.user_id
  WHERE u.auth_id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper function: Get current user's student_id (for students)
CREATE OR REPLACE FUNCTION get_student_id()
RETURNS INT AS $$
  SELECT s.student_id
  FROM students s
  JOIN users u ON s.student_id = u.user_id
  WHERE u.auth_id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ─── SECTIONS: All authenticated users can read
CREATE POLICY "auth_read_sections" ON sections FOR SELECT TO authenticated USING (true);

-- ─── USERS: Authenticated users can read all user profiles (non-sensitive metadata)
CREATE POLICY "auth_read_users" ON users FOR SELECT TO authenticated USING (true);

-- ─── STAFF_ADVISORS: Authenticated users can read advisor assignments
CREATE POLICY "auth_read_advisors" ON staff_advisors FOR SELECT TO authenticated USING (true);

-- ─── STUDENTS: Role-based access
-- HODs can see all students
CREATE POLICY "hod_read_all_students" ON students FOR SELECT TO authenticated
  USING (get_user_role() = 'HOD');
-- Advisors can see only their section's students
CREATE POLICY "advisor_read_section_students" ON students FOR SELECT TO authenticated
  USING (get_user_role() = 'ADVISOR' AND section_id = get_advisor_section());
-- Students can see only their own record
CREATE POLICY "student_read_own" ON students FOR SELECT TO authenticated
  USING (get_user_role() = 'STUDENT' AND student_id = get_student_id());

-- ─── DAILY_ATTENDANCE: Role-based access
-- HODs: full read access
CREATE POLICY "hod_read_all_attendance" ON daily_attendance FOR SELECT TO authenticated
  USING (get_user_role() = 'HOD');
-- HODs: can mark attendance
CREATE POLICY "hod_write_attendance" ON daily_attendance FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'HOD');
CREATE POLICY "hod_update_attendance" ON daily_attendance FOR UPDATE TO authenticated
  USING (get_user_role() = 'HOD');
-- Advisors: read/write only their section's attendance
CREATE POLICY "advisor_read_section_attendance" ON daily_attendance FOR SELECT TO authenticated
  USING (get_user_role() = 'ADVISOR' AND student_id IN (
    SELECT student_id FROM students WHERE section_id = get_advisor_section()
  ));
CREATE POLICY "advisor_write_section_attendance" ON daily_attendance FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'ADVISOR' AND student_id IN (
    SELECT student_id FROM students WHERE section_id = get_advisor_section()
  ));
CREATE POLICY "advisor_update_section_attendance" ON daily_attendance FOR UPDATE TO authenticated
  USING (get_user_role() = 'ADVISOR' AND student_id IN (
    SELECT student_id FROM students WHERE section_id = get_advisor_section()
  ));
-- Students: read only own attendance
CREATE POLICY "student_read_own_attendance" ON daily_attendance FOR SELECT TO authenticated
  USING (get_user_role() = 'STUDENT' AND student_id = get_student_id());

-- ─── LEAVE_SLIPS: Role-based access
-- HODs: full read/write
CREATE POLICY "hod_read_all_slips" ON leave_slips FOR SELECT TO authenticated
  USING (get_user_role() = 'HOD');
CREATE POLICY "hod_update_slips" ON leave_slips FOR UPDATE TO authenticated
  USING (get_user_role() = 'HOD');
-- Advisors: read/write their section's slips
CREATE POLICY "advisor_read_section_slips" ON leave_slips FOR SELECT TO authenticated
  USING (get_user_role() = 'ADVISOR' AND student_id IN (
    SELECT student_id FROM students WHERE section_id = get_advisor_section()
  ));
CREATE POLICY "advisor_insert_section_slips" ON leave_slips FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'ADVISOR' AND student_id IN (
    SELECT student_id FROM students WHERE section_id = get_advisor_section()
  ));
CREATE POLICY "advisor_update_section_slips" ON leave_slips FOR UPDATE TO authenticated
  USING (get_user_role() = 'ADVISOR' AND student_id IN (
    SELECT student_id FROM students WHERE section_id = get_advisor_section()
  ));
-- Students: read own, insert own
CREATE POLICY "student_read_own_slips" ON leave_slips FOR SELECT TO authenticated
  USING (get_user_role() = 'STUDENT' AND student_id = get_student_id());
CREATE POLICY "student_insert_own_slips" ON leave_slips FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'STUDENT' AND student_id = get_student_id());

-- ─── BIOMETRIC_PUNCHES: Authenticated read only (no direct insert from app)
CREATE POLICY "auth_read_punches" ON biometric_punches FOR SELECT TO authenticated USING (true);

-- ─── AUDIT_LOGS: HOD read only, authenticated insert
CREATE POLICY "hod_read_audit" ON audit_logs FOR SELECT TO authenticated
  USING (get_user_role() = 'HOD');
CREATE POLICY "auth_insert_audit" ON audit_logs FOR INSERT TO authenticated WITH CHECK (true);

-- ──────────────────── AUTH TRIGGER ────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (auth_id, email, full_name, role)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
        COALESCE((new.raw_user_meta_data->>'role')::user_role, 'STUDENT'::user_role)
    )
    ON CONFLICT (email) DO UPDATE
    SET auth_id = EXCLUDED.auth_id,
        full_name = EXCLUDED.full_name;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ──────────────────── SEED SECTIONS ────────────────────

INSERT INTO sections (section_id, year, section_name, total_strength) VALUES
('I-AIDS-A', 1, 'A', 60), ('I-AIDS-B', 1, 'B', 59), ('I-AIDS-C', 1, 'C', 60), ('I-AIDS-D', 1, 'D', 59),
('II-AIDS-A', 2, 'A', 62), ('II-AIDS-B', 2, 'B', 63), ('II-AIDS-C', 2, 'C', 61), ('II-AIDS-D', 2, 'D', 61),
('III-AIDS-A', 3, 'A', 60), ('III-AIDS-B', 3, 'B', 58), ('III-AIDS-C', 3, 'C', 59), ('III-AIDS-D', 3, 'D', 58),
('IV-AIDS-A', 4, 'A', 56), ('IV-AIDS-B', 4, 'B', 56)
ON CONFLICT (section_id) DO UPDATE SET total_strength = EXCLUDED.total_strength;
