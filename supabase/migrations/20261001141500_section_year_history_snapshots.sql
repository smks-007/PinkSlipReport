-- Step 3: Preserve the academic year that applied when attendance was marked.
-- Prerequisite: 20261001133000_hod_atomic_promotion_decision.sql.
BEGIN;

DO $$
BEGIN
  IF to_regclass('public.student_section_history') IS NULL OR NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'daily_attendance'
      AND column_name = 'section_id_at_marking'
  ) THEN
    RAISE EXCEPTION
      'Run 20261001133000_hod_atomic_promotion_decision.sql before this migration';
  END IF;
END $$;

ALTER TABLE public.daily_attendance
  ADD COLUMN IF NOT EXISTS study_year_at_marking integer;
ALTER TABLE public.daily_attendance
  DROP CONSTRAINT IF EXISTS daily_attendance_study_year_at_marking_range;
ALTER TABLE public.daily_attendance
  ADD CONSTRAINT daily_attendance_study_year_at_marking_range
  CHECK (study_year_at_marking BETWEEN 1 AND 4);

UPDATE public.daily_attendance a
SET study_year_at_marking = s.year
FROM public.sections s
WHERE s.section_id = a.section_id_at_marking
  AND a.study_year_at_marking IS NULL;

ALTER TABLE public.student_section_history
  ADD COLUMN IF NOT EXISTS study_year integer;
UPDATE public.student_section_history h
SET study_year = s.year
FROM public.sections s
WHERE s.section_id = h.section_id
  AND h.study_year IS NULL;
ALTER TABLE public.student_section_history
  ALTER COLUMN study_year SET NOT NULL;
ALTER TABLE public.student_section_history
  DROP CONSTRAINT IF EXISTS student_section_history_study_year_range;
ALTER TABLE public.student_section_history
  ADD CONSTRAINT student_section_history_study_year_range
  CHECK (study_year BETWEEN 1 AND 4);

CREATE OR REPLACE FUNCTION public.capture_attendance_section_snapshot()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_section_id varchar(15);
  v_study_year integer;
BEGIN
  IF NEW.section_id_at_marking IS NULL THEN
    SELECT s.section_id INTO v_section_id
    FROM public.students s
    WHERE s.student_id = NEW.student_id;
    NEW.section_id_at_marking := v_section_id;
  END IF;

  SELECT s.year INTO v_study_year
  FROM public.sections s
  WHERE s.section_id = NEW.section_id_at_marking;
  IF NEW.section_id_at_marking IS NULL OR v_study_year IS NULL THEN
    RAISE EXCEPTION 'Attendance student % does not have an assigned section', NEW.student_id;
  END IF;

  IF NEW.study_year_at_marking IS NULL THEN
    NEW.study_year_at_marking := v_study_year;
  END IF;
  RETURN NEW;
END;
$$;

NOTIFY pgrst, 'reload schema';
COMMIT;
