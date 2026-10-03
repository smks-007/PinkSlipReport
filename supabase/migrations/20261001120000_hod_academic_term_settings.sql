-- HOD-managed academic term range used by the HOD monthly attendance view.
BEGIN;

CREATE TABLE IF NOT EXISTS public.academic_term_settings (
  study_year smallint PRIMARY KEY CHECK (study_year BETWEEN 1 AND 4),
  term_name text NOT NULL DEFAULT 'Academic Term',
  start_date date NOT NULL,
  end_date date NOT NULL,
  updated_by integer REFERENCES public.users(user_id),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT academic_term_settings_valid_range CHECK (end_date >= start_date),
  CONSTRAINT academic_term_settings_minimum_range CHECK (end_date >= (start_date + INTERVAL '2 months')::date),
  CONSTRAINT academic_term_settings_maximum_range CHECK (end_date <= (start_date + INTERVAL '6 months')::date)
);

ALTER TABLE public.academic_term_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "hod_manage_academic_term_settings" ON public.academic_term_settings;
CREATE POLICY "hod_manage_academic_term_settings"
ON public.academic_term_settings
FOR ALL TO authenticated
USING (public.get_user_role() = 'HOD')
WITH CHECK (public.get_user_role() = 'HOD');

REVOKE ALL ON TABLE public.academic_term_settings FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE ON TABLE public.academic_term_settings TO authenticated;

INSERT INTO public.academic_term_settings (
  study_year,
  term_name,
  start_date,
  end_date
)
SELECT
  study_year,
  'Academic Term Sep-Dec 2026',
  DATE '2026-09-01',
  DATE '2026-12-31'
FROM generate_series(1, 4) AS study_year
ON CONFLICT (study_year) DO NOTHING;

NOTIFY pgrst, 'reload schema';
COMMIT;
