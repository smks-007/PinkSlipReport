-- Seed sample attendance and leave slips into Supabase
-- Target Date: 2026-09-07 and 2026-09-08
INSERT INTO public.daily_attendance (student_id, attendance_date, is_present, in_time, out_time, punch_method)
SELECT 
    student_id, 
    '2026-09-07'::DATE, 
    CASE WHEN (student_id % 15 = 0) THEN FALSE ELSE TRUE END,
    CASE WHEN (student_id % 15 = 0) THEN NULL ELSE '08:45:00'::TIME END,
    CASE WHEN (student_id % 15 = 0) THEN NULL ELSE '16:30:00'::TIME END,
    'BIOMETRIC_FINGERPRINT'::punch_source
FROM public.students
ON CONFLICT (student_id, attendance_date) DO NOTHING;

INSERT INTO public.daily_attendance (student_id, attendance_date, is_present, in_time, out_time, punch_method)
SELECT 
    student_id, 
    '2026-09-08'::DATE, 
    CASE WHEN (student_id % 12 = 0) THEN FALSE ELSE TRUE END,
    CASE WHEN (student_id % 12 = 0) THEN NULL ELSE '08:42:00'::TIME END,
    CASE WHEN (student_id % 12 = 0) THEN NULL ELSE '16:30:00'::TIME END,
    'FACE_DETECTION'::punch_source
FROM public.students
ON CONFLICT (student_id, attendance_date) DO NOTHING;

-- Seed Sample Pink Slips / Leave Applications
INSERT INTO public.leave_slips (student_id, reason, from_date, to_date, is_informed, status, advisor_remarks, hod_remarks) VALUES
(1007, 'Medical Appointment for fever and throat infection.', '2026-09-07', '2026-09-07', TRUE, 'APPROVED', 'Doctor prescription verified and endorsed.', 'Approved by HOD.'),
(1010, 'Attending Inter-College Symposium at PSG Tech (OD).', '2026-09-08', '2026-09-09', TRUE, 'APPROVED', 'Paper presentation participation proof attached.', 'Approved by HOD.'),
(1015, 'Family emergency at hometown.', '2026-09-08', '2026-09-08', TRUE, 'SUBMITTED', 'Parent intimation received via phone.', NULL),
(1020, 'Hackathon participation at IIT Madras (OD).', '2026-09-09', '2026-09-10', TRUE, 'PENDING_HOD', 'Event confirmation verified by Section Advisor.', 'Forwarded for HOD sign-off.')
ON CONFLICT DO NOTHING;
