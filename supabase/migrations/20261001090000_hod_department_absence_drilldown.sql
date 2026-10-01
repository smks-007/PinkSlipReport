-- HOD-only detailed absence drill-down for the department trend chart.
BEGIN;

CREATE OR REPLACE FUNCTION public.get_department_absences(
  p_attendance_date date
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  caller_role public.user_role;
  recorded_count integer;
  absence_rows jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required' USING ERRCODE = '42501';
  END IF;
  SELECT u.role INTO caller_role
  FROM public.users u
  WHERE u.auth_id = auth.uid() AND u.is_active IS TRUE;
  IF caller_role <> 'HOD' THEN
    RAISE EXCEPTION 'Only the HOD can view department absences' USING ERRCODE = '42501';
  END IF;
  IF p_attendance_date IS NULL OR
      p_attendance_date > (current_timestamp AT TIME ZONE 'Asia/Kolkata')::date THEN
    RAISE EXCEPTION 'Choose a recorded attendance date' USING ERRCODE = '22007';
  END IF;

  SELECT count(*) INTO recorded_count
  FROM public.daily_attendance a
  WHERE a.attendance_date = p_attendance_date;

  SELECT coalesce(jsonb_agg(to_jsonb(result) ORDER BY result.section_id, result.student_name), '[]'::jsonb)
  INTO absence_rows
  FROM (
    SELECT
      a.student_id,
      s.student_name,
      s.roll_number,
      s.register_number,
      s.section_id
    FROM public.daily_attendance a
    JOIN public.students s ON s.student_id = a.student_id
    WHERE a.attendance_date = p_attendance_date
      AND a.is_present IS FALSE
      AND coalesce(a.leave_type::text, '') NOT IN ('OD', 'ON_DUTY')
  ) result;

  RETURN jsonb_build_object(
    'recorded_count', recorded_count,
    'absences', absence_rows
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_department_absences(date) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_department_absences(date) TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
