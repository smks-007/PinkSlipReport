-- Seed HODs and Staff Advisors into Supabase
INSERT INTO public.users (user_id, email, full_name, role, phone_number, is_active) VALUES
(101, 'manivannan.hod@vsb.ac.in', 'Dr. Manivannan (Ph.D.)', 'HOD', '+91 94430 11001', TRUE),
(102, 'hod.kavitha@vsb.ac.in', 'Dr. Kavitha', 'HOD', '+91 94430 11002', TRUE),
(201, 'advisor.2a@vsb.ac.in', 'Dr. D. Anandhan', 'ADVISOR', '+91 94430 12001', TRUE),
(202, 'advisor.2b@vsb.ac.in', 'Dr. M. Rajendiran', 'ADVISOR', '+91 94430 12002', TRUE),
(203, 'advisor.2c@vsb.ac.in', 'Mr. A. Bharathidasan', 'ADVISOR', '+91 94430 12003', TRUE),
(204, 'advisor.2d@vsb.ac.in', 'Mr. R. Palraj', 'ADVISOR', '+91 94430 12004', TRUE),
(301, 'advisor.3a@vsb.ac.in', 'Ms. C. Vishnupriya', 'ADVISOR', '+91 94430 13001', TRUE),
(302, 'advisor.3b@vsb.ac.in', 'Dr. R. Murugesan', 'ADVISOR', '+91 94430 13002', TRUE),
(303, 'advisor.3c@vsb.ac.in', 'Mrs. B. Bharathi', 'ADVISOR', '+91 94430 13003', TRUE),
(304, 'advisor.3d@vsb.ac.in', 'Mr. Velusamy', 'ADVISOR', '+91 94430 13004', TRUE),
(401, 'advisor.4a@vsb.ac.in', 'Mr. Muthuselvan', 'ADVISOR', '+91 94430 14001', TRUE),
(402, 'advisor.4b@vsb.ac.in', 'Mrs. Nandhinidevi', 'ADVISOR', '+91 94430 14002', TRUE)
ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name;

INSERT INTO public.staff_advisors (staff_id, staff_code, assigned_section, designation, cabin_location) VALUES
(201, 'STF-AIDS-2A', 'II-AIDS-A', 'Associate Professor', 'Cabin A-101'),
(202, 'STF-AIDS-2B', 'II-AIDS-B', 'Associate Professor', 'Cabin A-102'),
(203, 'STF-AIDS-2C', 'II-AIDS-C', 'Assistant Professor', 'Cabin A-103'),
(204, 'STF-AIDS-2D', 'II-AIDS-D', 'Assistant Professor', 'Cabin A-104'),
(301, 'STF-AIDS-3A', 'III-AIDS-A', 'Assistant Professor', 'Cabin B-201'),
(302, 'STF-AIDS-3B', 'III-AIDS-B', 'Associate Professor', 'Cabin B-202'),
(303, 'STF-AIDS-3C', 'III-AIDS-C', 'Assistant Professor', 'Cabin B-203'),
(304, 'STF-AIDS-3D', 'III-AIDS-D', 'Assistant Professor', 'Cabin B-204'),
(401, 'STF-AIDS-4A', 'IV-AIDS-A', 'Assistant Professor', 'Cabin C-301'),
(402, 'STF-AIDS-4B', 'IV-AIDS-B', 'Assistant Professor', 'Cabin C-302')
ON CONFLICT (staff_code) DO UPDATE SET assigned_section = EXCLUDED.assigned_section;
