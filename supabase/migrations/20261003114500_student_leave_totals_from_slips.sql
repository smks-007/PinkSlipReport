-- Authoritative leave-day totals. Pending/rejected slips and approved OD slips
-- are intentionally excluded. Advisors receive their assigned section only.

BEGIN;

CREATE OR REPLACE FUNCTION public.get_visible_student_leave_totals()
RETURNS TABLE(student_id integer, approved_leave_days integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  v_role text;
  v_section varchar(15);
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required';
  END IF;

  v_role := get_user_role()::text;
  IF v_role = 'ADVISOR' THEN
    v_section := get_advisor_section();
  ELSIF v_role <> 'HOD' THEN
    RAISE EXCEPTION 'Only an advisor or HOD can read leave totals';
  END IF;

  RETURN QUERY
  SELECT
    s.student_id,
    coalesce(sum(
      CASE
        WHEN ls.status = 'APPROVED'::public.slip_status
          AND coalesce(ls.is_on_duty, false) = false
        THEN greatest((ls.to_date - ls.from_date) + 1, 1)
        ELSE 0
      END
    ), 0)::integer AS approved_leave_days
  FROM public.students s
  LEFT JOIN public.leave_slips ls ON ls.student_id = s.student_id
  WHERE v_role = 'HOD' OR s.section_id = v_section
  GROUP BY s.student_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_visible_student_leave_totals() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_visible_student_leave_totals() TO authenticated;

NOTIFY pgrst, 'reload schema';
COMMIT;
