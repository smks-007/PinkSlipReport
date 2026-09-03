import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_model.dart';
import '../data/student_directory_data.dart';

/// Provides realistic mock data and real-time state for the PinkSlipReport system.
class MockDataService {
  MockDataService._();

  // ──────────────────── Complete Directory (622 Students) ────────────────────

  /// All 622 students across all 10 sections
  static List<StudentModel> get allStudents => StudentDirectoryData.allStudents;

  /// Default section students (II AI&DS Sec B) for backwards compatibility
  static List<StudentModel> get students =>
      StudentDirectoryData.bySection['2-B'] ?? StudentDirectoryData.allStudents.take(63).toList();

  static List<StudentModel> getStudentsBySection(int year, String section) {
    return StudentDirectoryData.bySection['$year-$section'] ?? [];
  }

  static int get totalStrength => allStudents.length; // 622
  static int get presentToday => 589;
  static int get absentToday => totalStrength - presentToday;
  static double get attendancePercentage => (presentToday / totalStrength) * 100;

  static int getSectionStrength(int year, String section) {
    final list = getStudentsBySection(year, section);
    return list.isNotEmpty ? list.length : 60;
  }

  static int getSectionAbsent(int year, String section) {
    // Dynamic realistic absentee distribution across 10 sections
    final key = '$year-$section';
    switch (key) {
      case '4-A': return 3;
      case '4-B': return 3;
      case '3-A': return 4;
      case '3-B': return 3;
      case '3-C': return 3;
      case '3-D': return 3;
      case '2-A': return 3;
      case '2-B': return 4;
      case '2-C': return 3;
      case '2-D': return 4;
      default: return 3;
    }
  }

  static int getSectionPresent(int year, String section) {
    final str = getSectionStrength(year, section);
    final abs = getSectionAbsent(year, section);
    return str - abs;
  }

  static double getSectionAttendancePercentage(int year, String section) {
    final str = getSectionStrength(year, section);
    if (str == 0) return 100.0;
    final pres = getSectionPresent(year, section);
    return (pres / str) * 100;
  }

  static int getSectionPendingSlips(int year, String section) {
    final list = _leaveRequests.where((l) => l.year == year && l.section == section && l.letterStatus == LetterStatus.submitted).toList();
    return list.isNotEmpty ? list.length : 1;
  }

  static int getSectionReturnCheck(int year, String section) {
    final list = _leaveRequests.where((l) => l.year == year && l.section == section && l.letterStatus == LetterStatus.approved).toList();
    return list.isNotEmpty ? list.length : 1;
  }

