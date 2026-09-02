import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_model.dart';

/// Provides realistic mock data for Phase 1 (before backend integration).
class MockDataService {
  MockDataService._();

  // ──────────────────── Students ────────────────────

  static final List<StudentModel> students = [
    const StudentModel(id: 's1', name: 'Lithesh Hari R', rollNumber: '25243100', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 3, dueLetters: 1, isPresentToday: true),
    const StudentModel(id: 's2', name: 'Manikandan M', rollNumber: '25243113', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 2, dueLetters: 0, isPresentToday: true),
    const StudentModel(id: 's3', name: 'Janani Y', rollNumber: '25243068', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 5, dueLetters: 2, isPresentToday: false),
    const StudentModel(id: 's4', name: 'Rajavel S', rollNumber: '25243120', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 1, dueLetters: 0, isPresentToday: true),
    const StudentModel(id: 's5', name: 'Priya K', rollNumber: '25243055', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 4, dueLetters: 1, isPresentToday: false),
    const StudentModel(id: 's6', name: 'Arun Kumar V', rollNumber: '25243012', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 0, dueLetters: 0, isPresentToday: true),
    const StudentModel(id: 's7', name: 'Deepa M', rollNumber: '25243033', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 2, dueLetters: 0, isPresentToday: true),
    const StudentModel(id: 's8', name: 'Karthik R', rollNumber: '25243078', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 6, dueLetters: 3, isPresentToday: false),
    const StudentModel(id: 's9', name: 'Lakshmi S', rollNumber: '25243090', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 1, dueLetters: 0, isPresentToday: true),
    const StudentModel(id: 's10', name: 'Naveen P', rollNumber: '25243102', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 3, dueLetters: 1, isPresentToday: false),
    // More students for a realistic 63-student class
    const StudentModel(id: 's11', name: 'Surya T', rollNumber: '25243130', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 0, dueLetters: 0, isPresentToday: true),
    const StudentModel(id: 's12', name: 'Vignesh K', rollNumber: '25243140', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 1, dueLetters: 0, isPresentToday: true),
    const StudentModel(id: 's13', name: 'Anitha R', rollNumber: '25243008', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 2, dueLetters: 1, isPresentToday: true),
    const StudentModel(id: 's14', name: 'Bala Murugan S', rollNumber: '25243015', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 0, dueLetters: 0, isPresentToday: true),
    const StudentModel(id: 's15', name: 'Dhivya G', rollNumber: '25243028', department: 'AI&DS', section: 'B', year: 2, advisorId: 'adv-001', totalLeavesTaken: 3, dueLetters: 0, isPresentToday: true),
  ];

  static int get totalStrength => 63;
  static int get presentToday => 59;
  static int get absentToday => totalStrength - presentToday;
  static double get attendancePercentage => (presentToday / totalStrength) * 100;

  // ──────────────────── Leave Requests ────────────────────

