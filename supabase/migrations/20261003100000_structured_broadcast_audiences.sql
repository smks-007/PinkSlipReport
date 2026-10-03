-- Step 1: Structured, server-calculated notice audiences.
BEGIN;

ALTER TABLE public.broadcast_notices
  ADD COLUMN IF NOT EXISTS audience_type text NOT NULL DEFAULT 'DEPARTMENT',
  ADD COLUMN IF NOT EXISTS target_year integer,
  ADD COLUMN IF NOT EXISTS target_section text,
  ADD COLUMN IF NOT EXISTS recipient_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'SENT';

ALTER TABLE public.broadcast_notices
  DROP CONSTRAINT IF EXISTS broadcast_notices_audience_type_check,
  DROP CONSTRAINT IF EXISTS broadcast_notices_target_year_check,
  DROP CONSTRAINT IF EXISTS broadcast_notices_target_section_check,
  DROP CONSTRAINT IF EXISTS broadcast_notices_recipient_count_check,
  DROP CONSTRAINT IF EXISTS broadcast_notices_status_check;
ALTER TABLE public.broadcast_notices
  ADD CONSTRAINT broadcast_notices_audience_type_check
    CHECK (audience_type IN ('DEPARTMENT', 'YEAR', 'SECTION', 'ADVISORS')),
  ADD CONSTRAINT broadcast_notices_target_year_check
    CHECK (target_year IS NULL OR target_year BETWEEN 1 AND 4),
  ADD CONSTRAINT broadcast_notices_target_section_check
    CHECK (target_section IS NULL OR target_section ~ '^[A-D]$'),
  ADD CONSTRAINT broadcast_notices_recipient_count_check
    CHECK (recipient_count >= 0),
  ADD CONSTRAINT broadcast_notices_status_check
    CHECK (status IN ('DRAFT', 'SENT', 'EXPIRED'));

CREATE INDEX IF NOT EXISTS broadcast_notices_active_idx
  ON public.broadcast_notices(status, expires_at, created_at DESC);

CREATE OR REPLACE FUNCTION public.get_broadcast_audience_summary(
  p_audience_type text,
  p_target_year integer DEFAULT NULL,
  p_target_section text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_students integer := 0;
  v_advisors integer := 0;
  v_label text;
BEGIN
  IF auth.uid() IS NULL OR public.get_user_role() <> 'HOD' THEN
    RAISE EXCEPTION 'Only an authenticated HOD can inspect a broadcast audience' USING ERRCODE = '42501';
  END IF;
  IF p_audience_type NOT IN ('DEPARTMENT', 'YEAR', 'SECTION', 'ADVISORS') THEN
    RAISE EXCEPTION 'Invalid audience type' USING ERRCODE = '22023';
  END IF;
  IF p_audience_type IN ('YEAR', 'SECTION')
     AND (p_target_year IS NULL OR p_target_year NOT BETWEEN 1 AND 4) THEN
    RAISE EXCEPTION 'Choose an academic year' USING ERRCODE = '22023';
  END IF;
  IF p_audience_type = 'SECTION' AND coalesce(upper(p_target_section), '') !~ '^[A-D]$' THEN
    RAISE EXCEPTION 'Choose a valid section' USING ERRCODE = '22023';
  END IF;

  SELECT count(*) INTO v_students
  FROM public.students st
  JOIN public.sections sec ON sec.section_id = st.section_id
  WHERE p_audience_type <> 'ADVISORS'
    AND (p_audience_type = 'DEPARTMENT'
      OR (p_audience_type = 'YEAR' AND sec.year = p_target_year)
      OR (p_audience_type = 'SECTION' AND sec.year = p_target_year AND sec.section_name = upper(p_target_section)));

  SELECT count(*) INTO v_advisors
  FROM public.staff_advisors sa
  JOIN public.sections sec ON sec.section_id = sa.assigned_section
  WHERE p_audience_type IN ('DEPARTMENT', 'YEAR', 'SECTION', 'ADVISORS')
    AND (p_audience_type IN ('DEPARTMENT', 'ADVISORS')
      OR (p_audience_type = 'YEAR' AND sec.year = p_target_year)
      OR (p_audience_type = 'SECTION' AND sec.year = p_target_year AND sec.section_name = upper(p_target_section)));

  v_label := CASE p_audience_type
    WHEN 'DEPARTMENT' THEN 'Department'
    WHEN 'ADVISORS' THEN 'All Advisors'
    WHEN 'YEAR' THEN 'Year ' || p_target_year
    ELSE 'Year ' || p_target_year || ' · Section ' || upper(p_target_section)
  END;
  RETURN jsonb_build_object('label', v_label, 'students', v_students,
    'advisors', v_advisors, 'total', v_students + v_advisors);
END;
$$;

REVOKE ALL ON FUNCTION public.get_broadcast_audience_summary(text, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_broadcast_audience_summary(text, integer, text) TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
