-- Apply this after 20261001120000 when that migration has already run.
BEGIN;

ALTER TABLE public.academic_term_settings
  DROP CONSTRAINT IF EXISTS academic_term_settings_minimum_range,
  DROP CONSTRAINT IF EXISTS academic_term_settings_maximum_range;

ALTER TABLE public.academic_term_settings
  ADD CONSTRAINT academic_term_settings_minimum_range
    CHECK (end_date >= (start_date + INTERVAL '2 months')::date),
  ADD CONSTRAINT academic_term_settings_maximum_range
    CHECK (end_date <= (start_date + INTERVAL '6 months')::date);

COMMIT;
