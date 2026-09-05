export type UserRole = 'hod1' | 'hod2' | 'advisor' | 'faculty' | 'student';
export type AttendanceStatus = 'present' | 'leave_prior_cl' | 'leave_od' | 'leave_ml' | 'absent_uninformed';
export type LeaveType = 'prior_cl' | 'on_duty_od' | 'medical_ml';
export type LeaveApprovalStatus = 
  | 'pending_advisor'       // Student submitted -> awaiting class advisor review
  | 'forwarded_to_hod'      // Advisor approved -> forwarded to HOD for final signoff
  | 'approved_by_hod'       // HOD approved -> official attendance locked
  | 'rejected_by_advisor'   // Advisor rejected
  | 'rejected_by_hod';      // HOD rejected

export type YearLevel = 1 | 2 | 3 | 4;

export interface User {
  id: string;
  name: string;
  role: UserRole;
  title: string;
  department: string;
  email: string;
  avatar: string;
  phone: string;
}

export interface Batch {
  id: string;
  yearLevel: YearLevel;
  yearName: string; // "2nd Year", "3rd Year", "4th Year"
  section: string; // "A" | "B" | "C" | "D"
  batchCode: string; // "II-AIDS-A", "III-AIDS-A"
  advisorName: string;
  totalStudents: number;
  avgAttendance: number; // e.g. 89.5%
  presentToday: number;
  uninformedToday: number;
  approvedLeavesToday: number;
}

export interface Subject {
  code: string;
  name: string;
  facultyName: string;
  periodsConducted: number;
  credits: number;
}

export interface PeriodSlot {
  periodNumber: number; // 1 to 8
  timeRange: string; // "08:45 - 09:35 AM"
  subjectCode: string;
  subjectName: string;
  facultyName: string;
  isLab?: boolean;
}

export interface DailyAttendanceRecord {
  date: string;
  periodNumber: number;
  subjectCode: string;
  status: AttendanceStatus;
  markedBy: string;
  markedAt: string;
}

export interface LeaveRecord {
  id: string;
  studentId: string;
  studentName: string;
  rollNo: string;
  batchCode: string;
  leaveType: LeaveType;
  startDate: string;
  endDate: string;
  startPeriod: number;
  endPeriod: number;
  totalDays: number;
  reason: string;
  letterText?: string; // Typed words / formal letter written by student
  documentProofUrl?: string; // S3 / GCS Mock URL
  documentProofName?: string; // e.g. "SIH_Letter.pdf"
  status: LeaveApprovalStatus;
  appliedAt: string;
  
  // 2-Tier Workflow Review Trail
  advisorName?: string;
  advisorRemarks?: string;
  advisorReviewedAt?: string;
  
  hodName?: string;
  hodRemarks?: string;
  hodReviewedAt?: string;
  
  parentConsent: boolean;
}

export interface Student {
  id: string;
  regNo: string;
  rollNo: string;
  name: string;
  batchCode: string;
  yearLevel: YearLevel;
  section: string;
  avatar: string;
  parentName: string;
  parentPhone: string;
  parentEmail: string;
  advisorName: string;
  
  // Stats
  totalConductedPeriods: number;
  attendedPeriods: number;
  attendancePercentage: number;
  
  // Breakdown
  priorLeavesCount: number; // CL
  onDutyCount: number;      // OD
  medicalLeavesCount: number; // ML
  uninformedAbsencesCount: number; // Red flags!
  
  // 30-Day Multi-Date Attendance Matrix: "2026-09-02": [8 statuses]
  recentAttendance: Record<string, AttendanceStatus[]>;
  leaveHistory: LeaveRecord[];
  subjectAttendance: {
    subjectCode: string;
    subjectName: string;
    conducted: number;
    attended: number;
    percentage: number;
  }[];
}

export interface FacultyComplianceItem {
  periodNumber: number;
  timeSlot: string;
  batchCode: string;
  subjectCode: string;
  facultyName: string;
  isSubmitted: boolean;
  submittedAt?: string;
  presentCount?: number;
  totalCount?: number;
}

export interface DepartmentSummary {
  totalStrength: number;
  overallAttendancePercentage: number;
  presentTodayCount: number;
  uninformedAbsenteesToday: number;
  approvedLeavesToday: number;
  shortageStudentsCount: number; // < 75%
  activePeriodNumber: number;
}

export interface DayAttendanceSubmission {
  id: string;
  date: string; // YYYY-MM-DD
  batchCode: string;
  status: 'draft' | 'submitted_to_hod' | 'verified_by_hod';
  submittedBy?: string;
  submittedAt?: string;
  verifiedBy?: string;
  verifiedAt?: string;
  remarks?: string;
  presentCount: number;
  absentCount: number;
  odCount: number;
  leavesCount: number;
  totalStrength: number;
  dayPercentage: number;
}

export interface NotificationItem {
  id: string;
  recipientRole: 'advisor' | 'student' | 'hod' | 'all';
  recipientStudentId?: string;
  batchCode?: string;
  title: string;
  message: string;
  type: 'info' | 'success' | 'warning' | 'error';
  createdAt: string;
  read: boolean;
  relatedLeaveId?: string;
}
