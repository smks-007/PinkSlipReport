-- Apply before enabling self-registration. Staff provisioning is admin-only.
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

  -- An official roster may already have a student profile before that student
  -- creates their Auth account. Link it only while it is unlinked; never let
  -- public registration claim an existing staff or already-linked profile.
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

  -- Never accept a role from editable Auth metadata.
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
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

COMMIT;
