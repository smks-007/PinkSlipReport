-- Step 2: HOD-only atomic broadcast creation with server-calculated scope.
BEGIN;

CREATE OR REPLACE FUNCTION public.create_broadcast_notice(
  p_title text, p_message text, p_priority text, p_template_type text,
  p_audience_type text, p_target_year integer DEFAULT NULL,
  p_target_section text DEFAULT NULL, p_expires_at timestamptz DEFAULT NULL
)
RETURNS public.broadcast_notices
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_summary jsonb; v_sender text; v_notice public.broadcast_notices;
BEGIN
  IF auth.uid() IS NULL OR public.get_user_role() <> 'HOD' THEN
    RAISE EXCEPTION 'Only an authenticated HOD can send a department notice' USING ERRCODE = '42501';
  END IF;
  IF length(btrim(coalesce(p_title, ''))) NOT BETWEEN 3 AND 200
     OR length(btrim(coalesce(p_message, ''))) NOT BETWEEN 10 AND 1500 THEN
    RAISE EXCEPTION 'Notice title or message length is invalid' USING ERRCODE = '22023';
  END IF;
  IF p_expires_at IS NOT NULL AND p_expires_at <= now() THEN
    RAISE EXCEPTION 'Expiry must be in the future' USING ERRCODE = '22023';
  END IF;
  v_summary := public.get_broadcast_audience_summary(p_audience_type, p_target_year, p_target_section);
  SELECT full_name INTO v_sender FROM public.users WHERE auth_id = auth.uid();
  INSERT INTO public.broadcast_notices(
    title, message, target_audience, priority, template_type, sender_name,
    audience_type, target_year, target_section, recipient_count, expires_at, status
  ) VALUES (
    btrim(p_title), btrim(p_message), v_summary->>'label', coalesce(nullif(btrim(p_priority), ''), 'Normal'),
    coalesce(nullif(btrim(p_template_type), ''), 'Others'), coalesce(v_sender, 'HOD'),
    p_audience_type, p_target_year, nullif(upper(btrim(p_target_section)), ''),
    (v_summary->>'total')::integer, p_expires_at, 'SENT'
  ) RETURNING * INTO v_notice;
  RETURN v_notice;
END;
$$;

REVOKE ALL ON FUNCTION public.create_broadcast_notice(text, text, text, text, text, integer, text, timestamptz) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_broadcast_notice(text, text, text, text, text, integer, text, timestamptz) TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
