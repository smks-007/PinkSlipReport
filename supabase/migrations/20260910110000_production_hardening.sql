-- ============================================================================
-- PinkSlipReport: Production Database Hardening & Auth Provisioning Migration
-- Project: dpjsecqjcfgytcdxaksy
-- Generated: 2026-09-10
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ──────────────────── 1. SCHEMA ENHANCEMENTS ────────────────────

-- Ensure marked_by on daily_attendance
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_attendance' AND column_name = 'marked_by'
    ) THEN
        ALTER TABLE daily_attendance ADD COLUMN marked_by INT REFERENCES users(user_id) DEFAULT 1;
    END IF;
END $$;

-- Ensure updated_at on daily_attendance
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_attendance' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE daily_attendance ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- Ensure updated_at on leave_slips
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'leave_slips' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE leave_slips ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- Ensure updated_at trigger function
CREATE OR REPLACE FUNCTION update_timestamp_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_daily_attendance_time ON daily_attendance;
CREATE TRIGGER trg_update_daily_attendance_time
    BEFORE UPDATE ON daily_attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp_column();

DROP TRIGGER IF EXISTS trg_update_leave_slips_time ON leave_slips;
CREATE TRIGGER trg_update_leave_slips_time
    BEFORE UPDATE ON leave_slips
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp_column();

-- ──────────────────── 2. PERFORMANCE INDEXES ────────────────────

