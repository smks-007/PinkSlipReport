-- HOD-only interactive lists for the Today Attendance Count card.
BEGIN;

CREATE OR REPLACE FUNCTION public.get_today_department_attendance(
  p_status text
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  caller_role public.user_role;
  today_date date := (current_timestamp AT TIME ZONE 'Asia/Kolkata')::date;
  attendance_rows jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required' USING ERRCODE = '42501';
  END IF;
  IF p_status NOT IN ('ABSENT', 'OD') THEN
    RAISE EXCEPTION 'Choose ABSENT or OD' USING ERRCODE = '22023';
  END IF;
  SELECT u.role INTO caller_role
  FROM public.users u
  WHERE u.auth_id = auth.uid() AND u.is_active IS TRUE;
  IF caller_role <> 'HOD' THEN
    RAISE EXCEPTION 'Only the HOD can view department attendance lists' USING ERRCODE = '42501';
  END IF;

  SELECT coalesce(jsonb_agg(to_jsonb(result) ORDER BY result.section_id, result.student_name), '[]'::jsonb)
  INTO attendance_rows
  FROM (
    SELECT
      a.student_id,
      s.student_name,
      s.roll_number,
      s.register_number,
      s.section_id
    FROM public.daily_attendance a
    JOIN public.students s ON s.student_id = a.student_id
    WHERE a.attendance_date = today_date
      AND (
        (p_status = 'ABSENT' AND a.is_present IS FALSE
          AND coalesce(a.leave_type::text, '') NOT IN ('OD', 'ON_DUTY'))
        OR (p_status = 'OD' AND coalesce(a.leave_type::text, '') IN ('OD', 'ON_DUTY'))
      )
  ) result;

  RETURN jsonb_build_object(
    'recorded_count', (
      SELECT count(*)
      FROM public.daily_attendance a
      WHERE a.attendance_date = today_date
    ),
    'absences', attendance_rows
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_today_department_attendance(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_today_department_attendance(text) TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
