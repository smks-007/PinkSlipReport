-- HOD-only, database-calculated semester attendance report.
BEGIN;

CREATE OR REPLACE FUNCTION public.get_hod_semester_total_report(p_study_year integer)
RETURNS TABLE(
  student_id integer,
  student_name text,
  roll_number text,
  section_id text,
  attendance_days integer,
  present_days integer,
  absent_days integer,
  od_days integer,
  approved_leave_days integer,
  attendance_percentage numeric
)
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
  WITH attendance_summary AS (
    SELECT
      a.student_id,
      count(*)::integer AS attendance_days,
      (count(*) FILTER (WHERE a.is_present))::integer AS present_days,
      (count(*) FILTER (WHERE NOT a.is_present))::integer AS absent_days,
      (count(*) FILTER (WHERE a.is_present AND a.leave_type = 'OD'))::integer AS od_days
    FROM public.daily_attendance a
    WHERE a.attendance_date BETWEEN v_start_date AND v_end_date
    GROUP BY a.student_id
  ),
  leave_summary AS (
    SELECT
      ls.student_id,
      sum(
        greatest(least(ls.to_date, v_end_date) - greatest(ls.from_date, v_start_date) + 1, 1)
      )::integer AS approved_leave_days
    FROM public.leave_slips ls
    WHERE ls.status = 'APPROVED'::public.slip_status
      AND ls.is_on_duty IS NOT TRUE
      AND ls.from_date <= v_end_date
      AND ls.to_date >= v_start_date
    GROUP BY ls.student_id
  )
  SELECT
    s.student_id,
    CASE
      WHEN s.student_name IS NOT NULL AND btrim(s.student_name) <> '' THEN s.student_name
      WHEN u.full_name IS NOT NULL AND btrim(u.full_name) <> '' THEN u.full_name
      ELSE 'Student ' || s.student_id
    END::text,
    s.roll_number::text,
    s.section_id::text,
    CASE WHEN a.attendance_days IS NULL THEN 0 ELSE a.attendance_days END,
    CASE WHEN a.present_days IS NULL THEN 0 ELSE a.present_days END,
    CASE WHEN a.absent_days IS NULL THEN 0 ELSE a.absent_days END,
    CASE WHEN a.od_days IS NULL THEN 0 ELSE a.od_days END,
    CASE WHEN l.approved_leave_days IS NULL THEN 0 ELSE l.approved_leave_days END,
    CASE WHEN a.attendance_days IS NULL OR a.attendance_days = 0 THEN 0
         ELSE round(100.0 * a.present_days / a.attendance_days, 2)
    END
  FROM public.students s
  JOIN public.sections sec ON sec.section_id = s.section_id
  LEFT JOIN public.users u ON u.user_id = s.user_id
  LEFT JOIN attendance_summary a ON a.student_id = s.student_id
  LEFT JOIN leave_summary l ON l.student_id = s.student_id
  WHERE sec.year = p_study_year
  ORDER BY s.section_id, s.roll_number;
END;
$$;

REVOKE ALL ON FUNCTION public.get_hod_semester_total_report(integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_hod_semester_total_report(integer) TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
