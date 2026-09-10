-- Migration: 20260910140000_student_name_remove_guardian.sql
-- Goal: In public.students table, rename guardian_name to student_name, backfill with genuine student names from public.users, and drop guardian_contact.

-- 1. Rename column guardian_name to student_name if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'students' AND column_name = 'guardian_name'
    ) THEN
        ALTER TABLE public.students RENAME COLUMN guardian_name TO student_name;
    END IF;
END $$;

-- 2. Backfill student_name with the real student full_name from users table
UPDATE public.students s
SET student_name = u.full_name
FROM public.users u
WHERE s.student_id = u.user_id AND u.full_name IS NOT NULL;

-- 3. Ensure student_name is NOT NULL
ALTER TABLE public.students ALTER COLUMN student_name SET NOT NULL;

-- 4. Remove guardian_contact column from students table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'students' AND column_name = 'guardian_contact'
    ) THEN
        ALTER TABLE public.students DROP COLUMN guardian_contact;
    END IF;
END $$;
