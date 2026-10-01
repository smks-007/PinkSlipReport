-- HOD-only detailed absence drill-down for a selected section chart day.
BEGIN;

CREATE OR REPLACE FUNCTION public.get_section_absences(
  p_attendance_date date,
  p_section_id text
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
  IF p_section_id IS NULL OR btrim(p_section_id) = '' THEN
    RAISE EXCEPTION 'Choose a section' USING ERRCODE = '22023';
  END IF;
  IF p_attendance_date IS NULL OR
      p_attendance_date > (current_timestamp AT TIME ZONE 'Asia/Kolkata')::date THEN
    RAISE EXCEPTION 'Choose a recorded attendance date' USING ERRCODE = '22007';
  END IF;

  SELECT u.role INTO caller_role
  FROM public.users u
  WHERE u.auth_id = auth.uid() AND u.is_active IS TRUE;
  IF caller_role <> 'HOD' THEN
    RAISE EXCEPTION 'Only the HOD can view section absences' USING ERRCODE = '42501';
  END IF;

  SELECT count(*) INTO recorded_count
  FROM public.daily_attendance a
  JOIN public.students s ON s.student_id = a.student_id
  WHERE a.attendance_date = p_attendance_date
    AND s.section_id = p_section_id;

  SELECT coalesce(jsonb_agg(to_jsonb(result) ORDER BY result.student_name), '[]'::jsonb)
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
      AND s.section_id = p_section_id
      AND a.is_present IS FALSE
      AND coalesce(a.leave_type::text, '') NOT IN ('OD', 'ON_DUTY')
  ) result;

  RETURN jsonb_build_object(
    'recorded_count', recorded_count,
    'absences', absence_rows
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_section_absences(date, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_section_absences(date, text) TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
