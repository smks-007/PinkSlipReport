-- PinkSlipReport: PostgreSQL Database DDL & Seed Script
CREATE TYPE user_role AS ENUM ('HOD', 'ADVISOR', 'STUDENT');
CREATE TYPE leave_type AS ENUM ('INFORMED', 'UNINFORMED', 'OD', 'MEDICAL');
CREATE TYPE slip_status AS ENUM ('SUBMITTED', 'PENDING_HOD', 'APPROVED', 'REJECTED');
CREATE TYPE punch_source AS ENUM ('BIOMETRIC_FINGERPRINT', 'FACE_DETECTION', 'MANUAL_OVERRIDE');

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
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
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
    marked_by INT REFERENCES users(user_id),
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
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

-- Seed Sections
INSERT INTO sections (section_id, year, section_name, total_strength) VALUES
('I-AIDS-A', 1, 'A', 60), ('I-AIDS-B', 1, 'B', 59), ('I-AIDS-C', 1, 'C', 60), ('I-AIDS-D', 1, 'D', 59),
('II-AIDS-A', 2, 'A', 62), ('II-AIDS-B', 2, 'B', 63), ('II-AIDS-C', 2, 'C', 61), ('II-AIDS-D', 2, 'D', 61),
('III-AIDS-A', 3, 'A', 60), ('III-AIDS-B', 3, 'B', 58), ('III-AIDS-C', 3, 'C', 59), ('III-AIDS-D', 3, 'D', 58),
('IV-AIDS-A', 4, 'A', 56), ('IV-AIDS-B', 4, 'B', 56)
ON CONFLICT (section_id) DO NOTHING;
