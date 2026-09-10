-- ═══════════════════════════════════════════════════════════════════
-- Migration: Department Broadcast Notices Table
-- Date: 2026-09-10
-- Description: Stores HOD broadcast notices, priority alerts, and circulars
--              sent to section advisors, students, and class reps.
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS broadcast_notices (
    notice_id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    target_audience VARCHAR(100) NOT NULL,
    priority VARCHAR(50) NOT NULL DEFAULT 'Normal',
    template_type VARCHAR(50) DEFAULT 'Others',
    sender_name VARCHAR(100) DEFAULT 'HOD Dr. K. Manivannan',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed initial broadcast notice
INSERT INTO broadcast_notices (title, message, target_audience, priority, template_type, sender_name) VALUES
('Urgent: Department Attendance & IA Review', 'All Section Advisors and Class Representatives are requested to verify today''s attendance muster rolls and submit defaulter lists to the HOD office by 4:00 PM.', 'All Section Advisors (10 Faculty)', 'High Priority', 'Attendance Defaulters', 'HOD Dr. K. Manivannan')
ON CONFLICT DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_broadcast_created ON broadcast_notices(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_broadcast_priority ON broadcast_notices(priority);
