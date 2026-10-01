-- Run ONLY in a fresh disposable PostgreSQL database, never a hosted project.
-- psql -v ON_ERROR_STOP=1 -f supabase/tests/student_read_only_dashboard.sql
-- Uses the repository's schema/RLS plus synthetic Supabase auth/storage schemas.
\set ON_ERROR_STOP on
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE service_role NOLOGIN;
CREATE SCHEMA auth;
CREATE SCHEMA storage;
CREATE TABLE auth.users (id uuid PRIMARY KEY, email text, raw_user_meta_data jsonb);
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$
  SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
CREATE TABLE storage.objects (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, bucket_id text, name text);
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
CREATE POLICY legacy_storage_access ON storage.objects FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT USAGE ON SCHEMA public, auth, storage TO anon, authenticated;

\ir ../../pinkslip-attendance-system/database/supabase_complete_schema.sql
-- The provisioning body isn't under test; its historical public EXECUTE grant is.
CREATE FUNCTION public.provision_auth_user(text, text, text, text, text)
RETURNS uuid LANGUAGE sql SECURITY DEFINER AS $$ SELECT null::uuid $$;
\ir ../migrations/20260930110000_role_access_hardening.sql
\ir ../migrations/20260926123000_atomic_pink_slip_submission.sql

-- Seed test identities before any requests, without the signup trigger.
DROP TRIGGER on_auth_user_created ON auth.users;
INSERT INTO auth.users(id, email)
SELECT ('00000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
       'test-' || n || '@example.invalid'
FROM generate_series(1,8) n;
INSERT INTO public.users(user_id, auth_id, email, full_name, role, is_active)
SELECT n, ('00000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
       'test-' || n || '@example.invalid', 'Test ' || n,
       (CASE n WHEN 4 THEN 'HOD' WHEN 5 THEN 'ADVISOR' ELSE 'STUDENT' END)::public.user_role,
       n <> 6
FROM generate_series(1,8) n;
INSERT INTO public.students(student_id, roll_number, register_number, section_id, student_name)
SELECT n, 'ROLL-' || n, 'REG-' || n,
       CASE WHEN n = 3 THEN 'III-AIDS-C' ELSE 'III-AIDS-B' END, 'Test ' || n
FROM unnest(ARRAY[1,2,3,6,8]) n;
INSERT INTO public.staff_advisors(staff_id, staff_code, assigned_section)
VALUES(5, 'TEST-ADVISOR', 'III-AIDS-B');
INSERT INTO public.daily_attendance(student_id, attendance_date, is_present, marked_by)
SELECT 1, current_date - n, n <> 4, 5 FROM generate_series(1,4) n;
INSERT INTO public.daily_attendance(student_id, attendance_date, is_present, marked_by)
VALUES (1, current_date + 30, false, 5), (2, current_date - 1, false, 5), (3, current_date - 1, true, 4);
INSERT INTO public.leave_slips(student_id, reason, from_date, to_date)
VALUES (1, 'Private leave', current_date, current_date), (3, 'Other section', current_date, current_date);
INSERT INTO public.biometric_punches(student_id, punch_timestamp, punch_type, source)
VALUES(1, now(), 'IN', 'MANUAL_OVERRIDE');
INSERT INTO storage.objects(bucket_id, name) VALUES('leave_attachments', 'test.pdf');

-- Explicit SQL grants ensure failures are RLS denials, not missing table grants.
GRANT ALL ON ALL TABLES IN SCHEMA public, storage TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public, storage TO authenticated;
-- Simulate permissive leftovers; the new restrictions must still deny students.
CREATE POLICY legacy_student_slips ON public.leave_slips FOR ALL TO authenticated USING (public.get_user_role() = 'STUDENT') WITH CHECK (public.get_user_role() = 'STUDENT');
CREATE POLICY legacy_student_attendance ON public.daily_attendance FOR ALL TO authenticated USING (public.get_user_role() = 'STUDENT') WITH CHECK (public.get_user_role() = 'STUDENT');
CREATE POLICY legacy_profile_read ON public.users FOR SELECT TO authenticated USING (true);
CREATE POLICY legacy_roster_read ON public.students FOR SELECT TO authenticated USING (public.get_user_role() = 'STUDENT');

\ir ../migrations/20260930120000_student_read_only_dashboard.sql
-- Reapplication should also succeed without widening permissions.
\ir ../migrations/20260930120000_student_read_only_dashboard.sql

CREATE FUNCTION public.test_assert(ok boolean, message text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN IF ok IS DISTINCT FROM TRUE THEN RAISE EXCEPTION 'FAILED: %', message; END IF; END;
$$;
SET ROLE authenticated;
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
SELECT test_assert((SELECT count(*) = 1 AND min(roll_number) = 'ROLL-1' AND min(attendance_percentage) = 75.0 FROM get_my_student_dashboard()), 'only own summary, exact recorded-day percentage, excludes future dates');
SELECT test_assert((SELECT count(*) = 1 FROM public.users), 'only own profile despite legacy broad reads');
SELECT test_assert((SELECT count(*) = 1 FROM public.students), 'only own roster despite legacy broad reads');
SELECT test_assert((SELECT count(*) = 0 FROM public.daily_attendance), 'no raw attendance');
SELECT test_assert((SELECT count(*) = 0 FROM public.leave_slips), 'no leave history');
SELECT test_assert((SELECT count(*) = 0 FROM public.biometric_punches), 'no biometric details');
SELECT test_assert((SELECT count(*) = 0 FROM storage.objects), 'no leave attachments');
SELECT test_assert(NOT has_function_privilege(current_user, 'public.provision_auth_user(text,text,text,text,text)', 'EXECUTE'), 'no privileged account provisioning');
DO $$
DECLARE target integer;
BEGIN
  FOREACH target IN ARRAY ARRAY[1,2] LOOP
    BEGIN
      INSERT INTO public.leave_slips(student_id, reason, from_date, to_date)
      VALUES(target, 'Forbidden', current_date, current_date);
      RAISE EXCEPTION 'FAILED: student inserted leave for %', target;
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  END LOOP;
  BEGIN
    INSERT INTO public.daily_attendance(student_id, attendance_date, is_present, marked_by)
    VALUES(1, current_date, true, 1);
    RAISE EXCEPTION 'FAILED: student marked attendance';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    INSERT INTO storage.objects(bucket_id, name) VALUES('leave_attachments', 'student-upload.pdf');
    RAISE EXCEPTION 'FAILED: student uploaded attachment';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    UPDATE public.users SET role = 'HOD' WHERE user_id = 1;
    RAISE EXCEPTION 'FAILED: student changed role';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.submit_pink_slip_and_mark_attendance(1, 'Forbidden', current_date, false);
    RAISE EXCEPTION 'FAILED: student used submission RPC';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Only an advisor or HOD can issue a pink slip' THEN RAISE; END IF;
  END;
  UPDATE public.leave_slips SET reason = 'Forbidden' WHERE student_id = 1;
  IF FOUND THEN RAISE EXCEPTION 'FAILED: student changed slip'; END IF;
  DELETE FROM public.leave_slips WHERE student_id = 1;
  IF FOUND THEN RAISE EXCEPTION 'FAILED: student deleted slip'; END IF;
END;
$$;

SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
SELECT test_assert((SELECT count(*) = 1 AND min(roll_number) = 'ROLL-2' AND min(attendance_percentage) = 0 FROM get_my_student_dashboard()), 'second student receives only own 0 percent');
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000006';
SELECT test_assert((SELECT count(*) = 0 FROM get_my_student_dashboard()), 'inactive student receives no summary');
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000007';
SELECT test_assert((SELECT count(*) = 0 FROM get_my_student_dashboard()), 'unlinked student receives no summary');
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000008';
SELECT test_assert((SELECT count(*) = 1 AND bool_and(attendance_percentage IS NULL) FROM get_my_student_dashboard()), 'no attendance stays unknown');

SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000005';
SELECT test_assert((SELECT count(*) = 0 FROM get_my_student_dashboard()), 'advisor cannot impersonate student summary');
SELECT test_assert((SELECT count(*) = 6 FROM public.daily_attendance), 'advisor reads own section attendance');
SELECT test_assert((SELECT count(*) = 1 FROM public.leave_slips), 'advisor reads own section slips');
SELECT public.submit_pink_slip_and_mark_attendance(1, 'Advisor submission', current_date, false);
DO $$
BEGIN
  BEGIN
    PERFORM public.submit_pink_slip_and_mark_attendance(3, 'Other section', current_date, false);
    RAISE EXCEPTION 'FAILED: advisor wrote to another section';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Advisor cannot issue a pink slip for this student' THEN RAISE; END IF;
  END;
END;
$$;
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000004';
SELECT test_assert((SELECT count(*) = 8 FROM public.daily_attendance), 'HOD reads all attendance');
SELECT public.submit_pink_slip_and_mark_attendance(3, 'HOD submission', current_date, false);

-- Department chart drill-down: return only true absences, and only to the HOD.
INSERT INTO public.daily_attendance(
  student_id, attendance_date, is_present, leave_type, marked_by
)
VALUES (8, current_date - 1, false, 'OD', 5);
RESET ROLE;
\ir ../migrations/20261001090000_hod_department_absence_drilldown.sql
\ir ../migrations/20261001093000_hod_section_absence_drilldown.sql
SET ROLE authenticated;
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000004';
SELECT test_assert(
  (public.get_department_absences(current_date - 1)->>'recorded_count')::integer = 4,
  'department drill-down reports every recorded student, including OD'
);
SELECT test_assert(
  jsonb_array_length(public.get_department_absences(current_date - 1)->'absences') = 1
  AND public.get_department_absences(current_date - 1)->'absences'->0->>'roll_number' = 'ROLL-2',
  'department drill-down excludes OD and returns the absent student details'
);
SELECT test_assert(
  (public.get_department_absences(current_date - 20)->>'recorded_count')::integer = 0,
  'department drill-down distinguishes a day with no attendance records'
);
SELECT test_assert(
  (public.get_section_absences(current_date - 1, 'III-AIDS-B')->>'recorded_count')::integer = 3
  AND jsonb_array_length(public.get_section_absences(current_date - 1, 'III-AIDS-B')->'absences') = 1
  AND public.get_section_absences(current_date - 1, 'III-AIDS-B')->'absences'->0->>'roll_number' = 'ROLL-2',
  'section drill-down returns only the selected section and excludes OD'
);
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000005';
DO $$
BEGIN
  BEGIN
    PERFORM public.get_department_absences(current_date - 1);
    RAISE EXCEPTION 'FAILED: advisor accessed department absence drill-down';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.get_section_absences(current_date - 1, 'III-AIDS-B');
    RAISE EXCEPTION 'FAILED: advisor accessed section absence drill-down';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$$;

SET ROLE anon;
SELECT public.test_assert(NOT has_function_privilege(current_user, 'public.get_my_student_dashboard()', 'EXECUTE'), 'anonymous caller denied summary');
SELECT public.test_assert(NOT has_function_privilege(current_user, 'public.get_department_absences(date)', 'EXECUTE'), 'anonymous caller denied department drill-down');
SELECT public.test_assert(NOT has_function_privilege(current_user, 'public.get_section_absences(date, text)', 'EXECUTE'), 'anonymous caller denied section drill-down');
RESET ROLE;
\echo 'PASS: student summary, read/write isolation, and staff workflows'
