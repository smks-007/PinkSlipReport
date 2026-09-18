-- ============================================================================
-- Migration: 20260910170000_advisor_pink_slip_insert_policy.sql
-- Description: Grant Class Advisors explicit INSERT permissions on leave_slips
--              table so issued Pink Slips persist to Supabase Cloud Database.
-- ============================================================================

-- 1. Ensure RLS is active
ALTER TABLE IF EXISTS public.leave_slips ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policy if present
DROP POLICY IF EXISTS "advisor_insert_section_slips" ON public.leave_slips;

-- 3. Create Advisor INSERT Policy
CREATE POLICY "advisor_insert_section_slips" ON public.leave_slips FOR INSERT TO authenticated
  WITH CHECK (
    get_user_role() = 'ADVISOR' AND student_id IN (
      SELECT student_id FROM public.students WHERE section_id = get_advisor_section()
    )
  );

-- 4. Ensure HOD can insert and manage all slips
DROP POLICY IF EXISTS "hod_all_slips" ON public.leave_slips;
CREATE POLICY "hod_all_slips" ON public.leave_slips FOR ALL TO authenticated
  USING (get_user_role() = 'HOD') WITH CHECK (get_user_role() = 'HOD');

-- 5. Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