CREATE INDEX IF NOT EXISTS idx_daily_attendance_date ON daily_attendance(attendance_date);
CREATE INDEX IF NOT EXISTS idx_daily_attendance_student_date ON daily_attendance(student_id, attendance_date);
CREATE INDEX IF NOT EXISTS idx_daily_attendance_marked_by ON daily_attendance(marked_by);
CREATE INDEX IF NOT EXISTS idx_leave_slips_student ON leave_slips(student_id);
CREATE INDEX IF NOT EXISTS idx_leave_slips_status ON leave_slips(status);
CREATE INDEX IF NOT EXISTS idx_leave_slips_created ON leave_slips(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_students_section ON students(section_id);
CREATE INDEX IF NOT EXISTS idx_students_roll ON students(roll_number);
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON users(auth_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ──────────────────── 3. DROP INSECURE ANONYMOUS POLICIES ────────────────────

DROP POLICY IF EXISTS "Allow public read sections" ON sections;
DROP POLICY IF EXISTS "Allow authenticated read on sections" ON sections;
DROP POLICY IF EXISTS "Allow public read users" ON users;
DROP POLICY IF EXISTS "Allow authenticated read on users" ON users;
DROP POLICY IF EXISTS "Allow authenticated read on advisors" ON staff_advisors;
DROP POLICY IF EXISTS "Allow authenticated read on students" ON students;
DROP POLICY IF EXISTS "Allow public read attendance" ON daily_attendance;
DROP POLICY IF EXISTS "Allow authenticated full access on attendance" ON daily_attendance;
DROP POLICY IF EXISTS "Allow public insert leave_slips" ON leave_slips;
DROP POLICY IF EXISTS "Allow public read leave_slips" ON leave_slips;
DROP POLICY IF EXISTS "Allow authenticated full access on leave_slips" ON leave_slips;

-- Drop any previous custom policies to allow clean recreation
DROP POLICY IF EXISTS "auth_read_sections" ON sections;
DROP POLICY IF EXISTS "auth_read_users" ON users;
DROP POLICY IF EXISTS "auth_read_advisors" ON staff_advisors;
DROP POLICY IF EXISTS "hod_read_all_students" ON students;
DROP POLICY IF EXISTS "advisor_read_section_students" ON students;
DROP POLICY IF EXISTS "student_read_own" ON students;
DROP POLICY IF EXISTS "hod_read_all_attendance" ON daily_attendance;
DROP POLICY IF EXISTS "hod_write_attendance" ON daily_attendance;
DROP POLICY IF EXISTS "hod_update_attendance" ON daily_attendance;
DROP POLICY IF EXISTS "advisor_read_section_attendance" ON daily_attendance;
DROP POLICY IF EXISTS "advisor_write_section_attendance" ON daily_attendance;
DROP POLICY IF EXISTS "advisor_update_section_attendance" ON daily_attendance;
DROP POLICY IF EXISTS "student_read_own_attendance" ON daily_attendance;
DROP POLICY IF EXISTS "hod_all_slips" ON leave_slips;
DROP POLICY IF EXISTS "advisor_read_section_slips" ON leave_slips;
DROP POLICY IF EXISTS "advisor_update_section_slips" ON leave_slips;
DROP POLICY IF EXISTS "student_read_own_slips" ON leave_slips;
DROP POLICY IF EXISTS "student_insert_own_slips" ON leave_slips;

-- ──────────────────── 4. RLS HELPER FUNCTIONS ────────────────────

CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role AS $$
  SELECT role FROM users WHERE auth_id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_advisor_section()
RETURNS VARCHAR(15) AS $$
  SELECT sa.assigned_section
  FROM staff_advisors sa
  JOIN users u ON sa.staff_id = u.user_id
  WHERE u.auth_id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_student_id()
RETURNS INT AS $$
  SELECT s.student_id
  FROM students s
  JOIN users u ON s.student_id = u.user_id
  WHERE u.auth_id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ──────────────────── 5. PRODUCTION RLS ENFORCEMENT ────────────────────

ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_advisors ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_slips ENABLE ROW LEVEL SECURITY;

-- SECTIONS
CREATE POLICY "auth_read_sections" ON sections FOR SELECT TO authenticated USING (true);

-- USERS
CREATE POLICY "auth_read_users" ON users FOR SELECT TO authenticated USING (true);

-- STAFF ADVISORS
CREATE POLICY "auth_read_advisors" ON staff_advisors FOR SELECT TO authenticated USING (true);

-- STUDENTS
CREATE POLICY "hod_read_all_students" ON students FOR SELECT TO authenticated
  USING (get_user_role() = 'HOD');
CREATE POLICY "advisor_read_section_students" ON students FOR SELECT TO authenticated
  USING (get_user_role() = 'ADVISOR' AND section_id = get_advisor_section());
CREATE POLICY "student_read_own" ON students FOR SELECT TO authenticated
  USING (get_user_role() = 'STUDENT' AND student_id = get_student_id());

-- DAILY ATTENDANCE
CREATE POLICY "hod_read_all_attendance" ON daily_attendance FOR SELECT TO authenticated
  USING (get_user_role() = 'HOD');
CREATE POLICY "hod_write_attendance" ON daily_attendance FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'HOD');
CREATE POLICY "hod_update_attendance" ON daily_attendance FOR UPDATE TO authenticated
  USING (get_user_role() = 'HOD');

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

CREATE POLICY "student_read_own_attendance" ON daily_attendance FOR SELECT TO authenticated
  USING (get_user_role() = 'STUDENT' AND student_id = get_student_id());

-- LEAVE SLIPS
CREATE POLICY "hod_all_slips" ON leave_slips FOR ALL TO authenticated
  USING (get_user_role() = 'HOD') WITH CHECK (get_user_role() = 'HOD');

CREATE POLICY "advisor_read_section_slips" ON leave_slips FOR SELECT TO authenticated
  USING (get_user_role() = 'ADVISOR' AND student_id IN (
    SELECT student_id FROM students WHERE section_id = get_advisor_section()
  ));
CREATE POLICY "advisor_update_section_slips" ON leave_slips FOR UPDATE TO authenticated
  USING (get_user_role() = 'ADVISOR' AND student_id IN (
    SELECT student_id FROM students WHERE section_id = get_advisor_section()
  ));

CREATE POLICY "student_read_own_slips" ON leave_slips FOR SELECT TO authenticated
  USING (get_user_role() = 'STUDENT' AND student_id = get_student_id());
CREATE POLICY "student_insert_own_slips" ON leave_slips FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'STUDENT' AND student_id = get_student_id());

-- ──────────────────── 6. AUTH ACCOUNT PROVISIONING ────────────────────

