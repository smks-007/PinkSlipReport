-- Step 5: Promotion workflow for stable cohort section IDs.
BEGIN;

CREATE OR REPLACE FUNCTION public.submit_my_promotion_request(
  p_from_year integer, p_batch_year text, p_semester_completed integer,
  p_semester_end_date date, p_grace_transition_days integer, p_advisor_remarks text
)
RETURNS public.promotions
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_section text; v_year integer; v_actor integer; v_total integer; v_result public.promotions;
BEGIN
  IF auth.uid() IS NULL OR public.get_user_role() <> 'ADVISOR' THEN
    RAISE EXCEPTION 'Only an authenticated advisor can submit a promotion request' USING ERRCODE = '42501';
  END IF;
  IF p_from_year NOT BETWEEN 1 AND 4 OR p_semester_completed NOT BETWEEN 1 AND 8
     OR p_grace_transition_days NOT BETWEEN 7 AND 10
     OR p_semester_end_date IS NULL
     OR p_semester_end_date > (current_timestamp AT TIME ZONE 'Asia/Kolkata')::date THEN
    RAISE EXCEPTION 'Invalid promotion request details' USING ERRCODE = '22023';
  END IF;
  IF (current_timestamp AT TIME ZONE 'Asia/Kolkata')::date < p_semester_end_date + p_grace_transition_days THEN
    RAISE EXCEPTION 'The configured grace period has not ended' USING ERRCODE = '22023';
  END IF;

  SELECT public.get_advisor_section(), u.user_id
  INTO v_section, v_actor FROM public.users u
  WHERE u.auth_id = auth.uid() AND u.is_active IS TRUE;
  SELECT s.year INTO v_year FROM public.sections s WHERE s.section_id = v_section;
  IF v_section IS NULL OR v_year IS NULL OR v_year <> p_from_year THEN
    RAISE EXCEPTION 'Advisor can request promotion only for the assigned academic year and section' USING ERRCODE = '42501';
  END IF;
  SELECT count(*) INTO v_total FROM public.students s WHERE s.section_id = v_section;
  IF v_total = 0 THEN RAISE EXCEPTION 'The assigned section has no active students' USING ERRCODE = '22023'; END IF;

  INSERT INTO public.promotions (
    from_year, to_year, section, batch_year, semester_completed, semester_end_date,
    grace_transition_days, eligible_promotion_date, total_students, status,
    advisor_name, advisor_remarks, date_forwarded_by_advisor
  )
  SELECT p_from_year, CASE WHEN p_from_year = 4 THEN 5 ELSE p_from_year + 1 END,
    sec.section_name, btrim(p_batch_year), p_semester_completed, p_semester_end_date,
    p_grace_transition_days, p_semester_end_date + p_grace_transition_days, v_total,
    'FORWARDED_TO_HOD', u.full_name, nullif(btrim(p_advisor_remarks), ''), now()
  FROM public.users u JOIN public.sections sec ON sec.section_id = v_section
  WHERE u.user_id = v_actor
  RETURNING * INTO v_result;

  INSERT INTO public.promotion_audit_log(promotion_id, action, actor_user_id, remarks)
  VALUES (v_result.promotion_id, 'REQUESTED', v_actor, nullif(btrim(p_advisor_remarks), ''));
  RETURN v_result;
EXCEPTION WHEN unique_violation THEN
  RAISE EXCEPTION 'An active promotion request already exists for this cohort and semester' USING ERRCODE = '23505';
END;
$$;

CREATE OR REPLACE FUNCTION public.decide_promotion_request(
  p_promotion_id integer, p_approve boolean, p_hod_remarks text
)
RETURNS public.promotions
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_request public.promotions; v_hod_id integer; v_hod_name text;
  v_section text; v_moved integer;
