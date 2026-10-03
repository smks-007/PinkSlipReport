-- Step 1: Stable cohort-based section identity foundation.
-- Existing IDs remain live during this non-breaking rollout. The next
-- migration will replace IDs only after every foreign-key consumer is ready.
BEGIN;

ALTER TABLE public.sections
  ADD COLUMN IF NOT EXISTS cohort_year integer;

-- Academic year 2026-2027: Year 1 = 2026 intake, Year 2 = 2025 intake,
-- Year 3 = 2024 intake, Year 4 = 2023 intake.
UPDATE public.sections
SET cohort_year = 2027 - year
WHERE cohort_year IS NULL;

ALTER TABLE public.sections
  ALTER COLUMN cohort_year SET NOT NULL;

ALTER TABLE public.sections
  DROP CONSTRAINT IF EXISTS sections_cohort_year_range;
ALTER TABLE public.sections
  ADD CONSTRAINT sections_cohort_year_range
  CHECK (cohort_year BETWEEN 2000 AND 2100);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'sections_cohort_department_section_key'
      AND conrelid = 'public.sections'::regclass
  ) THEN
    ALTER TABLE public.sections
      ADD CONSTRAINT sections_cohort_department_section_key
      UNIQUE (cohort_year, department, section_name);
  END IF;
END $$;

-- HOD, advisor, and student interfaces must display the academic year label,
-- not the internal cohort key (for example: III-AIDS-B).
CREATE OR REPLACE FUNCTION public.section_display_label(p_section_id text)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT CASE s.year
    WHEN 1 THEN 'I'
    WHEN 2 THEN 'II'
    WHEN 3 THEN 'III'
    WHEN 4 THEN 'IV'
  END || '-AIDS-' || upper(s.section_name)
  FROM public.sections s
  WHERE s.section_id = p_section_id
  LIMIT 1
$$;

REVOKE ALL ON FUNCTION public.section_display_label(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.section_display_label(text) TO authenticated;

NOTIFY pgrst, 'reload schema';
COMMIT;
