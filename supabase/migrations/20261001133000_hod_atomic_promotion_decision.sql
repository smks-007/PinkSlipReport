-- Step 4: HOD-only atomic promotion approval and rejection.
BEGIN;

-- Keep a dated section snapshot with every attendance record.  A student's
-- current section changes during promotion; reports for past dates must not.
ALTER TABLE public.daily_attendance
  ADD COLUMN IF NOT EXISTS section_id_at_marking varchar(15)
  REFERENCES public.sections(section_id) ON DELETE RESTRICT;

UPDATE public.daily_attendance a
SET section_id_at_marking = s.section_id
FROM public.students s
WHERE s.student_id = a.student_id
  AND a.section_id_at_marking IS NULL;

CREATE OR REPLACE FUNCTION public.capture_attendance_section_snapshot()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.section_id_at_marking IS NULL THEN
    SELECT s.section_id INTO NEW.section_id_at_marking
    FROM public.students s
    WHERE s.student_id = NEW.student_id;
  END IF;
  IF NEW.section_id_at_marking IS NULL THEN
    RAISE EXCEPTION 'Attendance student % does not have an assigned section', NEW.student_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_capture_attendance_section_snapshot ON public.daily_attendance;
CREATE TRIGGER trg_capture_attendance_section_snapshot
BEFORE INSERT ON public.daily_attendance
FOR EACH ROW EXECUTE FUNCTION public.capture_attendance_section_snapshot();