  static final List<LeaveModel> leaveRequests = [
    LeaveModel(
      id: 'l1',
      studentId: 's1',
      studentName: 'Lithesh Hari R',
      studentRollNumber: '25243100',
      leaveDate: DateTime.now().subtract(const Duration(days: 2)),
      leaveType: LeaveType.informed,
      reason: 'Fees not Paid',
      letterSubmitted: true,
      letterStatus: LetterStatus.submitted,
      dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 2)),
      dueDays: 2,
      totalLeavesTaken: 3,
    ),
    LeaveModel(
      id: 'l2',
      studentId: 's2',
      studentName: 'Manikandan M',
      studentRollNumber: '25243113',
      leaveDate: DateTime.now().subtract(const Duration(days: 3)),
      leaveType: LeaveType.informed,
      reason: 'Chicken Pox',
      letterSubmitted: true,
      letterStatus: LetterStatus.approved,
      dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 3)),
      dateReceivedByHod: DateTime.now().subtract(const Duration(days: 2)),
      dateApprovedRejected: DateTime.now().subtract(const Duration(days: 1)),
      dueDays: 0,
      totalLeavesTaken: 2,
      hodRemarks: 'Medical leave approved. Get well soon.',
    ),
    LeaveModel(
      id: 'l3',
      studentId: 's3',
      studentName: 'Janani Y',
      studentRollNumber: '25243068',
      leaveDate: DateTime.now().subtract(const Duration(days: 1)),
      leaveType: LeaveType.informed,
      reason: 'Stomach Pain',
      letterSubmitted: true,
      letterStatus: LetterStatus.submitted,
      dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 1)),
      dueDays: 1,
      totalLeavesTaken: 5,
    ),
    LeaveModel(
      id: 'l4',
      studentId: 's5',
      studentName: 'Priya K',
      studentRollNumber: '25243055',
      leaveDate: DateTime.now(),
      leaveType: LeaveType.uninformed,
      reason: 'Family Emergency',
      letterSubmitted: false,
      letterStatus: LetterStatus.notSubmitted,
      dueDays: 0,
      totalLeavesTaken: 4,
    ),
    LeaveModel(
      id: 'l5',
      studentId: 's8',
      studentName: 'Karthik R',
      studentRollNumber: '25243078',
      leaveDate: DateTime.now().subtract(const Duration(days: 5)),
      leaveType: LeaveType.informed,
      reason: 'Sports Tournament',
      letterSubmitted: true,
      letterStatus: LetterStatus.forwarded,
      dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 5)),
      dateReceivedByHod: DateTime.now().subtract(const Duration(days: 3)),
      advisorRemarks: 'Genuine reason. Representing college in state-level cricket.',
      dueDays: 3,
      totalLeavesTaken: 6,
    ),
    LeaveModel(
      id: 'l6',
      studentId: 's10',
      studentName: 'Naveen P',
      studentRollNumber: '25243102',
      leaveDate: DateTime.now().subtract(const Duration(days: 4)),
      leaveType: LeaveType.uninformed,
      reason: 'Personal Reasons',
      letterSubmitted: true,
      letterStatus: LetterStatus.rejected,
      dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 4)),
      dateReceivedByHod: DateTime.now().subtract(const Duration(days: 3)),
      dateApprovedRejected: DateTime.now().subtract(const Duration(days: 2)),
      hodRemarks: 'Insufficient reason. Too many uninformed leaves.',
      dueDays: 0,
      totalLeavesTaken: 3,
    ),
    LeaveModel(
      id: 'l7',
      studentId: 's13',
      studentName: 'Anitha R',
      studentRollNumber: '25243008',
      leaveDate: DateTime.now().subtract(const Duration(days: 1)),
      leaveType: LeaveType.informed,
      reason: 'Medical Checkup',
      letterSubmitted: true,
      letterStatus: LetterStatus.forwarded,
      dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 1)),
      dateReceivedByHod: DateTime.now(),
      advisorRemarks: 'Regular medical appointment.',
      dueDays: 1,
      totalLeavesTaken: 2,
    ),
  ];

  // ──────────────────── Attendance Records ────────────────────

  static List<AttendanceRecord> generateAttendanceForDate(DateTime date) {
    return students.map((s) {
      return AttendanceRecord(
        id: 'att-${s.id}-${date.toIso8601String()}',
        studentId: s.id,
        date: date,
        isPresent: s.isPresentToday,
        biometricPunchIn: s.isPresentToday
            ? DateTime(date.year, date.month, date.day, 8, 30 + (s.id.hashCode % 30))
            : null,
        biometricPunchOut: s.isPresentToday
            ? DateTime(date.year, date.month, date.day, 16, 0 + (s.id.hashCode % 30))
            : null,
        source: 'biometric',
        createdAt: date,
      );
    }).toList();
  }

  // ──────────────────── Dashboard Stats ────────────────────

  static int get pendingSlips =>
      leaveRequests.where((l) => l.letterStatus == LetterStatus.submitted || l.letterStatus == LetterStatus.forwarded).length;

  static int get returnCheckReady =>
      leaveRequests.where((l) => l.letterStatus == LetterStatus.approved).length;

  static int get pendingHodApprovals =>
      leaveRequests.where((l) => l.letterStatus == LetterStatus.forwarded).length;
}
