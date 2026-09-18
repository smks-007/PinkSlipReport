-- ============================================================================
-- Migration: 20260916143000_sync_schema_from_excel.sql
-- Goal: Synchronize database schema and rosters with official 'AIDS student count.xlsx'
-- ============================================================================

-- 1. Correct Section Capacities & Strengths
UPDATE public.sections
SET total_strength = CASE section_id
    WHEN 'II-AIDS-A' THEN 63
    WHEN 'II-AIDS-B' THEN 62
    WHEN 'II-AIDS-C' THEN 61
    WHEN 'II-AIDS-D' THEN 63
    WHEN 'III-AIDS-A' THEN 65
    WHEN 'III-AIDS-B' THEN 61
    WHEN 'III-AIDS-C' THEN 60
    WHEN 'III-AIDS-D' THEN 63
    WHEN 'IV-AIDS-A' THEN 59
    WHEN 'IV-AIDS-B' THEN 65
    ELSE total_strength
END
WHERE section_id IN (
    'II-AIDS-A', 'II-AIDS-B', 'II-AIDS-C', 'II-AIDS-D',
    'III-AIDS-A', 'III-AIDS-B', 'III-AIDS-C', 'III-AIDS-D',
    'IV-AIDS-A', 'IV-AIDS-B'
);

-- 2. Correct Section for Student MUGESHDHARAN M (Roll: 25243128) -> II-AIDS-C
UPDATE public.students
SET section_id = 'II-AIDS-C'
WHERE roll_number = '25243128';

-- 3. Ensure Staff Advisor Assignments Match Official Roster
INSERT INTO public.staff_advisors (staff_id, staff_code, assigned_section, designation, cabin_location)
VALUES
(201, 'STF-AIDS-2A', 'II-AIDS-A', 'Associate Professor', 'Cabin A-101'),
(202, 'STF-AIDS-2B', 'II-AIDS-B', 'Associate Professor', 'Cabin A-102'),
(203, 'STF-AIDS-2C', 'II-AIDS-C', 'Assistant Professor', 'Cabin A-103'),
(204, 'STF-AIDS-2D', 'II-AIDS-D', 'Assistant Professor', 'Cabin A-104'),
(301, 'STF-AIDS-3A', 'III-AIDS-A', 'Assistant Professor', 'Cabin B-201'),
(302, 'STF-AIDS-3B', 'III-AIDS-B', 'Associate Professor', 'Cabin B-202'),
(303, 'STF-AIDS-3C', 'III-AIDS-C', 'Assistant Professor', 'Cabin B-203'),
(304, 'STF-AIDS-3D', 'III-AIDS-D', 'Assistant Professor', 'Cabin B-204'),
(401, 'STF-AIDS-4A', 'IV-AIDS-A', 'Assistant Professor', 'Cabin C-301'),
(402, 'STF-AIDS-4B', 'IV-AIDS-B', 'Assistant Professor', 'Cabin C-302')
ON CONFLICT (staff_code) DO UPDATE
SET assigned_section = EXCLUDED.assigned_section;

-- 4. Update Staff Names if needed
UPDATE public.users SET full_name = 'Dr. M. Rajediren' WHERE email = 'advisor.2b@vsb.ac.in';
UPDATE public.users SET full_name = 'Mr. Muthuchelvan' WHERE email = 'advisor.4a@vsb.ac.in';

-- 5. Helper Function: Get Section Student Count
CREATE OR REPLACE FUNCTION get_section_student_count(p_section_id VARCHAR)
RETURNS INT AS $$
    SELECT COUNT(*)::INT FROM public.students WHERE section_id = p_section_id;
$$ LANGUAGE sql STABLE;
