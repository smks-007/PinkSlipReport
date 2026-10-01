-- Role access hardening for authenticated application clients.
-- Apply after the existing production-hardening and phase2 migrations.
BEGIN;

REVOKE INSERT, UPDATE, DELETE ON TABLE
  public.users,
  public.staff_advisors,
  public.students
FROM authenticated;

GRANT SELECT ON TABLE
  public.users,
  public.staff_advisors,
  public.students
TO authenticated;

-- A client can read its own profile. HODs can read profiles for administration.
DROP POLICY IF EXISTS "auth_read_users" ON public.users;
DROP POLICY IF EXISTS "user_read_self_or_hod" ON public.users;
CREATE POLICY "user_read_self_or_hod"
ON public.users FOR SELECT TO authenticated
USING (auth_id = auth.uid() OR get_user_role() = 'HOD');

-- Staff records are visible to the HOD and to the advisor who owns the record.
DROP POLICY IF EXISTS "auth_read_advisors" ON public.staff_advisors;
DROP POLICY IF EXISTS "hod_read_all_advisors" ON public.staff_advisors;
DROP POLICY IF EXISTS "advisor_read_self" ON public.staff_advisors;
CREATE POLICY "hod_read_all_advisors"
ON public.staff_advisors FOR SELECT TO authenticated
USING (get_user_role() = 'HOD');
CREATE POLICY "advisor_read_self"
ON public.staff_advisors FOR SELECT TO authenticated
USING (
  get_user_role() = 'ADVISOR'
  AND staff_id = (
    SELECT user_id FROM public.users WHERE auth_id = auth.uid()
  )
);

-- Students are visible only to HODs, the assigned advisor, or the student.
DROP POLICY IF EXISTS "auth_read_students" ON public.students;
DROP POLICY IF EXISTS "student_read_own" ON public.students;
DROP POLICY IF EXISTS "advisor_read_section_students" ON public.students;
DROP POLICY IF EXISTS "hod_read_all_students" ON public.students;
CREATE POLICY "hod_read_all_students"
ON public.students FOR SELECT TO authenticated
USING (get_user_role() = 'HOD');
CREATE POLICY "advisor_read_section_students"
ON public.students FOR SELECT TO authenticated
USING (
  get_user_role() = 'ADVISOR'
  AND section_id = get_advisor_section()
);
CREATE POLICY "student_read_own"
ON public.students FOR SELECT TO authenticated
USING (
  get_user_role() = 'STUDENT'
  AND student_id = get_student_id()
);

COMMIT;
