ALTER TABLE public.leave_slips
  ADD COLUMN IF NOT EXISTS drive_file_id text,
  ADD COLUMN IF NOT EXISTS drive_file_name text,
  ADD COLUMN IF NOT EXISTS drive_mime_type text,
  ADD COLUMN IF NOT EXISTS drive_web_view_link text,
  ADD COLUMN IF NOT EXISTS drive_uploaded_by uuid,
  ADD COLUMN IF NOT EXISTS drive_uploaded_at timestamptz;

CREATE INDEX IF NOT EXISTS idx_leave_slips_drive_file_id
  ON public.leave_slips (drive_file_id);