BEGIN
  IF auth.uid() IS NULL OR public.get_user_role() <> 'HOD' THEN
    RAISE EXCEPTION 'Only an authenticated HOD can decide a promotion request' USING ERRCODE = '42501';
  END IF;
  IF nullif(btrim(p_hod_remarks), '') IS NULL THEN
    RAISE EXCEPTION 'HOD remarks are required' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_request FROM public.promotions
  WHERE promotion_id = p_promotion_id FOR UPDATE;
  IF NOT FOUND OR v_request.status <> 'FORWARDED_TO_HOD' THEN
    RAISE EXCEPTION 'Only a forwarded request can be decided' USING ERRCODE = '22023';
  END IF;
  SELECT user_id, full_name INTO v_hod_id, v_hod_name FROM public.users
  WHERE auth_id = auth.uid() AND is_active IS TRUE;

  IF NOT p_approve THEN
    UPDATE public.promotions SET status = 'REJECTED', hod_name = v_hod_name,
      hod_remarks = btrim(p_hod_remarks), date_approved_by_hod = now()
    WHERE promotion_id = p_promotion_id RETURNING * INTO v_request;
    INSERT INTO public.promotion_audit_log(promotion_id, action, actor_user_id, remarks)
    VALUES (p_promotion_id, 'REJECTED', v_hod_id, btrim(p_hod_remarks));
    RETURN v_request;
  END IF;

  SELECT section_id INTO v_section FROM public.sections
  WHERE year = v_request.from_year AND section_name = upper(v_request.section)
  ORDER BY cohort_year DESC LIMIT 1;
  IF v_section IS NULL THEN RAISE EXCEPTION 'The cohort section was not found' USING ERRCODE = 'P0002'; END IF;
  SELECT count(*) INTO v_moved FROM public.students WHERE section_id = v_section;
  IF v_moved = 0 THEN RAISE EXCEPTION 'No students found in this cohort' USING ERRCODE = '22023'; END IF;

  IF v_request.from_year < 4 THEN
    UPDATE public.student_section_history SET ended_on = greatest(started_on, current_date - 1),
      promotion_id = p_promotion_id WHERE section_id = v_section AND ended_on IS NULL;
    UPDATE public.sections SET year = v_request.to_year WHERE section_id = v_section;
    INSERT INTO public.student_section_history(student_id, section_id, study_year, started_on, promotion_id)
    SELECT s.student_id, v_section, v_request.to_year, current_date, p_promotion_id
    FROM public.students s WHERE s.section_id = v_section;
  ELSE
    INSERT INTO public.alumni_archive(student_id, student_name, roll_number, section, batch_year,
      graduation_date, retention_period_years, retention_expiry_date, cumulative_attendance, total_ods_attended, is_purged)
    SELECT s.student_id, s.student_name, s.roll_number, s.section_id, v_request.batch_year,
      current_date, 2, (current_date + interval '2 years')::date,
      coalesce(round(100.0 * count(a.attendance_id) FILTER (WHERE a.is_present) / nullif(count(a.attendance_id), 0), 2), 0), 0, false
    FROM public.students s LEFT JOIN public.daily_attendance a ON a.student_id = s.student_id
    WHERE s.section_id = v_section AND NOT EXISTS (
      SELECT 1 FROM public.alumni_archive aa WHERE aa.student_id = s.student_id AND aa.is_purged IS FALSE)
    GROUP BY s.student_id, s.student_name, s.roll_number, s.section_id;
  END IF;

  UPDATE public.promotions SET status = 'APPROVED_BY_HOD', hod_name = v_hod_name,
    hod_remarks = btrim(p_hod_remarks), date_approved_by_hod = now()
  WHERE promotion_id = p_promotion_id RETURNING * INTO v_request;
  INSERT INTO public.promotion_audit_log(promotion_id, action, actor_user_id, remarks, metadata)
  VALUES (p_promotion_id, CASE WHEN v_request.from_year = 4 THEN 'ARCHIVED' ELSE 'APPROVED' END,
    v_hod_id, btrim(p_hod_remarks), jsonb_build_object('affected_students', v_moved));
  RETURN v_request;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_my_promotion_request(integer, text, integer, date, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_my_promotion_request(integer, text, integer, date, integer, text) TO authenticated;
REVOKE ALL ON FUNCTION public.decide_promotion_request(integer, boolean, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.decide_promotion_request(integer, boolean, text) TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
