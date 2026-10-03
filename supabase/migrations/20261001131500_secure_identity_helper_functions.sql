-- Repair identity helpers for security-definer RPCs that use an empty
-- search_path. Fully qualifying every relation prevents search-path attacks
-- and fixes "relation users does not exist" in deployed projects.
BEGIN;

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS public.user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT u.role
  FROM public.users u
  WHERE u.auth_id = auth.uid()
    AND u.is_active IS TRUE
  LIMIT 1
$$;

CREATE OR REPLACE FUNCTION public.get_advisor_section()
RETURNS varchar(15)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT sa.assigned_section
  FROM public.staff_advisors sa
  JOIN public.users u ON u.user_id = sa.staff_id
  WHERE u.auth_id = auth.uid()
    AND u.is_active IS TRUE
  LIMIT 1
$$;

CREATE OR REPLACE FUNCTION public.get_student_id()
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT s.student_id
  FROM public.students s
  JOIN public.users u ON u.user_id = s.student_id
  WHERE u.auth_id = auth.uid()
    AND u.is_active IS TRUE
  LIMIT 1
$$;

REVOKE ALL ON FUNCTION public.get_user_role() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_advisor_section() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_student_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_advisor_section() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_student_id() TO authenticated;

NOTIFY pgrst, 'reload schema';
COMMIT;
