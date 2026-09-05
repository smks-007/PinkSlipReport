export type UserRole = 'hod1' | 'hod2' | 'advisor' | 'faculty' | 'student';
export type AttendanceStatus = 'present' | 'leave_prior_cl' | 'leave_od' | 'leave_ml' | 'absent_uninformed';
export type LeaveType = 'prior_cl' | 'on_duty_od' | 'medical_ml';
export type LeaveApprovalStatus = 'pending' | 'approved_by_advisor' | 'approved_by_hod' | 'rejected';
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
  yearName: string; // "1st Year", "2nd Year", "3rd Year", "4th Year"
  section: string; // "A" | "B"
  batchCode: string; // "3-CSE-A"
  advisorName: string;
  totalStudents: number;
  avgAttendance: number; // e.g. 84.5%
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
  timeRange: string; // "09:00 - 09:50 AM"
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
  documentProofUrl?: string; // S3 / GCS Mock URL
  documentProofName?: string;
  status: LeaveApprovalStatus;
  appliedAt: string;
  reviewedBy?: string;
  reviewerComments?: string;
  reviewedAt?: string;
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
  
  // Weekly / Period Matrix
  recentAttendance: Record<string, AttendanceStatus[]>; // "2026-08-22": [8 statuses]
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
