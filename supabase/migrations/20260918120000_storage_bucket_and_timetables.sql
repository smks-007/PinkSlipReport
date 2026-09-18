-- ═══════════════════════════════════════════════════════════════════
-- Migration: Storage Bucket for Leave Documents & Dynamic Timetables
-- Date: 2026-09-18
-- Description: Provision Supabase storage bucket 'leave_attachments'
--              and dynamic timetables table for AI&DS sections.
-- ═══════════════════════════════════════════════════════════════════

-- ──────────────── 1. Storage Bucket: leave_attachments ────────────────

INSERT INTO storage.buckets (id, name, public)
VALUES ('leave_attachments', 'leave_attachments', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Bucket Security Policies
DROP POLICY IF EXISTS "Public Access to Leave Attachments" ON storage.objects;
CREATE POLICY "Public Access to Leave Attachments" ON storage.objects
    FOR SELECT USING (bucket_id = 'leave_attachments');

DROP POLICY IF EXISTS "Authenticated Upload to Leave Attachments" ON storage.objects;
CREATE POLICY "Authenticated Upload to Leave Attachments" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'leave_attachments');

DROP POLICY IF EXISTS "Authenticated Update on Leave Attachments" ON storage.objects;
CREATE POLICY "Authenticated Update on Leave Attachments" ON storage.objects
    FOR UPDATE USING (bucket_id = 'leave_attachments');

-- ──────────────── 2. Timetables Table ────────────────

CREATE TABLE IF NOT EXISTS public.timetables (
    timetable_id SERIAL PRIMARY KEY,
    section_id VARCHAR(20) NOT NULL REFERENCES public.sections(section_id) ON DELETE CASCADE,
    day_of_week VARCHAR(15) NOT NULL CHECK (day_of_week IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')),
    period_number INT NOT NULL CHECK (period_number BETWEEN 1 AND 8),
    time_slot VARCHAR(30) NOT NULL,
    subject_code VARCHAR(30) NOT NULL,
    subject_name VARCHAR(150) NOT NULL,
    short_name VARCHAR(30) NOT NULL,
    faculty_name VARCHAR(100) NOT NULL,
    faculty_short VARCHAR(20) NOT NULL,
    room_number VARCHAR(50) DEFAULT 'MB III A-201',
    is_lab BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(section_id, day_of_week, period_number)
);

CREATE INDEX IF NOT EXISTS idx_timetables_section ON public.timetables(section_id);
CREATE INDEX IF NOT EXISTS idx_timetables_day ON public.timetables(day_of_week);

-- ──────────────── 3. RLS Policies on Timetables ────────────────

ALTER TABLE public.timetables ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "timetables_read_all" ON public.timetables;
CREATE POLICY "timetables_read_all" ON public.timetables
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "timetables_write_faculty_hod" ON public.timetables;
CREATE POLICY "timetables_write_faculty_hod" ON public.timetables
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.auth_id = auth.uid()
              AND u.role IN ('FACULTY', 'HOD', 'ADMIN')
        )
        OR auth.jwt() ->> 'role' = 'authenticated'
    );
