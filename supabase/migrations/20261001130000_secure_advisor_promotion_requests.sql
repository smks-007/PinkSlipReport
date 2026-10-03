-- Step 1: Advisors submit only their own section's promotion request.
-- HOD approval and alumni archival are implemented in the next transaction step.
BEGIN;

CREATE TABLE IF NOT EXISTS public.promotion_audit_log (
  audit_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  promotion_id integer NOT NULL REFERENCES public.promotions(promotion_id) ON DELETE RESTRICT,
  action text NOT NULL CHECK (action IN ('REQUESTED', 'FORWARDED', 'APPROVED', 'REJECTED', 'ARCHIVED', 'PURGE_PENDING', 'PURGED')),
  actor_user_id integer REFERENCES public.users(user_id) ON DELETE SET NULL,
  remarks text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS promotion_audit_log_promotion_created_idx
  ON public.promotion_audit_log(promotion_id, created_at DESC);

-- Only one active request may exist for a cohort/semester at a time.
CREATE UNIQUE INDEX IF NOT EXISTS promotions_one_active_request_per_cohort_idx
  ON public.promotions(from_year, section, batch_year, semester_completed)
  WHERE status IN ('PENDING_ADVISOR', 'FORWARDED_TO_HOD');

ALTER TABLE public.promotion_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "hod_read_promotion_audit_log" ON public.promotion_audit_log;
CREATE POLICY "hod_read_promotion_audit_log"
ON public.promotion_audit_log FOR SELECT TO authenticated
USING (public.get_user_role() = 'HOD');

REVOKE ALL ON TABLE public.promotion_audit_log FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.promotion_audit_log TO authenticated;

-- Promotion writes occur only through security-definer workflow functions.
REVOKE INSERT, UPDATE, DELETE ON TABLE public.promotions FROM authenticated;

CREATE OR REPLACE FUNCTION public.submit_my_promotion_request(
  p_from_year integer,
  p_batch_year text,
  p_semester_completed integer,
  p_semester_end_date date,
  p_grace_transition_days integer,
  p_advisor_remarks text
)
RETURNS public.promotions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_advisor_section text;
  v_expected_section text;
  v_actor_user_id integer;
  v_total_students integer;
  v_promotion public.promotions;
BEGIN
  IF auth.uid() IS NULL OR public.get_user_role() <> 'ADVISOR' THEN
    RAISE EXCEPTION 'Only an authenticated advisor can submit a promotion request' USING ERRCODE = '42501';
  END IF;
  IF p_from_year NOT BETWEEN 1 AND 4 OR p_semester_completed NOT BETWEEN 1 AND 8 THEN
    RAISE EXCEPTION 'Invalid academic year or semester' USING ERRCODE = '22023';
  END IF;
  IF p_grace_transition_days NOT BETWEEN 7 AND 10 THEN
    RAISE EXCEPTION 'Grace period must be between 7 and 10 days' USING ERRCODE = '22023';
  END IF;
  IF p_semester_end_date IS NULL OR p_semester_end_date > (current_timestamp AT TIME ZONE 'Asia/Kolkata')::date THEN
    RAISE EXCEPTION 'Semester end date must not be in the future' USING ERRCODE = '22007';
  END IF;
  IF (current_timestamp AT TIME ZONE 'Asia/Kolkata')::date < p_semester_end_date + p_grace_transition_days THEN
    RAISE EXCEPTION 'The configured grace period has not ended' USING ERRCODE = '22023';
  END IF;

  SELECT public.get_advisor_section(), u.user_id
  INTO v_advisor_section, v_actor_user_id
  FROM public.users u
  WHERE u.auth_id = auth.uid() AND u.is_active IS TRUE;

  IF v_advisor_section IS NULL THEN
    RAISE EXCEPTION 'No advisor section assignment exists' USING ERRCODE = '42501';
  END IF;
  v_expected_section := CASE p_from_year
    WHEN 1 THEN 'I'
    WHEN 2 THEN 'II'
    WHEN 3 THEN 'III'
    ELSE 'IV'
  END || '-AIDS-' || split_part(v_advisor_section, '-', 3);

  IF v_advisor_section <> v_expected_section THEN
    RAISE EXCEPTION 'Advisor can request promotion only for the assigned academic year and section' USING ERRCODE = '42501';
  END IF;

  SELECT count(*) INTO v_total_students
  FROM public.students s
  WHERE s.section_id = v_advisor_section;
  IF v_total_students = 0 THEN
    RAISE EXCEPTION 'The assigned section has no active students' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.promotions (
    from_year, to_year, section, batch_year, semester_completed,
    semester_end_date, grace_transition_days, eligible_promotion_date,
    total_students, status, advisor_name, advisor_remarks,
    date_forwarded_by_advisor
  )
  SELECT
    p_from_year, CASE WHEN p_from_year = 4 THEN 5 ELSE p_from_year + 1 END,
    split_part(v_advisor_section, '-', 3), btrim(p_batch_year),
    p_semester_completed, p_semester_end_date, p_grace_transition_days,
    p_semester_end_date + p_grace_transition_days, v_total_students,
    'FORWARDED_TO_HOD', u.full_name, nullif(btrim(p_advisor_remarks), ''), now()
  FROM public.users u
  WHERE u.user_id = v_actor_user_id
  RETURNING * INTO v_promotion;

  INSERT INTO public.promotion_audit_log (promotion_id, action, actor_user_id, remarks)
  VALUES (v_promotion.promotion_id, 'REQUESTED', v_actor_user_id, nullif(btrim(p_advisor_remarks), ''));

  RETURN v_promotion;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'An active promotion request already exists for this cohort and semester' USING ERRCODE = '23505';
END;
$$;

REVOKE ALL ON FUNCTION public.submit_my_promotion_request(integer, text, integer, date, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_my_promotion_request(integer, text, integer, date, integer, text) TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
