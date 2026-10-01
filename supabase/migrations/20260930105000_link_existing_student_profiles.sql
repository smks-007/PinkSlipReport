-- Corrective migration for projects that already applied the initial
-- registration trigger. It links a newly created Auth identity to a matching,
-- unlinked official STUDENT profile and rejects all other email conflicts.
BEGIN;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  existing_role public.user_role;
  existing_auth_id uuid;
BEGIN
  SELECT role, auth_id
  INTO existing_role, existing_auth_id
  FROM public.users
  WHERE email = NEW.email
  FOR UPDATE;

  IF FOUND THEN
    IF existing_role <> 'STUDENT'::public.user_role OR existing_auth_id IS NOT NULL THEN
      RAISE EXCEPTION 'An active department profile already uses this email';
    END IF;

    UPDATE public.users
    SET auth_id = NEW.id,
        full_name = left(COALESCE(NULLIF(btrim(NEW.raw_user_meta_data->>'full_name'), ''), full_name), 100)
    WHERE email = NEW.email;
    RETURN NEW;
  END IF;

  INSERT INTO public.users (auth_id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    left(COALESCE(NULLIF(btrim(NEW.raw_user_meta_data->>'full_name'), ''),
                  split_part(NEW.email, '@', 1)), 100),
    'STUDENT'::public.user_role
  );
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;
COMMIT;
