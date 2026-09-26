-- Phase 2: authorization hardening for PinkSlipReport.
-- This corrective migration replaces broad policies from earlier migrations.

BEGIN;

ALTER TABLE public.sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_advisors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_slips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alumni_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcast_notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timetables ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE
  public.sections, public.users, public.staff_advisors, public.students,
  public.daily_attendance, public.leave_slips, public.academic_calendar,
  public.promotions, public.alumni_archive, public.broadcast_notices,
  public.timetables
FROM anon;

DROP POLICY IF EXISTS "public_all_academic_calendar" ON public.academic_calendar;
DROP POLICY IF EXISTS "authenticated_all_promotions" ON public.promotions;
DROP POLICY IF EXISTS "authenticated_all_alumni" ON public.alumni_archive;
DROP POLICY IF EXISTS "public_all_broadcast_notices" ON public.broadcast_notices;
DROP POLICY IF EXISTS "anon_read_staff_advisors" ON public.staff_advisors;
DROP POLICY IF EXISTS "auth_read_users" ON public.users;
DROP POLICY IF EXISTS "timetables_read_all" ON public.timetables;
DROP POLICY IF EXISTS "timetables_write_faculty_hod" ON public.timetables;
DROP POLICY IF EXISTS "user_read_self_or_hod" ON public.users;
DROP POLICY IF EXISTS "authenticated_read_academic_calendar" ON public.academic_calendar;
DROP POLICY IF EXISTS "hod_manage_academic_calendar" ON public.academic_calendar;
DROP POLICY IF EXISTS "hod_manage_promotions" ON public.promotions;
DROP POLICY IF EXISTS "advisor_read_promotions" ON public.promotions;
DROP POLICY IF EXISTS "advisor_update_promotions" ON public.promotions;
DROP POLICY IF EXISTS "hod_manage_alumni_archive" ON public.alumni_archive;
DROP POLICY IF EXISTS "authenticated_read_broadcast_notices" ON public.broadcast_notices;
DROP POLICY IF EXISTS "hod_insert_broadcast_notices" ON public.broadcast_notices;
DROP POLICY IF EXISTS "hod_update_broadcast_notices" ON public.broadcast_notices;
DROP POLICY IF EXISTS "hod_delete_broadcast_notices" ON public.broadcast_notices;
DROP POLICY IF EXISTS "authenticated_read_timetables" ON public.timetables;
DROP POLICY IF EXISTS "advisor_hod_manage_timetables" ON public.timetables;
DROP POLICY IF EXISTS "authenticated_read_leave_attachments" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_insert_leave_attachments" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_update_leave_attachments" ON storage.objects;

DROP POLICY IF EXISTS "Public Access to Leave Attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload to Leave Attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Update on Leave Attachments" ON storage.objects;

UPDATE storage.buckets
SET public = false
WHERE id = 'leave_attachments';

CREATE POLICY "user_read_self_or_hod"
ON public.users FOR SELECT TO authenticated
USING (auth_id = auth.uid() OR get_user_role() = 'HOD');

CREATE POLICY "authenticated_read_academic_calendar"
ON public.academic_calendar FOR SELECT TO authenticated
USING (true);

CREATE POLICY "hod_manage_academic_calendar"
ON public.academic_calendar FOR ALL TO authenticated
USING (get_user_role() = 'HOD')
WITH CHECK (get_user_role() = 'HOD');

CREATE POLICY "hod_manage_promotions"
ON public.promotions FOR ALL TO authenticated
USING (get_user_role() = 'HOD')
WITH CHECK (get_user_role() = 'HOD');

CREATE POLICY "advisor_read_promotions"
ON public.promotions FOR SELECT TO authenticated
USING (get_user_role() = 'ADVISOR' AND section = get_advisor_section());

CREATE POLICY "advisor_update_promotions"
ON public.promotions FOR UPDATE TO authenticated
USING (get_user_role() = 'ADVISOR' AND section = get_advisor_section())
WITH CHECK (get_user_role() = 'ADVISOR' AND section = get_advisor_section());

CREATE POLICY "hod_manage_alumni_archive"
ON public.alumni_archive FOR ALL TO authenticated
USING (get_user_role() = 'HOD')
WITH CHECK (get_user_role() = 'HOD');

CREATE POLICY "authenticated_read_broadcast_notices"
ON public.broadcast_notices FOR SELECT TO authenticated
USING (true);

CREATE POLICY "hod_insert_broadcast_notices"
ON public.broadcast_notices FOR INSERT TO authenticated
WITH CHECK (get_user_role() = 'HOD');

CREATE POLICY "hod_update_broadcast_notices"
ON public.broadcast_notices FOR UPDATE TO authenticated
USING (get_user_role() = 'HOD')
WITH CHECK (get_user_role() = 'HOD');

CREATE POLICY "hod_delete_broadcast_notices"
ON public.broadcast_notices FOR DELETE TO authenticated
USING (get_user_role() = 'HOD');

CREATE POLICY "authenticated_read_timetables"
ON public.timetables FOR SELECT TO authenticated
USING (true);

CREATE POLICY "advisor_hod_manage_timetables"
ON public.timetables FOR ALL TO authenticated
USING (get_user_role() IN ('ADVISOR', 'HOD'))
WITH CHECK (get_user_role() IN ('ADVISOR', 'HOD'));

CREATE POLICY "authenticated_read_leave_attachments"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'leave_attachments');

CREATE POLICY "authenticated_insert_leave_attachments"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'leave_attachments');

CREATE POLICY "authenticated_update_leave_attachments"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'leave_attachments')
WITH CHECK (bucket_id = 'leave_attachments');

REVOKE ALL ON SEQUENCE
  public.academic_calendar_calendar_id_seq,
  public.promotions_promotion_id_seq,
  public.alumni_archive_archive_id_seq,
  public.broadcast_notices_notice_id_seq,
  public.timetables_timetable_id_seq
FROM anon;

COMMIT;
