-- Student and class-representative accounts see their own details and an
-- attendance percentage only. Advisor/HOD workflows retain their existing RLS.
BEGIN;

CREATE OR REPLACE FUNCTION public.get_my_student_dashboard()
RETURNS TABLE (
  auth_id uuid,
  full_name text,
  email text,
  roll_number text,
  register_number text,
  section_id text,
  department text,
  attendance_percentage numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required' USING ERRCODE = '42501';
  END IF;

  -- Definer access is necessary to aggregate attendance without exposing its
  -- underlying rows. The caller cannot supply or override the student ID.
  RETURN QUERY
  SELECT
    u.auth_id, u.full_name::text, u.email::text,
    s.roll_number::text, s.register_number::text, s.section_id::text,
    sec.department::text,
    (
      SELECT round(
        100.0 * count(*) FILTER (WHERE a.is_present IS TRUE)
        / nullif(count(*), 0), 1
      )
      FROM public.daily_attendance a
      WHERE a.student_id = s.student_id
        AND a.attendance_date <= (current_timestamp AT TIME ZONE 'Asia/Kolkata')::date
    )
  FROM public.users u
  JOIN public.students s ON s.student_id = u.user_id
  LEFT JOIN public.sections sec ON sec.section_id = s.section_id
  WHERE u.auth_id = auth.uid()
    AND u.role = 'STUDENT'
    AND u.is_active IS TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_student_dashboard() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_student_dashboard() TO authenticated;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_slips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.biometric_punches ENABLE ROW LEVEL SECURITY;

-- Restrictive policies also constrain any older permissive policies left in
-- a deployed database. They grant no additional access to staff.
DROP POLICY IF EXISTS "student_profile_read_boundary" ON public.users;
CREATE POLICY "student_profile_read_boundary"
ON public.users AS RESTRICTIVE FOR SELECT TO authenticated
USING (
  public.get_user_role() IN ('HOD', 'ADVISOR')
  OR (public.get_user_role() = 'STUDENT' AND auth_id = auth.uid())
);

DROP POLICY IF EXISTS "student_roster_read_boundary" ON public.students;
CREATE POLICY "student_roster_read_boundary"
ON public.students AS RESTRICTIVE FOR SELECT TO authenticated
USING (
  public.get_user_role() IN ('HOD', 'ADVISOR')
  OR (public.get_user_role() = 'STUDENT' AND student_id = public.get_student_id())
);

REVOKE INSERT, UPDATE, DELETE ON public.users, public.students, public.staff_advisors
FROM authenticated;

DROP POLICY IF EXISTS "student_read_own_attendance" ON public.daily_attendance;
DROP POLICY IF EXISTS "student_attendance_summary_only" ON public.daily_attendance;
CREATE POLICY "student_attendance_summary_only"
ON public.daily_attendance AS RESTRICTIVE FOR ALL TO authenticated
USING (public.get_user_role() IN ('HOD', 'ADVISOR'))
WITH CHECK (public.get_user_role() IN ('HOD', 'ADVISOR'));

DROP POLICY IF EXISTS "student_read_own_slips" ON public.leave_slips;
DROP POLICY IF EXISTS "student_insert_own_slips" ON public.leave_slips;
DROP POLICY IF EXISTS "staff_only_leave_slips" ON public.leave_slips;
CREATE POLICY "staff_only_leave_slips"
ON public.leave_slips AS RESTRICTIVE FOR ALL TO authenticated
USING (public.get_user_role() IN ('HOD', 'ADVISOR'))
WITH CHECK (public.get_user_role() IN ('HOD', 'ADVISOR'));

-- Biometric events must not provide another route to detailed attendance.
DROP POLICY IF EXISTS "staff_only_biometric_events" ON public.biometric_punches;
CREATE POLICY "staff_only_biometric_events"
ON public.biometric_punches AS RESTRICTIVE FOR ALL TO authenticated
USING (public.get_user_role() IN ('HOD', 'ADVISOR'))
WITH CHECK (public.get_user_role() IN ('HOD', 'ADVISOR'));

DROP POLICY IF EXISTS "staff_only_leave_attachments" ON storage.objects;
CREATE POLICY "staff_only_leave_attachments"
ON storage.objects AS RESTRICTIVE FOR ALL TO authenticated
USING (
  bucket_id <> 'leave_attachments'
  OR public.get_user_role() IN ('HOD', 'ADVISOR')
)
WITH CHECK (
  bucket_id <> 'leave_attachments'
  OR public.get_user_role() IN ('HOD', 'ADVISOR')
);

-- This legacy setup helper can change passwords and roles with definer rights.
-- It must not be a route around the student restrictions via a direct RPC.
REVOKE ALL ON FUNCTION public.provision_auth_user(text, text, text, text, text)
FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.provision_auth_user(text, text, text, text, text)
TO service_role;

NOTIFY pgrst, 'reload schema';
COMMIT;