CREATE OR REPLACE FUNCTION provision_auth_user(
    p_email TEXT,
    p_password TEXT,
    p_name TEXT,
    p_role TEXT,
    p_section TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    SELECT id INTO v_user_id FROM auth.users WHERE email = p_email;
    
    IF v_user_id IS NULL THEN
        v_user_id := gen_random_uuid();
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            confirmation_token,
            recovery_token,
            email_change_token_new,
            email_change_token_current,
            email_change,
            phone_change,
            phone_change_token,
            reauthentication_token
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            v_user_id,
            'authenticated',
            'authenticated',
            p_email,
            crypt(p_password, gen_salt('bf')),
            NOW(),
            '{"provider": "email", "providers": ["email"]}'::jsonb,
            jsonb_build_object(
                'full_name', p_name,
                'role', p_role,
                'class_section', p_section,
                'department', 'AI&DS',
                'college', 'V.S.B. Engineering College'
            ),
            NOW(),
            NOW(),
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            ''
        );

        INSERT INTO auth.identities (
            id,
            user_id,
            identity_data,
            provider,
            provider_id,
            last_sign_in_at,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            v_user_id,
            jsonb_build_object('sub', v_user_id::text, 'email', p_email),
            'email',
            v_user_id::text,
            NOW(),
            NOW(),
            NOW()
        );
    ELSE
        UPDATE auth.users
        SET encrypted_password = crypt(p_password, gen_salt('bf')),
            email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
            confirmation_token = COALESCE(confirmation_token, ''),
            recovery_token = COALESCE(recovery_token, ''),
            email_change_token_new = COALESCE(email_change_token_new, ''),
            email_change_token_current = COALESCE(email_change_token_current, ''),
            email_change = COALESCE(email_change, ''),
            phone_change = COALESCE(phone_change, ''),
            phone_change_token = COALESCE(phone_change_token, ''),
            reauthentication_token = COALESCE(reauthentication_token, ''),
            raw_user_meta_data = jsonb_build_object(
                'full_name', p_name,
                'role', p_role,
                'class_section', p_section,
                'department', 'AI&DS',
                'college', 'V.S.B. Engineering College'
            ),
            updated_at = NOW()
        WHERE id = v_user_id;
    END IF;

    -- Link back to public.users table
    UPDATE public.users
    SET auth_id = v_user_id
    WHERE email = p_email;

    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Provision HODs
SELECT provision_auth_user('manivannan.hod@vsb.ac.in', 'Hod@Mani2026', 'Dr. Manivannan (Ph.D.)', 'HOD');
SELECT provision_auth_user('hod.kavitha@vsb.ac.in', 'Hod@Kavi2026', 'Dr. Kavitha', 'HOD');

-- Provision IV Year Section Advisors
SELECT provision_auth_user('advisor.4a@vsb.ac.in', 'Adv@Muthu4A', 'Mr. Muthuselvan', 'ADVISOR', 'IV AI&DS - Section A');
SELECT provision_auth_user('advisor.4b@vsb.ac.in', 'Adv@Nandhini4B', 'Mrs. Nandhinidevi', 'ADVISOR', 'IV AI&DS - Section B');

-- Provision III Year Section Advisors
SELECT provision_auth_user('advisor.3a@vsb.ac.in', 'Adv@Vishnu3A', 'Ms. C. Vishnupriya', 'ADVISOR', 'III AI&DS - Section A');
SELECT provision_auth_user('advisor.3b@vsb.ac.in', 'Adv@Murugesan3B', 'Dr. R. Murugesan', 'ADVISOR', 'III AI&DS - Section B');
SELECT provision_auth_user('advisor.3c@vsb.ac.in', 'Adv@Bharathi3C', 'Mrs. B. Bharathi', 'ADVISOR', 'III AI&DS - Section C');
SELECT provision_auth_user('advisor.3d@vsb.ac.in', 'Adv@Velu3D', 'Mr. Velusamy', 'ADVISOR', 'III AI&DS - Section D');

-- Provision II Year Section Advisors
SELECT provision_auth_user('advisor.2a@vsb.ac.in', 'Adv@Anandh2A', 'Dr. D. Anandhan', 'ADVISOR', 'II AI&DS - Section A');
SELECT provision_auth_user('advisor.2b@vsb.ac.in', 'Adv@Rajen2B', 'Dr. M. Rajendiran', 'ADVISOR', 'II AI&DS - Section B');
SELECT provision_auth_user('advisor.2c@vsb.ac.in', 'Adv@Bharathi2C', 'Mr. A. Bharathidasan', 'ADVISOR', 'II AI&DS - Section C');
SELECT provision_auth_user('advisor.2d@vsb.ac.in', 'Adv@Palraj2D', 'Mr. R. Palraj', 'ADVISOR', 'II AI&DS - Section D');
