-- Keep advisor pink-slip creation and attendance synchronization atomic.
-- The function runs with definer privileges, but still validates the caller's
-- authenticated role and assigned section before writing any data.

BEGIN;

CREATE OR REPLACE FUNCTION public.submit_pink_slip_and_mark_attendance(
  p_student_id integer,
  p_reason text,
  p_date date,
  p_is_on_duty boolean,
  p_letter_url text DEFAULT NULL,
  p_status text DEFAULT 'SUBMITTED',
  p_advisor_remarks text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  v_role text;
  v_marked_by integer;
  v_db_status text := upper(coalesce(p_status, 'SUBMITTED'));
  v_section varchar(15);
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required';
  END IF;

  v_role := get_user_role()::text;
  IF v_role = 'HOD' THEN
    NULL;
  ELSIF v_role = 'ADVISOR' THEN
    v_section := get_advisor_section();
    IF NOT EXISTS (
      SELECT 1
      FROM public.students
      WHERE student_id = p_student_id
        AND section_id = v_section
    ) THEN
      RAISE EXCEPTION 'Advisor cannot issue a pink slip for this student';
    END IF;
  ELSE
    RAISE EXCEPTION 'Only an advisor or HOD can issue a pink slip';
  END IF;

  IF v_db_status NOT IN ('APPROVED', 'REJECTED', 'PENDING_HOD', 'SUBMITTED') THEN
    v_db_status := 'SUBMITTED';
  END IF;

  SELECT user_id INTO v_marked_by
  FROM public.users
  WHERE auth_id = auth.uid();

  INSERT INTO public.leave_slips (
    student_id, reason, from_date, to_date, is_informed,
    letter_document_url, status, advisor_remarks, created_at
  ) VALUES (
    p_student_id, p_reason, p_date, p_date, true,
    p_letter_url, v_db_status::public.slip_status, p_advisor_remarks, now()
  );

  IF NOT p_is_on_duty THEN
    INSERT INTO public.daily_attendance (
      student_id, attendance_date, is_present, leave_type,
      punch_method, marked_by, updated_at
    ) VALUES (
      p_student_id, p_date, false, 'INFORMED',
      'MANUAL_OVERRIDE', v_marked_by, now()
    )
    ON CONFLICT (student_id, attendance_date)
    DO UPDATE SET
      is_present = false,
      leave_type = 'INFORMED',
      punch_method = 'MANUAL_OVERRIDE',
      marked_by = excluded.marked_by,
      updated_at = now();
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_pink_slip_and_mark_attendance(
  integer, text, date, boolean, text, text, text
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_pink_slip_and_mark_attendance(
  integer, text, date, boolean, text, text, text
) TO authenticated;

-- Ensure PostgREST exposes the newly-created RPC immediately after deploy.
NOTIFY pgrst, 'reload schema';

COMMIT;