  static List<LeaveModel> getSectionLeaves(int year, String section) {
    final filtered = _leaveRequests.where((l) => l.year == year && l.section == section).toList();
    if (filtered.isNotEmpty) return filtered;
    // Return sample request for this section if empty
    final studentsInSec = getStudentsBySection(year, section);
    final sampleStu = studentsInSec.isNotEmpty ? studentsInSec.first : null;
    return [
      LeaveModel(
        id: 'l-$year$section-sample',
        studentId: sampleStu?.id ?? 'stu_sample',
        studentName: sampleStu?.name ?? 'Sample Student',
        studentRollNumber: sampleStu?.rollNumber ?? '25243001',
        category: LeaveCategory.leave,
        section: section,
        year: year,
        batchYear: sampleStu?.batchYear ?? '2026 BATCH',
        leaveDate: DateTime.now().subtract(const Duration(days: 1)),
        leaveType: LeaveType.informed,
        reason: 'Personal Academic Consultation & Family Leave',
        letterSubmitted: true,
        letterStatus: LetterStatus.submitted,
        attachmentFileName: 'parent_leave_application.pdf',
        attachmentFileType: 'Parent Signed Application',
        attachmentFileSize: '1.2 MB',
        dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 1)),
        advisorRemarks: 'Reviewed by Class Advisor for Section $section.',
        dueDays: 1,
        totalLeavesTaken: 1,
      ),
    ];
  }

  // ──────────────────── Leave & On-Duty (OD) Requests ────────────────────

  static final List<LeaveModel> _leaveRequests = [
    // 1. II AIDS B: Lithesh Hari R (Leave with Parent Letter)
    LeaveModel(
      id: 'l-001',
      studentId: 'stu_098',
      studentName: 'LITHEH HARI R',
      studentRollNumber: '25243100',
      category: LeaveCategory.leave,
      section: 'B',
      year: 2,
      batchYear: '2025 BATCH',
      leaveDate: DateTime.now().subtract(const Duration(days: 2)),
      leaveType: LeaveType.informed,
      reason: 'Fees not paid (Family financial settlement discussion)',
      letterSubmitted: true,
      letterStatus: LetterStatus.submitted,
      attachmentFileName: 'guardian_explanation_letter.pdf',
      attachmentFileType: 'Parent Signed Letter',
      attachmentFileSize: '1.4 MB',
      dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 2)),
      advisorRemarks: 'Parent met advisor in person. Genuine delay requested.',
      dueDays: 2,
      totalLeavesTaken: 3,
    ),

    // 2. II AIDS B: Manikandan M (Medical Leave with Hospital Certificate - Approved)
    LeaveModel(
      id: 'l-002',
      studentId: 'stu_111',
      studentName: 'MANIKANDAN M',
      studentRollNumber: '25243113',
      category: LeaveCategory.leave,
      section: 'B',
      year: 2,
      batchYear: '2025 BATCH',
      leaveDate: DateTime.now().subtract(const Duration(days: 3)),
      leaveType: LeaveType.informed,
      reason: 'Severe viral fever & throat infection',
      letterSubmitted: true,
      letterStatus: LetterStatus.approved,
      attachmentFileName: 'medical_fitness_certificate.pdf',
      attachmentFileType: 'Medical Certificate (GH)',
      attachmentFileSize: '2.1 MB',
      dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 3)),
      dateReceivedByHod: DateTime.now().subtract(const Duration(days: 2)),
      dateApprovedRejected: DateTime.now().subtract(const Duration(days: 1)),
      advisorRemarks: 'Medical certificate verified from registered medical officer.',
      hodRemarks: 'Approved by HOD. Medical condonation granted.',
      dueDays: 0,
      totalLeavesTaken: 2,
    ),

    // 3. II AIDS B: Janani Y (On-Duty OD - Symposium at IIT Madras)
    LeaveModel(
      id: 'l-003',
      studentId: 'stu_067',
      studentName: 'JANANI Y',
      studentRollNumber: '25243068',
      category: LeaveCategory.onDuty,
      section: 'B',
      year: 2,
      batchYear: '2025 BATCH',
      leaveDate: DateTime.now().subtract(const Duration(days: 1)),
      leaveType: LeaveType.informed,
      reason: 'National Level Technical Symposium & AI Paper Presentation at IIT Madras',
      letterSubmitted: true,
      letterStatus: LetterStatus.forwarded,
      attachmentFileName: 'iit_madras_symposium_invitation.pdf',
      attachmentFileType: 'Official OD Invitation Letter',
      attachmentFileSize: '1.8 MB',
      dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 1)),
      dateReceivedByHod: DateTime.now(),
      advisorRemarks: 'Selected for final round paper presentation. Highly recommended for OD.',
      dueDays: 1,
      totalLeavesTaken: 1,
    ),

    // 4. II AIDS A: Adithyan S (On-Duty OD - State Level Cricket Tournament)
    LeaveModel(
      id: 'l-004',
      studentId: 'stu_002',
      studentName: 'ADITHYAN S',
      studentRollNumber: '25243002',
      category: LeaveCategory.onDuty,
      section: 'A',
      year: 2,
      batchYear: '2025 BATCH',
      leaveDate: DateTime.now().subtract(const Duration(days: 4)),
      leaveType: LeaveType.informed,
      reason: 'Anna University Zonal Cricket Tournament Championship match',
      letterSubmitted: true,
      letterStatus: LetterStatus.forwarded,
      attachmentFileName: 'sports_board_od_letter.pdf',
      attachmentFileType: 'Physical Education OD Proof',
      attachmentFileSize: '920 KB',
      dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 4)),
      dateReceivedByHod: DateTime.now().subtract(const Duration(days: 1)),
      advisorRemarks: 'Endorsed by College Physical Director. Regularize under sports quota.',
      dueDays: 0,
      totalLeavesTaken: 2,
    ),

    // 5. III AIDS A: Akash I (On-Duty OD - Smart India Hackathon)
    LeaveModel(
      id: 'l-005',
      studentId: 'stu_256',
      studentName: 'AKASH I',
      studentRollNumber: '24243007',
      category: LeaveCategory.onDuty,
      section: 'A',
      year: 3,
      batchYear: '2024 BATCH',
      leaveDate: DateTime.now(),
      leaveType: LeaveType.informed,
      reason: 'Smart India Hackathon (SIH) 2026 Grand Finale at Bengaluru Nodal Center',
      letterSubmitted: true,
      letterStatus: LetterStatus.submitted,
      attachmentFileName: 'sih_team_selection_letter.pdf',
      attachmentFileType: 'Govt. OD Endorsement Letter',
      attachmentFileSize: '3.4 MB',
      dateSubmittedToAdvisor: DateTime.now(),
      advisorRemarks: 'Lead shortlisted finalist for SIH hardware-software category.',
      dueDays: 0,
      totalLeavesTaken: 1,
    ),

    // 6. IV AIDS B: S. Harini (Placement Drive On-Duty OD)
    LeaveModel(
      id: 'l-006',
      studentId: 'stu_558',
      studentName: 'S. HARINI',
      studentRollNumber: '23243034',
      category: LeaveCategory.onDuty,
      section: 'B',
      year: 4,
      batchYear: '2023 BATCH',
      leaveDate: DateTime.now().subtract(const Duration(days: 1)),
      leaveType: LeaveType.informed,
      reason: 'Off-campus recruitment final technical round at Zoho Corporation, Chennai',
      letterSubmitted: true,
      letterStatus: LetterStatus.forwarded,
      attachmentFileName: 'zoho_interview_call_letter.pdf',
      attachmentFileType: 'Placement Office Call Letter',
      attachmentFileSize: '1.1 MB',
      dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 1)),
      dateReceivedByHod: DateTime.now(),
      advisorRemarks: 'Placement cell verified the call letter. OD recommended.',
      dueDays: 1,
      totalLeavesTaken: 2,
    ),

    // 7. II AIDS C: Muhil Raja A (Uninformed Leave Regularization with Medical Proof)
    LeaveModel(
      id: 'l-007',
      studentId: 'stu_127',
      studentName: 'MUHIL RAJA A',
      studentRollNumber: '25243129',
      category: LeaveCategory.leave,
      section: 'C',
      year: 2,
      batchYear: '2025 BATCH',
      leaveDate: DateTime.now().subtract(const Duration(days: 5)),
      leaveType: LeaveType.uninformed,
      reason: 'Acute Gastroenteritis OPD treatment',
      letterSubmitted: true,
      letterStatus: LetterStatus.approved,
      attachmentFileName: 'clinic_prescription_bill.pdf',
      attachmentFileType: 'Medical Prescription & Bill',
      attachmentFileSize: '850 KB',
      dateSubmittedToAdvisor: DateTime.now().subtract(const Duration(days: 4)),
      dateReceivedByHod: DateTime.now().subtract(const Duration(days: 3)),
      dateApprovedRejected: DateTime.now().subtract(const Duration(days: 2)),
      advisorRemarks: 'Student submitted medical certificate upon returning.',
      hodRemarks: 'Absence regularized. Advised to inform prior next time.',
      dueDays: 0,
      totalLeavesTaken: 2,
    ),

    // 8. III AIDS B: Kabeesh L (Leave without letter - Pending)
    LeaveModel(
      id: 'l-008',
      studentId: 'stu_315',
      studentName: 'KABEESH L',
      studentRollNumber: '24243064',
      category: LeaveCategory.leave,
      section: 'B',
      year: 3,
      batchYear: '2024 BATCH',
      leaveDate: DateTime.now().subtract(const Duration(days: 2)),
      leaveType: LeaveType.uninformed,
      reason: 'Native town temple festival function',
      letterSubmitted: false,
      letterStatus: LetterStatus.notSubmitted,
      dueDays: 2,
      totalLeavesTaken: 3,
    ),
  ];

  static List<LeaveModel> get leaveRequests => List.unmodifiable(_leaveRequests);

  /// Filter leaves by section and year
  static List<LeaveModel> getLeavesForSection(int year, String section) {
    return _leaveRequests.where((l) => l.year == year && l.section == section).toList();
  }

  /// Get pending slips awaiting HOD action
  static List<LeaveModel> getPendingForHod({int? year}) {
    return _leaveRequests.where((l) {
      final isPending = l.letterStatus == LetterStatus.forwarded || l.letterStatus == LetterStatus.submitted;
      if (year == null) return isPending;
      return isPending && l.year == year;
    }).toList();
  }

  /// Submit a new Leave or On-Duty Request (used by Students & Class Representatives)
  static void submitLeaveRequest(LeaveModel newLeave) {
    _leaveRequests.insert(0, newLeave);
  }

  /// Forward request from Advisor to HOD
  static bool forwardToHod(String leaveId, {String? advisorRemarks}) {
    final index = _leaveRequests.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final item = _leaveRequests[index];
      _leaveRequests[index] = item.copyWith(
        letterStatus: LetterStatus.forwarded,
        dateReceivedByHod: DateTime.now(),
        advisorRemarks: advisorRemarks ?? item.advisorRemarks ?? 'Endorsed and forwarded to HOD for approval.',
      );
      return true;
    }
    return false;
  }

  /// HOD Approval
  static bool approveByHod(String leaveId, {String? remarks}) {
    final index = _leaveRequests.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final item = _leaveRequests[index];
      _leaveRequests[index] = item.copyWith(
        letterStatus: LetterStatus.approved,
        dateApprovedRejected: DateTime.now(),
        hodRemarks: remarks ?? 'Approved by Head of Department (AI&DS). Document verified.',
      );
      return true;
    }
    return false;
  }

  /// HOD Rejection
  static bool rejectByHod(String leaveId, {String? remarks}) {
    final index = _leaveRequests.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final item = _leaveRequests[index];
      _leaveRequests[index] = item.copyWith(
        letterStatus: LetterStatus.rejected,
        dateApprovedRejected: DateTime.now(),
        hodRemarks: remarks ?? 'Rejected by HOD. Insufficient supporting documentation.',
      );
      return true;
    }
    return false;
  }

  // ──────────────────── Multi-Day Persistent Attendance Storage ────────────────────

  static final Map<String, List<AttendanceRecord>> _attendanceCache = {};

  static String _formatDateKey(DateTime date, int year, String section) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_${year}_$section';
  }

  static List<AttendanceRecord> getAttendanceForDate(DateTime date, {int year = 2, String section = 'B'}) {
    final key = _formatDateKey(date, year, section);
    if (_attendanceCache.containsKey(key)) {
      return _attendanceCache[key]!;
    }

    // Generate initial records for this section and date
    final targetStudents = getStudentsBySection(year, section);
    // Realistic section advisor name
    final advName = (year == 4 && section == 'A')
        ? 'Mr. Muthuselvan'
        : (year == 4 && section == 'B')
            ? 'Mrs. Nandhinidevi'
            : (year == 3 && section == 'A')
                ? 'Ms. C. Vishnupriya'
                : (year == 3 && section == 'B')
                    ? 'Dr. R. Murugesan'
                    : (year == 3 && section == 'C')
                        ? 'Mrs. B. Bharathi'
                        : (year == 3 && section == 'D')
                            ? 'Mr. Velusamy'
                            : (year == 2 && section == 'A')
                                ? 'Dr. D. Anandhan'
                                : (year == 2 && section == 'B')
                                    ? 'Dr. M. Rajendiran'
                                    : (year == 2 && section == 'C')
                                        ? 'Mr. A. Bharathidasan'
                                        : (year == 2 && section == 'D')
                                            ? 'Mr. R. Palraj'
                                            : 'Class Advisor';
    final isPastDate = date.isBefore(DateTime.now().subtract(const Duration(hours: 12)));

    final records = targetStudents.asMap().entries.map((entry) {
      final idx = entry.key;
      final s = entry.value;
      // Realistic attendance: 92-96% presence
      final isAbsent = (idx % 18 == 4 || idx % 27 == 11);
      final isPresent = !isAbsent;

      return AttendanceRecord(
        id: 'att-${s.id}-${date.year}${date.month}${date.day}',
        studentId: s.id,
        date: date,
        isPresent: isPresent,
        biometricPunchIn: isPresent
            ? DateTime(date.year, date.month, date.day, 8, 30 + (s.id.hashCode % 20).abs())
            : null,
        biometricPunchOut: isPresent
            ? DateTime(date.year, date.month, date.day, 16, 0 + (s.id.hashCode % 30).abs())
            : null,
        source: isPastDate ? 'manual_verified' : 'biometric',
        recordedBy: advName,
        createdAt: date,
      );
    }).toList();

    _attendanceCache[key] = records;
    return records;
  }

  static void updateAttendanceRecord(AttendanceRecord updated, {int year = 2, String section = 'B'}) {
    final key = _formatDateKey(updated.date, year, section);
    final list = getAttendanceForDate(updated.date, year: year, section: section);
    final idx = list.indexWhere((r) => r.id == updated.id || r.studentId == updated.studentId);
    if (idx != -1) {
      list[idx] = updated;
      _attendanceCache[key] = list;
    }
  }

  static void markAllPresentForDate(DateTime date, {int year = 2, String section = 'B', String recordedBy = 'Class Advisor'}) {
    final key = _formatDateKey(date, year, section);
    final list = getAttendanceForDate(date, year: year, section: section);
    final updatedList = list.map((r) {
      return r.copyWith(
        isPresent: true,
        source: 'manual',
        recordedBy: recordedBy,
        updatedAt: DateTime.now(),
      );
    }).toList();
    _attendanceCache[key] = updatedList;
  }

  static List<AttendanceRecord> generateAttendanceForDate(DateTime date, {int? year, String? section}) {
    return getAttendanceForDate(date, year: year ?? 2, section: section ?? 'B');
  }

  // ──────────────────── Storage & System Metrics ────────────────────

  static Map<String, dynamic> getStorageMetrics() {
    return {
      'totalStudents': allStudents.length, // 622
      'totalAdvisors': 10,
      'totalHods': 2,
      'totalClassReps': 20,
      'totalSections': 10,
      'totalLeaveSlips': _leaveRequests.length,
      'totalAttendanceRecords': 622 * 14, // 14 days of loaded attendance
      'storageAllocatedMB': 100.0,
      'storageUsedMB': 31.45,
      'breakdown': [
        {'category': '622 Student Profiles & Bio Data', 'size': '2.45 MB', 'records': '622 rows'},
        {'category': '10 Faculty Advisor & HOD Portals', 'size': '320 KB', 'records': '12 accounts'},
        {'category': 'Multi-Day Attendance & Punch Logs', 'size': '5.80 MB', 'records': '8,708 logs'},
        {'category': 'OD & Medical Proof PDF Attachments', 'size': '18.60 MB', 'records': '8 documents'},
        {'category': 'Odd Sem 2026 Timetable Indices', 'size': '1.15 MB', 'records': '10 sections'},
        {'category': 'HOD Jarvis AI Intelligence Engine', 'size': '3.13 MB', 'records': 'Full Index'},
      ],
      'systemHealth': '100% Operational',
      'syncStatus': 'Local Storage Synced with Dept Cloud Server',
      'lastSyncTime': '03-09-2026 10:25 AM',
    };
  }

  // ──────────────────── Dashboard Stats ────────────────────

  static int get pendingSlips =>
      _leaveRequests.where((l) => l.letterStatus == LetterStatus.submitted || l.letterStatus == LetterStatus.forwarded).length;

  static int get returnCheckReady =>
      _leaveRequests.where((l) => l.letterStatus == LetterStatus.approved).length;

  static int get pendingHodApprovals =>
      _leaveRequests.where((l) => l.letterStatus == LetterStatus.forwarded).length;
}
