-- Step 4: Convert legacy IDs (III-AIDS-B) to stable cohort IDs (24-AIDS-B).
-- Prerequisites: 20261001140000 and 20261001141500.
BEGIN;

DO $$
DECLARE
  unexpected_table text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'sections' AND column_name = 'cohort_year')
    OR to_regclass('public.student_section_history') IS NULL THEN
    RAISE EXCEPTION 'Run the cohort foundation and attendance-history migrations first';
  END IF;

  SELECT rel.relname INTO unexpected_table
  FROM pg_constraint fk
  JOIN pg_class rel ON rel.oid = fk.conrelid
  WHERE fk.contype = 'f'
    AND fk.confrelid = 'public.sections'::regclass
    AND rel.relname NOT IN ('students', 'staff_advisors', 'daily_attendance',
                            'student_section_history', 'timetables')
  LIMIT 1;
  IF unexpected_table IS NOT NULL THEN
    RAISE EXCEPTION 'Unreviewed section dependency found: %. Add it to this migration before conversion.', unexpected_table;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.sections WHERE cohort_year IS NULL) THEN
    RAISE EXCEPTION 'Every section must have a cohort_year before conversion';
  END IF;
END $$;

ALTER TABLE public.sections
  DROP CONSTRAINT IF EXISTS sections_cohort_department_section_key;

CREATE TEMP TABLE section_id_map (
  old_id varchar(15) PRIMARY KEY,
  new_id varchar(15) NOT NULL UNIQUE
) ON COMMIT DROP;

INSERT INTO section_id_map(old_id, new_id)
SELECT s.section_id,
       right(s.cohort_year::text, 2) || '-AIDS-' || upper(s.section_name)
FROM public.sections s
WHERE s.section_id ~ '^(I|II|III|IV)-AIDS-[A-D]$';

-- Duplicate section metadata under the new stable key before moving any FK.
INSERT INTO public.sections (
  section_id, year, section_name, department, total_strength, academic_year, cohort_year
)
SELECT m.new_id, s.year, s.section_name, s.department, s.total_strength,
       s.academic_year, s.cohort_year
FROM public.sections s
JOIN section_id_map m ON m.old_id = s.section_id;

UPDATE public.students t SET section_id = m.new_id
FROM section_id_map m WHERE t.section_id = m.old_id;
UPDATE public.staff_advisors t SET assigned_section = m.new_id
FROM section_id_map m WHERE t.assigned_section = m.old_id;
UPDATE public.daily_attendance t SET section_id_at_marking = m.new_id
FROM section_id_map m WHERE t.section_id_at_marking = m.old_id;
UPDATE public.student_section_history t SET section_id = m.new_id
FROM section_id_map m WHERE t.section_id = m.old_id;
DO $$
BEGIN
  -- Timetables are optional in older project databases.
  IF to_regclass('public.timetables') IS NOT NULL THEN
    EXECUTE 'UPDATE public.timetables t SET section_id = m.new_id
             FROM pg_temp.section_id_map m WHERE t.section_id = m.old_id';
  END IF;
END $$;

DELETE FROM public.sections s
USING section_id_map m
WHERE s.section_id = m.old_id;

ALTER TABLE public.sections
  ADD CONSTRAINT sections_cohort_department_section_key
  UNIQUE (cohort_year, department, section_name);

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.sections WHERE section_id ~ '^(I|II|III|IV)-AIDS-[A-D]$') THEN
    RAISE EXCEPTION 'Legacy section IDs remain after conversion';
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
COMMIT;
