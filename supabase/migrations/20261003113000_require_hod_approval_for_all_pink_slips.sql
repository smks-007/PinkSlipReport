-- Every advisor-issued Pink Slip, including OD, must be approved by the HOD
-- before it can change daily attendance.

BEGIN;

ALTER TABLE public.leave_slips
  ADD COLUMN IF NOT EXISTS is_on_duty boolean NOT NULL DEFAULT false;

-- Replace the legacy submit-and-mark function.  The name is retained so old
-- mobile clients fail safely into the new pending-approval behavior.
DROP FUNCTION IF EXISTS public.submit_pink_slip_and_mark_attendance(
  integer, text, date, boolean, text, text, text
);

CREATE FUNCTION public.submit_pink_slip_and_mark_attendance(
  p_student_id integer,
  p_reason text,
  p_date date,
  p_is_on_duty boolean,
  p_letter_url text DEFAULT NULL,
  p_status text DEFAULT 'PENDING_HOD',
  p_advisor_remarks text DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  v_role text;
  v_section varchar(15);
  v_slip_id integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required';
  END IF;

  v_role := get_user_role()::text;
  IF v_role = 'ADVISOR' THEN
    v_section := get_advisor_section();
    IF NOT EXISTS (
      SELECT 1 FROM public.students
      WHERE student_id = p_student_id AND section_id = v_section
    ) THEN
      RAISE EXCEPTION 'Advisor cannot issue a pink slip for this student';
    END IF;
  ELSIF v_role <> 'HOD' THEN
    RAISE EXCEPTION 'Only an advisor or HOD can issue a pink slip';
  END IF;

  INSERT INTO public.leave_slips (
    student_id, reason, from_date, to_date, is_informed,
    letter_document_url, status, advisor_remarks, is_on_duty, created_at
  ) VALUES (
    p_student_id, btrim(p_reason), p_date, p_date, true,
    p_letter_url, 'PENDING_HOD'::public.slip_status, p_advisor_remarks,
    coalesce(p_is_on_duty, false), now()
  )
  RETURNING slip_id INTO v_slip_id;

  RETURN v_slip_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.decide_pink_slip_and_apply_attendance(
  p_slip_id integer,
  p_approved boolean,
  p_hod_remarks text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  v_slip public.leave_slips%ROWTYPE;
  v_hod_user_id integer;
BEGIN
  IF auth.uid() IS NULL OR get_user_role()::text <> 'HOD' THEN
    RAISE EXCEPTION 'Only the HOD can decide a Pink Slip';
  END IF;

  SELECT * INTO v_slip FROM public.leave_slips
  WHERE slip_id = p_slip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pink Slip % was not found', p_slip_id;
  END IF;
  IF v_slip.status NOT IN ('SUBMITTED', 'PENDING_HOD') THEN
    RAISE EXCEPTION 'This Pink Slip has already been decided';
  END IF;

  SELECT user_id INTO v_hod_user_id FROM public.users WHERE auth_id = auth.uid();

  UPDATE public.leave_slips
  SET status = CASE WHEN p_approved THEN 'APPROVED'::public.slip_status ELSE 'REJECTED'::public.slip_status END,
      hod_remarks = nullif(btrim(p_hod_remarks), ''),
      updated_at = now()
  WHERE slip_id = p_slip_id;

  -- A rejection leaves attendance unchanged. An approval writes precisely one
  -- final attendance result: OD is present; leave is absent.
  IF p_approved THEN
    INSERT INTO public.daily_attendance (
      student_id, attendance_date, is_present, leave_type,
      punch_method, marked_by, updated_at
    ) VALUES (
      v_slip.student_id, v_slip.from_date, v_slip.is_on_duty,
      CASE WHEN v_slip.is_on_duty THEN 'OD' ELSE 'INFORMED' END,
      'HOD_PINK_SLIP_APPROVAL', v_hod_user_id, now()
    )
    ON CONFLICT (student_id, attendance_date)
    DO UPDATE SET
      is_present = excluded.is_present,
      leave_type = excluded.leave_type,
      punch_method = excluded.punch_method,
      marked_by = excluded.marked_by,
      updated_at = now();
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_pink_slip_and_mark_attendance(integer, text, date, boolean, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_pink_slip_and_mark_attendance(integer, text, date, boolean, text, text, text) TO authenticated;
REVOKE ALL ON FUNCTION public.decide_pink_slip_and_apply_attendance(integer, boolean, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.decide_pink_slip_and_apply_attendance(integer, boolean, text) TO authenticated;

NOTIFY pgrst, 'reload schema';
COMMIT;
