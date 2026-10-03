-- Converts the original shared HOD term setting into independently managed
-- settings for Years 1, 2, 3, and 4.
BEGIN;

ALTER TABLE public.academic_term_settings
  DROP CONSTRAINT IF EXISTS academic_term_settings_pkey;

ALTER TABLE public.academic_term_settings
  ADD COLUMN IF NOT EXISTS study_year smallint;

UPDATE public.academic_term_settings
SET study_year = 1
WHERE study_year IS NULL;

INSERT INTO public.academic_term_settings (
  study_year, term_name, start_date, end_date, updated_by, updated_at
)
SELECT year_value, term_name, start_date, end_date, updated_by, updated_at
FROM public.academic_term_settings
CROSS JOIN generate_series(2, 4) AS year_value
WHERE study_year = 1
  AND NOT EXISTS (
    SELECT 1
    FROM public.academic_term_settings existing
    WHERE existing.study_year = year_value
  );

ALTER TABLE public.academic_term_settings
  ALTER COLUMN study_year SET NOT NULL,
  ADD CONSTRAINT academic_term_settings_study_year_check CHECK (study_year BETWEEN 1 AND 4),
  ADD PRIMARY KEY (study_year),
  DROP COLUMN IF EXISTS settings_id;

NOTIFY pgrst, 'reload schema';
COMMIT;
