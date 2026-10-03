-- Replacement for the semester report RPC. Returns one JSON object per student
-- to avoid positional TABLE-return parsing issues in older deployed schemas.
BEGIN;

DROP FUNCTION IF EXISTS public.get_hod_semester_total_report(integer);

CREATE FUNCTION public.get_hod_semester_total_report(p_study_year integer)
RETURNS TABLE(report jsonb)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  v_start_date date;
  v_end_date date;
BEGIN
  IF auth.uid() IS NULL OR get_user_role()::text <> 'HOD' THEN
    RAISE EXCEPTION 'Only the HOD can generate a semester report';
  END IF;

  SELECT start_date, end_date INTO v_start_date, v_end_date
  FROM public.academic_term_settings
  WHERE study_year = p_study_year;
  IF v_start_date IS NULL OR v_end_date IS NULL THEN
    RAISE EXCEPTION 'Configure the academic term for Year % before generating its report', p_study_year;
  END IF;

  RETURN QUERY
  SELECT jsonb_build_object(
    'student_id', s.student_id,
    'student_name', s.student_name,
    'roll_number', s.roll_number,
    'section_id', s.section_id,
    'attendance_days', (SELECT count(*) FROM public.daily_attendance a WHERE a.student_id = s.student_id AND a.attendance_date BETWEEN v_start_date AND v_end_date),
    'present_days', (SELECT count(*) FROM public.daily_attendance a WHERE a.student_id = s.student_id AND a.attendance_date BETWEEN v_start_date AND v_end_date AND a.is_present),
    'absent_days', (SELECT count(*) FROM public.daily_attendance a WHERE a.student_id = s.student_id AND a.attendance_date BETWEEN v_start_date AND v_end_date AND NOT a.is_present),
    'od_days', (SELECT count(*) FROM public.daily_attendance a WHERE a.student_id = s.student_id AND a.attendance_date BETWEEN v_start_date AND v_end_date AND a.is_present AND a.leave_type = 'OD'),
    'approved_leave_days', (SELECT sum(greatest(least(ls.to_date, v_end_date) - greatest(ls.from_date, v_start_date) + 1, 1)) FROM public.leave_slips ls WHERE ls.student_id = s.student_id AND ls.status = 'APPROVED'::public.slip_status AND ls.is_on_duty IS NOT TRUE AND ls.from_date <= v_end_date AND ls.to_date >= v_start_date)
  )
  FROM public.students s
  JOIN public.sections sec ON sec.section_id = s.section_id
  WHERE sec.year = p_study_year
  ORDER BY s.section_id, s.roll_number;
END;
$$;

REVOKE ALL ON FUNCTION public.get_hod_semester_total_report(integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_hod_semester_total_report(integer) TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