-- Audit each student's enrollment so a promotion never erases academic
-- history.  `students.section_id` remains the current operational section.
CREATE TABLE IF NOT EXISTS public.student_section_history (
  history_id bigserial PRIMARY KEY,
  student_id integer NOT NULL REFERENCES public.students(student_id) ON DELETE RESTRICT,
  section_id varchar(15) NOT NULL REFERENCES public.sections(section_id) ON DELETE RESTRICT,
  started_on date NOT NULL,
  ended_on date,
  promotion_id integer REFERENCES public.promotions(promotion_id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (ended_on IS NULL OR ended_on >= started_on)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_student_current_section_history
  ON public.student_section_history(student_id)
  WHERE ended_on IS NULL;

ALTER TABLE public.student_section_history ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.student_section_history FROM PUBLIC, anon, authenticated;
DROP POLICY IF EXISTS "hod_read_student_section_history"
  ON public.student_section_history;
CREATE POLICY "hod_read_student_section_history"
  ON public.student_section_history FOR SELECT TO authenticated
  USING (public.get_user_role() = 'HOD');

INSERT INTO public.student_section_history (student_id, section_id, started_on)
SELECT s.student_id, s.section_id, current_date
FROM public.students s
WHERE s.section_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.student_section_history h
    WHERE h.student_id = s.student_id AND h.ended_on IS NULL
  );

CREATE OR REPLACE FUNCTION public.decide_promotion_request(
  p_promotion_id integer,
  p_approve boolean,
  p_hod_remarks text
)
RETURNS public.promotions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_request public.promotions;
  v_hod_id integer;
  v_hod_name text;
  v_source_section text;
  v_target_section text;
  v_moved_count integer;
BEGIN
  IF auth.uid() IS NULL OR public.get_user_role() <> 'HOD' THEN
    RAISE EXCEPTION 'Only an authenticated HOD can decide a promotion request' USING ERRCODE = '42501';
  END IF;
  IF nullif(btrim(p_hod_remarks), '') IS NULL THEN
    RAISE EXCEPTION 'HOD remarks are required' USING ERRCODE = '22023';
  END IF;

  SELECT p.* INTO v_request
  FROM public.promotions p
  WHERE p.promotion_id = p_promotion_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Promotion request was not found' USING ERRCODE = 'P0002';
  END IF;
  IF v_request.status <> 'FORWARDED_TO_HOD' THEN
    RAISE EXCEPTION 'Only a request forwarded by an advisor can be decided' USING ERRCODE = '22023';
  END IF;

  SELECT user_id, full_name INTO v_hod_id, v_hod_name
  FROM public.users
  WHERE auth_id = auth.uid() AND is_active IS TRUE;

  IF NOT p_approve THEN
    UPDATE public.promotions
    SET status = 'REJECTED', hod_name = v_hod_name,
        hod_remarks = btrim(p_hod_remarks), date_approved_by_hod = now()
    WHERE promotion_id = p_promotion_id
    RETURNING * INTO v_request;
    INSERT INTO public.promotion_audit_log(promotion_id, action, actor_user_id, remarks)
    VALUES (p_promotion_id, 'REJECTED', v_hod_id, btrim(p_hod_remarks));
    RETURN v_request;
  END IF;

  v_source_section := CASE v_request.from_year
    WHEN 1 THEN 'I' WHEN 2 THEN 'II' WHEN 3 THEN 'III' ELSE 'IV' END
    || '-AIDS-' || upper(v_request.section);

  IF v_request.from_year < 4 THEN
    v_target_section := CASE v_request.to_year
      WHEN 2 THEN 'II' WHEN 3 THEN 'III' WHEN 4 THEN 'IV' END
      || '-AIDS-' || upper(v_request.section);
    IF NOT EXISTS (SELECT 1 FROM public.sections WHERE section_id = v_target_section) THEN
      RAISE EXCEPTION 'Target section % does not exist', v_target_section USING ERRCODE = '22023';
    END IF;
    UPDATE public.student_section_history
    SET ended_on = greatest(started_on, current_date - 1),
        promotion_id = p_promotion_id
    WHERE section_id = v_source_section
      AND ended_on IS NULL;

    UPDATE public.students
    SET section_id = v_target_section
    WHERE section_id = v_source_section;
    GET DIAGNOSTICS v_moved_count = ROW_COUNT;
    IF v_moved_count = 0 THEN
      RAISE EXCEPTION 'No students found in the promotion source section' USING ERRCODE = '22023';
    END IF;

    INSERT INTO public.student_section_history (student_id, section_id, started_on, promotion_id)
    SELECT s.student_id, v_target_section, current_date, p_promotion_id
    FROM public.students s
    WHERE s.section_id = v_target_section
      AND NOT EXISTS (
        SELECT 1 FROM public.student_section_history h
        WHERE h.student_id = s.student_id AND h.ended_on IS NULL
      );
  ELSE
    INSERT INTO public.alumni_archive (
      student_id, student_name, roll_number, section, batch_year,
      graduation_date, retention_period_years, retention_expiry_date,
      cumulative_attendance, total_ods_attended, is_purged
    )
    SELECT
      s.student_id, s.student_name, s.roll_number, s.section_id, v_request.batch_year,
      current_date, 2, (current_date + interval '2 years')::date,
      coalesce(round(100.0 * count(a.attendance_id) FILTER (WHERE a.is_present) / nullif(count(a.attendance_id), 0), 2), 0),
      0, false
    FROM public.students s
    LEFT JOIN public.daily_attendance a ON a.student_id = s.student_id
    WHERE s.section_id = v_source_section
      AND NOT EXISTS (
        SELECT 1 FROM public.alumni_archive archived
        WHERE archived.student_id = s.student_id AND archived.is_purged IS FALSE
      )
    GROUP BY s.student_id, s.student_name, s.roll_number, s.section_id;
    GET DIAGNOSTICS v_moved_count = ROW_COUNT;
    IF v_moved_count = 0 THEN
      RAISE EXCEPTION 'No eligible final-year students found to archive' USING ERRCODE = '22023';
    END IF;
  END IF;

  UPDATE public.promotions
  SET status = 'APPROVED_BY_HOD', hod_name = v_hod_name,
      hod_remarks = btrim(p_hod_remarks), date_approved_by_hod = now()
  WHERE promotion_id = p_promotion_id
  RETURNING * INTO v_request;

  INSERT INTO public.promotion_audit_log(promotion_id, action, actor_user_id, remarks, metadata)
  VALUES (p_promotion_id, CASE WHEN v_request.from_year = 4 THEN 'ARCHIVED' ELSE 'APPROVED' END,
          v_hod_id, btrim(p_hod_remarks), jsonb_build_object('affected_students', v_moved_count));
  RETURN v_request;
END;
$$;

REVOKE ALL ON FUNCTION public.decide_promotion_request(integer, boolean, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.decide_promotion_request(integer, boolean, text) TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
