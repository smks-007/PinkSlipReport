import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_model.dart';
import '../models/promotion_model.dart';
import '../data/student_directory_data.dart';

/// Central Real-Time Database and Telemetry Service for SMART PRO.
/// Provides 2026 Academic Calendar (Sep-Dec), Date-wise Attendance, Two-Tier HOD Approvals,
/// Weekly/Monthly Analytics Graphs, <75% Low Attendance Alerting, Academic Year Progression,
/// and 2-Year Alumni Data Retention with Automated Database Purging.
class MockDataService {
  MockDataService._();

  /// ValueNotifier to signal real-time updates to dashboards
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  static void _notifyUpdate() {
    changeNotifier.value = changeNotifier.value + 1;
  }

  // ──────────────────── Complete Directory (622 Students) ────────────────────

  static final List<StudentModel> _dynamicStudents = List.of(StudentDirectoryData.allStudents);

  /// All active students in the department
  static List<StudentModel> get allStudents => List.unmodifiable(_dynamicStudents.where((s) => !s.isPurged));

  static List<StudentModel> getStudentsBySection(int year, String section) {
    return _dynamicStudents
        .where((s) => s.year == year && s.section == section && !s.isPurged && s.academicStatus != StudentAcademicStatus.graduated)
        .toList();
  }

  static int get totalStrength => allStudents.length;
  
  static int get presentToday {
    int total = 0;
    for (int yr = 2; yr <= 4; yr++) {
      final sections = yr == 4 ? ['A', 'B'] : ['A', 'B', 'C', 'D'];
      for (final sec in sections) {
        total += getSectionPresent(yr, sec, DateTime(2026, 9, 7)) + getSectionOnDuty(yr, sec, DateTime(2026, 9, 7));
      }
    }
    return total;
  }

  static int get absentToday => totalStrength - presentToday;
  static double get attendancePercentage => totalStrength > 0 ? (presentToday / totalStrength) * 100 : 0.0;

  static int getSectionStrength(int year, String section) {
    final list = getStudentsBySection(year, section);
    return list.isNotEmpty ? list.length : 60;
  }

  static int getSectionAbsent(int year, String section, [DateTime? date]) {
    final targetDate = date ?? DateTime(2026, 9, 7);
    final records = getAttendanceForDate(targetDate, year: year, section: section);
    return records.where((r) => r.isAbsent).length;
  }

  static int getSectionPresent(int year, String section, [DateTime? date]) {
    final targetDate = date ?? DateTime(2026, 9, 7);
    final records = getAttendanceForDate(targetDate, year: year, section: section);
    return records.where((r) => r.isPresent).length;
  }

  static int getSectionOnDuty(int year, String section, [DateTime? date]) {
    final targetDate = date ?? DateTime(2026, 9, 7);
    final records = getAttendanceForDate(targetDate, year: year, section: section);
    return records.where((r) => r.isOnDuty).length;
  }

  static double getSectionAttendancePercentage(int year, String section, [DateTime? date]) {
    final str = getSectionStrength(year, section);
    if (str == 0) return 100.0;
    final pres = getSectionPresent(year, section, date);
    final od = getSectionOnDuty(year, section, date);
    // On-Duty (OD) is counted as present for official academic compliance
    return ((pres + od) / str) * 100;
  }

  /// Check whether a student is present today (including On-Duty)
  static bool isStudentPresent(String rollNumber) {
    return !todaysAbsentRollNumbers.contains(rollNumber);
  }

  /// Check whether a student is absent today
  static bool isStudentAbsent(String rollNumber) {
    return todaysAbsentRollNumbers.contains(rollNumber);
  }

  // ──────────────────── Official Today's Absentee Database ────────────────────

  static const Set<String> todaysAbsentRollNumbers = {
    // II Year Section A (6 Absentees)
    '25243006', // AKHIL M
    '25243010', // ARSHAD S
    '25243022', // BHARATH M
    '25243035', // DHARSAN S
    '25243039', // DHARUN K
    '25243041', // DHIVAKAR S

    // II Year Section B (3 Absentees)
    '25243096', // LAKSHAYAA S
    '25243100', // LITHESH HARI R
    '25243128', // MUGESHDHARAN M

    // II Year Section C (60 Absentees - Full Section Absent)
    '25243129', '25243130', '25243131', '25243132', '25243133', '25243134', '25243135', '25243136',
    '25243137', '25243138', '25243139', '25243140', '25243141', '25243142', '25243143', '25243144',
    '25243145', '25243146', '25243147', '25243148', '25243149', '25243150', '25243151', '25243152',
    '25243153', '25243154', '25243155', '25243156', '25243157', '25243158', '25243159', '25243160',
    '25243161', '25243162', '25243163', '25243164', '25243165', '25243166', '25243167', '25243168',
    '25243169', '25243170', '25243171', '25243172', '25243173', '25243174', '25243175', '25243176',
    '25243177', '25243178', '25243179', '25243180', '25243181', '25243182', '25243183', '25243184',
    '25243185', '25243186', '25243187', '25243188',

    // II Year Section D (6 Absentees)
    '25243195', // SANTHOSH RAJ B
    '25243201', // SHANMUGA SUNDARAM B
    '25243211', // SRI HARISHKUMAR T
    '25243226', // TAMILARASAN M
    '25243228', // THAMARAIKKANNAN S
    '25243242', // VIJAY M

    // III Year Section A (1 Absentee)
    '24243302', // SANTHOSH A

    // III Year Section B (6 Absentees)
    '24243079', // KAVIN SHARVESH R
    '24243081', // KAVIYA D
    '24243084', // KAVYA SHREE TV
    '24243095', // LALITHA M
    '24243097', // LOGESH S
    '24243101', // MAHALAKSHMI K

    // III Year Section C (1 Absentee)
    '24243180', // SAKTHI BALAN M

    // III Year Section D (2 Absentees)
    '24243179', // SAKTHI B
    '24243240', // VELAVAN A

    // IV Year Section A (7 Absentees)
    '23243001', // S.AARTHI
    '23243020', // S.ELAMATHI
    '23243024', // V.GOKUL ANAND
    '23243025', // S.GOKUL KRISHNA
    '23243026', // M.GOKUL
    '23243031', // S.HARI KRISHNA
    '23243036', // V.S HARINI

    // IV Year Section B (2 Absentees)
    '23243092', // P. ROOBALAKSHMI
    '23243117', // K. THARANI KUMAR
  };

  // ──────────────────── 2026 Academic Calendar (Sep - Dec) ────────────────────

  /// Academic term calendar months
  static const List<Map<String, dynamic>> academicMonths2026 = [
    {'month': 9, 'year': 2026, 'name': 'September 2026', 'short': 'Sep 26', 'days': 30},
    {'month': 10, 'year': 2026, 'name': 'October 2026', 'short': 'Oct 26', 'days': 31},
    {'month': 11, 'year': 2026, 'name': 'November 2026', 'short': 'Nov 26', 'days': 30},
    {'month': 12, 'year': 2026, 'name': 'December 2026', 'short': 'Dec 26', 'days': 31},
  ];

  /// Get list of working academic dates for a specific month in 2026
  static List<DateTime> getDatesForMonth(int month, {int year = 2026}) {
    final daysInMonth = month == 9 || month == 11 ? 30 : 31;
    final List<DateTime> dates = [];
    for (int d = 1; d <= daysInMonth; d++) {
      final dt = DateTime(year, month, d);
      // Skip Sundays (weekday == 7) for normal instructional days
      if (dt.weekday != DateTime.sunday) {
        dates.add(dt);
      }
    }
    return dates;
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
    final advName = _getAdvisorName(year, section);
    final isToday = (date.year == 2026 && date.month == 9 && date.day == 7) ||
        (date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day);
    final isPastDate = date.isBefore(DateTime(2026, 9, 7, 23, 59));

    final records = targetStudents.asMap().entries.map((entry) {
      final idx = entry.key;
      final s = entry.value;

      AttendanceStatus status;
      String? odReason;

      if (isToday) {
        if (todaysAbsentRollNumbers.contains(s.rollNumber)) {
          status = AttendanceStatus.absent;
        } else {
          // Check if student has active registered OD
          final hasOd = _leaveRequests.any((l) =>
              l.studentRollNumber == s.rollNumber &&
              l.category == LeaveCategory.onDuty &&
              l.leaveDate.day == date.day &&
              l.leaveDate.month == date.month &&
              l.leaveDate.year == date.year);

          if (hasOd) {
            status = AttendanceStatus.onDuty;
            final req = _leaveRequests.firstWhere((l) => l.studentRollNumber == s.rollNumber && l.category == LeaveCategory.onDuty);
            odReason = req.reason;
          } else {
            status = AttendanceStatus.present;
          }
        }
      } else {
        // Realistic pseudo-random distribution for past/future working calendar days
        final hash = (s.id.hashCode + date.day * 7 + date.month * 13).abs();
        if (hash % 29 == 4) {
          status = AttendanceStatus.onDuty;
          odReason = 'Technical Symposium / Sports OD';
        } else if (hash % 19 == 7 || (idx % 22 == 5 && date.day % 3 == 0)) {
          status = AttendanceStatus.absent;
        } else {
          status = AttendanceStatus.present;
        }
      }

      final hash = (s.id.hashCode + date.day * 7 + date.month * 13).abs();

      return AttendanceRecord(
        id: 'att-${s.id}-${date.year}${date.month}${date.day}',
        studentId: s.id,
        date: date,
        status: status,
        biometricPunchIn: status == AttendanceStatus.present
            ? DateTime(date.year, date.month, date.day, 8, 30 + (hash % 18))
            : null,
        biometricPunchOut: status == AttendanceStatus.present
            ? DateTime(date.year, date.month, date.day, 16, 0 + (hash % 30))
            : null,
        source: isToday ? 'live_biometric_sync' : (isPastDate ? 'manual_verified' : 'biometric'),
        recordedBy: advName,
        onDutyReason: status == AttendanceStatus.onDuty ? (odReason ?? 'Official OD') : null,
        createdAt: date,
      );
    }).toList();

    _attendanceCache[key] = records;
    return records;
  }

  static void updateAttendanceRecord(AttendanceRecord updated, {int year = 2, String section = 'B'}) {
    final key = _formatDateKey(updated.date, year, section);
    final list = List<AttendanceRecord>.from(getAttendanceForDate(updated.date, year: year, section: section));
    final idx = list.indexWhere((r) => r.id == updated.id || r.studentId == updated.studentId);
    if (idx != -1) {
      list[idx] = updated;
    } else {
      list.add(updated);
    }
    _attendanceCache[key] = list;
    _notifyUpdate();
  }

  /// Create Pink Slip issued by Class Advisor and synchronize attendance (Mark Present or Absent)
  static LeaveModel createAdvisorPinkSlip({
    required StudentModel student,
    required DateTime date,
    required bool markPresent,
    required LeaveCategory category,
    LeaveType leaveType = LeaveType.informed,
    required String reason,
    required String advisorName,
    String? advisorId,
    String? advisorRemarks,
    String? attachmentFileName,
    String? attachmentFileType,
    String? attachmentFileSize,
    int? year,
    String? section,
  }) {
    final effectiveYear = year ?? student.year;
    final effectiveSection = section ?? student.section;

    final slip = LeaveModel(
      id: 'ps-${DateTime.now().millisecondsSinceEpoch}',
      studentId: student.id,
      studentName: student.name,
      studentRollNumber: student.rollNumber,
      category: category,
      section: effectiveSection,
      year: effectiveYear,
      batchYear: student.batchYear,
      leaveDate: date,
      leaveType: leaveType,
      reason: reason,
      letterSubmitted: true,
      letterStatus: markPresent ? LetterStatus.approved : LetterStatus.forwarded,
      attachmentFileName: attachmentFileName ?? (markPresent ? 'official_od_clearance.pdf' : 'advisor_signed_pink_slip.pdf'),
      attachmentFileType: attachmentFileType ?? (markPresent ? 'On-Duty Clearance Letter' : 'Advisor Issued Pink Slip'),
      attachmentFileSize: attachmentFileSize ?? '1.2 MB',
      dateSubmittedToAdvisor: DateTime.now(),
      advisorId: advisorId,
      advisorRemarks: advisorRemarks ?? 'Official Pink Slip issued by Class Advisor $advisorName. Attendance marked as ${markPresent ? "PRESENT (OD)" : "ABSENT"}.',
      dateReceivedByHod: markPresent ? DateTime.now() : null,
      dateApprovedRejected: markPresent ? DateTime.now() : null,
      hodRemarks: markPresent ? 'Sanctioned via Class Advisor Official OD Pink Slip' : null,
      dueDays: 0,
      totalLeavesTaken: markPresent ? 0 : 1,
    );

    // Save leave/slip to top of requests
    _leaveRequests.insert(0, slip);

    // Synchronize attendance record
    final record = AttendanceRecord(
      id: 'att-${student.id}-${date.year}${date.month}${date.day}',
      studentId: student.id,
      date: date,
      status: markPresent ? AttendanceStatus.present : AttendanceStatus.absent,
      onDutyReason: category == LeaveCategory.onDuty ? reason : null,
      source: markPresent ? 'pink_slip_od' : 'pink_slip_absent',
      recordedBy: '$advisorName (Class Advisor Pink Slip)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      biometricPunchIn: markPresent ? DateTime(date.year, date.month, date.day, 8, 30) : null,
      biometricPunchOut: markPresent ? DateTime(date.year, date.month, date.day, 16, 0) : null,
    );

    updateAttendanceRecord(record, year: effectiveYear, section: effectiveSection);

    return slip;
  }

  static void markAllPresentForDate(DateTime date, {int year = 2, String section = 'B', String recordedBy = 'Class Advisor'}) {
    final key = _formatDateKey(date, year, section);
    final list = getAttendanceForDate(date, year: year, section: section);
    final updatedList = list.map((r) {
      return r.copyWith(
        status: AttendanceStatus.present,
        source: 'manual',
        recordedBy: recordedBy,
        updatedAt: DateTime.now(),
      );
    }).toList();
    _attendanceCache[key] = updatedList;
    _notifyUpdate();
  }

  static void markAllAbsentForDate(DateTime date, {int year = 2, String section = 'B', String recordedBy = 'Class Advisor'}) {
    final key = _formatDateKey(date, year, section);
    final list = getAttendanceForDate(date, year: year, section: section);
    final updatedList = list.map((r) {
      return r.copyWith(
        status: AttendanceStatus.absent,
        source: 'manual',
        recordedBy: recordedBy,
        updatedAt: DateTime.now(),
      );
    }).toList();
    _attendanceCache[key] = updatedList;
    _notifyUpdate();
  }

  // ──────────────────── College Declared Holidays & Calendar Leaves ────────────────────

  static final Map<String, String> _collegeHolidays = {
    '2026-09-04': 'Ganesh Chaturthi (State Holiday)',
    '2026-09-16': 'Milad-un-Nabi (Govt Holiday)',
    '2026-10-02': 'Gandhi Jayanti (National Holiday)',
    '2026-10-19': 'Ayudha Puja (Festival Leave)',
    '2026-10-20': 'Vijayadasami (Festival Holiday)',
    '2026-11-08': 'Diwali Celebration (College Leave)',
  };

  static bool isSunday(DateTime date) => date.weekday == DateTime.sunday;

  static bool isCollegeHoliday(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _collegeHolidays.containsKey(key);
  }

  static String? getCollegeHolidayReason(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _collegeHolidays[key];
  }

  static void declareCollegeHoliday(DateTime date, String reason) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    _collegeHolidays[key] = reason;
    _notifyUpdate();
  }

  static Map<String, String> get allCollegeHolidays => Map.unmodifiable(_collegeHolidays);

  // ──────────────────── Analytics Graphs & Statistics ────────────────────

  /// Get daily attendance % trend for the last 6 working instructional days (Strictly Excludes Sundays, Highlights College Leaves)
  static List<Map<String, dynamic>> getWeeklyTrend(int year, String section) {
    final now = DateTime(2026, 9, 7); // Active Academic Reference Date (Monday)
    final List<Map<String, dynamic>> data = [];

    // Collect 6 working days going backward from now, strictly omitting Sundays
    final List<DateTime> workingDays = [];
    int offset = 0;
    while (workingDays.length < 6) {
      final d = now.subtract(Duration(days: offset));
      if (d.weekday != DateTime.sunday) {
        workingDays.add(d);
      }
      offset++;
    }

    // Sort chronologically (oldest to newest)
    workingDays.sort((a, b) => a.compareTo(b));

    for (final d in workingDays) {
      final isHoliday = isCollegeHoliday(d);
      final holidayReason = getCollegeHolidayReason(d);
      final pct = isHoliday ? 0.0 : getSectionAttendancePercentage(year, section, d);
      final dayName = getDayAbbreviation(d.weekday);

      data.add({
        'date': d,
        'label': '$dayName ${d.day}/${d.month}',
        'dayName': dayName,
        'percentage': double.parse(pct.toStringAsFixed(1)),
        'isHoliday': isHoliday,
        'holidayReason': holidayReason,
        'present': isHoliday ? 0 : getSectionPresent(year, section, d),
        'absent': isHoliday ? 0 : getSectionAbsent(year, section, d),
        'od': isHoliday ? 0 : getSectionOnDuty(year, section, d),
      });
    }
    return data;
  }

  /// Get overall department weekly trend across all 10 sections (Excludes Sundays, Highlights College Leaves)
  static List<Map<String, dynamic>> getOverallDepartmentWeeklyTrend() {
    final now = DateTime(2026, 9, 7);
    final List<Map<String, dynamic>> data = [];

    final List<DateTime> workingDays = [];
    int offset = 0;
    while (workingDays.length < 6) {
      final d = now.subtract(Duration(days: offset));
      if (d.weekday != DateTime.sunday) {
        workingDays.add(d);
      }
      offset++;
    }

    workingDays.sort((a, b) => a.compareTo(b));

    for (final d in workingDays) {
      final isHoliday = isCollegeHoliday(d);
      final holidayReason = getCollegeHolidayReason(d);

      int totalPres = 0;
      int totalOD = 0;
      int totalAbs = 0;

      if (!isHoliday) {
        for (int yr = 2; yr <= 4; yr++) {
          final sections = yr == 4 ? ['A', 'B'] : ['A', 'B', 'C', 'D'];
          for (final sec in sections) {
            totalPres += getSectionPresent(yr, sec, d);
            totalOD += getSectionOnDuty(yr, sec, d);
            totalAbs += getSectionAbsent(yr, sec, d);
          }
        }
      }

      final total = totalPres + totalOD + totalAbs;
      final pct = isHoliday ? 0.0 : (total > 0 ? ((totalPres + totalOD) / total) * 100 : 94.5);
      final dayName = getDayAbbreviation(d.weekday);

      data.add({
        'date': d,
        'label': '$dayName ${d.day}/${d.month}',
        'dayName': dayName,
        'percentage': double.parse(pct.toStringAsFixed(1)),
        'isHoliday': isHoliday,
        'holidayReason': holidayReason,
        'present': totalPres,
        'od': totalOD,
        'absent': totalAbs,
        'total': total,
      });
    }
    return data;
  }

  /// Get monthly attendance progression across 2026 semester months (Sep, Oct, Nov, Dec 2026)
  static List<Map<String, dynamic>> getMonthlyTrend(int year, String section) {
    return [
      {'month': 'Sep 2026', 'percentage': 95.2, 'status': 'Active Month', 'classesHeld': 24},
      {'month': 'Oct 2026', 'percentage': 94.6, 'status': 'Scheduled', 'classesHeld': 25},
      {'month': 'Nov 2026', 'percentage': 96.1, 'status': 'Scheduled', 'classesHeld': 23},
      {'month': 'Dec 2026', 'percentage': 95.8, 'status': 'Revision & Exams', 'classesHeld': 18},
    ];
  }

  /// Overall department monthly progression
  static List<Map<String, dynamic>> getOverallDepartmentMonthlyTrend() {
    return [
      {'month': 'Sep 2026', 'percentage': 94.8, 'target': 95.0, 'totalStudents': 627},
      {'month': 'Oct 2026', 'percentage': 95.3, 'target': 95.0, 'totalStudents': 627},
      {'month': 'Nov 2026', 'percentage': 96.0, 'target': 95.0, 'totalStudents': 627},
      {'month': 'Dec 2026', 'percentage': 95.5, 'target': 95.0, 'totalStudents': 627},
    ];
  }

  // ──────────────────── Low Attendance Defaulter Alerts (< 75%) ────────────────────

  /// Get students with cumulative attendance less than 75% for a section
  static List<Map<String, dynamic>> getDefaultersBySection(int year, String section) {
    final students = getStudentsBySection(year, section);
    final List<Map<String, dynamic>> defaulters = [];

    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      // Realistic simulation: a small subset has low attendance (<75%)
      final hash = (s.rollNumber.hashCode + year * 31 + section.hashCode).abs();
      if (hash % 17 == 3 || (i == 4 && section == 'A') || (i == 13 && section == 'B')) {
        final pct = 68.0 + (hash % 6);
        defaulters.add({
          'student': s,
          'percentage': pct,
          'totalWorkingDays': 30,
          'daysPresent': (30 * (pct / 100)).round(),
          'daysAbsent': 30 - (30 * (pct / 100)).round(),
          'dueSlips': s.dueLetters > 0 ? s.dueLetters : 2,
          'advisorRemarks': 'Parent intimation required. Warning notice issued.',
        });
      }
    }
    return defaulters;
  }

  /// Get all department-wide defaulters (< 75%) for HOD view
  static List<Map<String, dynamic>> getAllDepartmentDefaulters() {
    final List<Map<String, dynamic>> allDefaulters = [];
    for (int yr = 2; yr <= 4; yr++) {
      final sections = yr == 4 ? ['A', 'B'] : ['A', 'B', 'C', 'D'];
      for (final sec in sections) {
        allDefaulters.addAll(getDefaultersBySection(yr, sec));
      }
    }
    return allDefaulters;
  }

  // ──────────────────── Leave & On-Duty (OD) Two-Tier Workflow ────────────────────

  static final List<LeaveModel> _leaveRequests = [
    // 1. II AIDS B: Lithesh Hari R (Leave with Parent Letter)
    LeaveModel(
      id: 'l-001',
      studentId: 'stu_098',
      studentName: 'LITHESH HARI R',
      studentRollNumber: '25243100',
      category: LeaveCategory.leave,
      section: 'B',
      year: 2,
      batchYear: '2025 BATCH',
      leaveDate: DateTime(2026, 9, 5),
      leaveType: LeaveType.informed,
      reason: 'Fees not paid (Family financial settlement discussion)',
      letterSubmitted: true,
      letterStatus: LetterStatus.submitted,
      attachmentFileName: 'guardian_explanation_letter.pdf',
      attachmentFileType: 'Parent Signed Letter',
      attachmentFileSize: '1.4 MB',
      dateSubmittedToAdvisor: DateTime(2026, 9, 5),
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
      leaveDate: DateTime(2026, 9, 4),
      leaveType: LeaveType.informed,
      reason: 'Severe viral fever & throat infection (OPD admission)',
      letterSubmitted: true,
      letterStatus: LetterStatus.approved,
      attachmentFileName: 'medical_fitness_certificate.pdf',
      attachmentFileType: 'Medical Certificate (GH)',
      attachmentFileSize: '2.1 MB',
      dateSubmittedToAdvisor: DateTime(2026, 9, 4),
      dateReceivedByHod: DateTime(2026, 9, 5),
      dateApprovedRejected: DateTime(2026, 9, 6),
      advisorRemarks: 'Medical certificate verified from registered medical officer.',
      hodRemarks: 'Approved by HOD Dr. Manivannan. Medical condonation granted.',
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
      leaveDate: DateTime(2026, 9, 6),
      leaveType: LeaveType.informed,
      reason: 'National Level Technical Symposium & AI Paper Presentation at IIT Madras',
      letterSubmitted: true,
      letterStatus: LetterStatus.forwarded,
      attachmentFileName: 'iit_madras_symposium_invitation.pdf',
      attachmentFileType: 'Official OD Invitation Letter',
      attachmentFileSize: '1.8 MB',
      dateSubmittedToAdvisor: DateTime(2026, 9, 6),
      dateReceivedByHod: DateTime(2026, 9, 7),
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
      leaveDate: DateTime(2026, 9, 3),
      leaveType: LeaveType.informed,
      reason: 'Anna University Zonal Cricket Tournament Championship match',
      letterSubmitted: true,
      letterStatus: LetterStatus.forwarded,
      attachmentFileName: 'sports_board_od_letter.pdf',
      attachmentFileType: 'Physical Education OD Proof',
      attachmentFileSize: '920 KB',
      dateSubmittedToAdvisor: DateTime(2026, 9, 3),
      dateReceivedByHod: DateTime(2026, 9, 6),
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
      leaveDate: DateTime(2026, 9, 7),
      leaveType: LeaveType.informed,
      reason: 'Smart India Hackathon (SIH) 2026 Grand Finale at Bengaluru Nodal Center',
      letterSubmitted: true,
      letterStatus: LetterStatus.forwarded,
      attachmentFileName: 'sih_team_selection_letter.pdf',
      attachmentFileType: 'Govt. OD Endorsement Letter',
      attachmentFileSize: '3.4 MB',
      dateSubmittedToAdvisor: DateTime(2026, 9, 7),
      dateReceivedByHod: DateTime(2026, 9, 7),
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
      leaveDate: DateTime(2026, 9, 6),
      leaveType: LeaveType.informed,
      reason: 'Off-campus recruitment final technical round at Zoho Corporation, Chennai',
      letterSubmitted: true,
      letterStatus: LetterStatus.forwarded,
      attachmentFileName: 'zoho_interview_call_letter.pdf',
      attachmentFileType: 'Placement Office Call Letter',
      attachmentFileSize: '1.1 MB',
      dateSubmittedToAdvisor: DateTime(2026, 9, 6),
      dateReceivedByHod: DateTime(2026, 9, 7),
      advisorRemarks: 'Placement cell verified the call letter. OD recommended.',
      dueDays: 1,
      totalLeavesTaken: 2,
    ),
  ];

  static List<LeaveModel> get leaveRequests => List.unmodifiable(_leaveRequests);

  static List<LeaveModel> getLeavesForSection(int year, String section) {
    return _leaveRequests.where((l) => l.year == year && l.section == section).toList();
  }

  static List<LeaveModel> getPendingForHod({int? year}) {
    return _leaveRequests.where((l) {
      final isPending = l.letterStatus == LetterStatus.forwarded || l.letterStatus == LetterStatus.submitted;
      if (year == null) return isPending;
      return isPending && l.year == year;
    }).toList();
  }

  static void submitLeaveRequest(LeaveModel newLeave) {
    _leaveRequests.insert(0, newLeave);
    _notifyUpdate();
  }

  static bool forwardToHod(String leaveId, {String? advisorRemarks}) {
    final index = _leaveRequests.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final item = _leaveRequests[index];
      _leaveRequests[index] = item.copyWith(
        letterStatus: LetterStatus.forwarded,
        dateReceivedByHod: DateTime.now(),
        advisorRemarks: advisorRemarks ?? item.advisorRemarks ?? 'Endorsed and forwarded to HOD for approval.',
      );
      _notifyUpdate();
      return true;
    }
    return false;
  }

  static bool approveByHod(String leaveId, {String? remarks}) {
    final index = _leaveRequests.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final item = _leaveRequests[index];
      _leaveRequests[index] = item.copyWith(
        letterStatus: LetterStatus.approved,
        dateApprovedRejected: DateTime.now(),
        hodRemarks: remarks ?? 'Approved by Head of Department (AI&DS). Document verified.',
      );
      _notifyUpdate();
      return true;
    }
    return false;
  }

  static bool rejectByAdvisor(String leaveId, {String? remarks}) {
    final index = _leaveRequests.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final item = _leaveRequests[index];
      _leaveRequests[index] = item.copyWith(
        letterStatus: LetterStatus.rejected,
        dateApprovedRejected: DateTime.now(),
        advisorRemarks: remarks ?? 'Returned to student by Class Advisor for correction.',
      );
      _notifyUpdate();
      return true;
    }
    return false;
  }

  static bool rejectByHod(String leaveId, {String? remarks}) {
    final index = _leaveRequests.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final item = _leaveRequests[index];
      _leaveRequests[index] = item.copyWith(
        letterStatus: LetterStatus.rejected,
        dateApprovedRejected: DateTime.now(),
        hodRemarks: remarks ?? 'Rejected by HOD. Insufficient supporting documentation.',
      );
      _notifyUpdate();
      return true;
    }
    return false;
  }

  // ──────────────────── Academic Year Progression & Promotion Engine ────────────────────
  // Rule: 1 Sem = ~3 Months. 1 Year = 2 Sems (Odd & Even).
  // After Even Semester finishes, a 7-10 day transition grace period triggers a Promotion Request
  // sent to Class Advisor & HOD for approval. Once approved: 1st->2nd, 2nd->3rd, 3rd->4th, 4th->Alumni Archive.

  static final List<PromotionRequest> _promotionRequests = [
    // 1. II AIDS A: 2nd Sem completed, 8 days elapsed in grace period -> Pending Advisor Endorsement
    PromotionRequest(
      id: 'prom-001',
      fromYear: 2,
      toYear: 3,
      section: 'A',
      batchYear: '2025 BATCH',
      semesterCompleted: 4,
      semesterEndDate: DateTime(2026, 8, 30),
      graceTransitionDays: 8,
      eligiblePromotionDate: DateTime(2026, 9, 7),
      studentIds: StudentDirectoryData.bySection['2-A']?.map((s) => s.id).toList() ?? [],
      totalStudents: StudentDirectoryData.bySection['2-A']?.length ?? 62,
      status: PromotionApprovalStatus.pendingAdvisorReview,
      advisorName: 'Dr. D. Anandhan',
      advisorRemarks: 'All 62 students have cleared practical assessments and attendance minimum (75%+ average). Ready to forward to HOD.',
      createdAt: DateTime(2026, 8, 30),
    ),

    // 2. III AIDS B: 2nd Sem completed, 9 days elapsed -> Forwarded to HOD for Final Signature
    PromotionRequest(
      id: 'prom-002',
      fromYear: 3,
      toYear: 4,
      section: 'B',
      batchYear: '2024 BATCH',
      semesterCompleted: 6,
      semesterEndDate: DateTime(2026, 8, 28),
      graceTransitionDays: 10,
      eligiblePromotionDate: DateTime(2026, 9, 7),
      studentIds: StudentDirectoryData.bySection['3-B']?.map((s) => s.id).toList() ?? [],
      totalStudents: StudentDirectoryData.bySection['3-B']?.length ?? 62,
      status: PromotionApprovalStatus.forwardedToHod,
      advisorName: 'Dr. R. Murugesan',
      advisorRemarks: 'Verified 6th Semester credits, mini-project submissions, and Anna University exam registrations. Strongly recommended for final year promotion.',
      dateForwardedByAdvisor: DateTime(2026, 9, 6),
      createdAt: DateTime(2026, 8, 28),
    ),

    // 3. IV AIDS A: 8th Sem Completed (Final Year) -> Forwarded to HOD for Graduation & Alumni Archival
    PromotionRequest(
      id: 'prom-003',
      fromYear: 4,
      toYear: 5, // 5 represents Graduation / Alumni Archive
      section: 'A',
      batchYear: '2023 BATCH',
      semesterCompleted: 8,
      semesterEndDate: DateTime(2026, 8, 26),
      graceTransitionDays: 10,
      eligiblePromotionDate: DateTime(2026, 9, 5),
      studentIds: StudentDirectoryData.bySection['4-A']?.map((s) => s.id).toList() ?? [],
      totalStudents: StudentDirectoryData.bySection['4-A']?.length ?? 60,
      status: PromotionApprovalStatus.forwardedToHod,
      advisorName: 'Mr. Muthuselvan',
      advisorRemarks: 'Major project viva-voce completed with Anna University External Examiners. Placement drives concluded. Ready for graduation archival (2-Year data retention rule applies).',
      dateForwardedByAdvisor: DateTime(2026, 9, 5),
      createdAt: DateTime(2026, 8, 26),
    ),
  ];

  static List<PromotionRequest> get promotionRequests => List.unmodifiable(_promotionRequests);

  static List<PromotionRequest> getPendingPromotionsForAdvisor(int year, String section) {
    return _promotionRequests
        .where((p) => p.fromYear == year && p.section == section && p.status == PromotionApprovalStatus.pendingAdvisorReview)
        .toList();
  }

  static List<PromotionRequest> getPendingPromotionsForHod() {
    return _promotionRequests
        .where((p) => p.status == PromotionApprovalStatus.forwardedToHod || p.status == PromotionApprovalStatus.pendingAdvisorReview)
        .toList();
  }

  /// Class Advisor verifies and forwards promotion proposal to HOD
  static bool advisorForwardPromotion(String requestId, {required String advisorName, required String remarks}) {
    final idx = _promotionRequests.indexWhere((p) => p.id == requestId);
    if (idx != -1) {
      final cur = _promotionRequests[idx];
      _promotionRequests[idx] = cur.copyWith(
        status: PromotionApprovalStatus.forwardedToHod,
        advisorName: advisorName,
        advisorRemarks: remarks,
        dateForwardedByAdvisor: DateTime.now(),
      );
      _notifyUpdate();
      return true;
    }
    return false;
  }

  /// HOD approves promotion request -> changes student academic year and updates active database!
  static bool hodApprovePromotion(String requestId, {required String hodName, required String remarks}) {
    final idx = _promotionRequests.indexWhere((p) => p.id == requestId);
    if (idx != -1) {
      final req = _promotionRequests[idx];
      _promotionRequests[idx] = req.copyWith(
        status: PromotionApprovalStatus.approvedByHod,
        hodName: hodName,
        hodRemarks: remarks,
        dateApprovedByHod: DateTime.now(),
      );

      // Execute promotion logic on dynamic students
      for (int i = 0; i < _dynamicStudents.length; i++) {
        final stu = _dynamicStudents[i];
        if (req.studentIds.contains(stu.id) || (stu.year == req.fromYear && stu.section == req.section)) {
          if (req.isGraduation) {
            // 4th Year -> Graduated & transition to Alumni Archive
            final gradDate = DateTime(2026, 6, 15);
            final expiryDate = gradDate.add(const Duration(days: 730)); // 2 years
            _dynamicStudents[i] = stu.copyWith(
              academicStatus: StudentAcademicStatus.graduated,
              year: 5,
              graduationDate: gradDate,
              archivalDate: DateTime.now(),
              scheduledPurgeDate: expiryDate,
              isArchived: true,
            );

            // Add to alumni archive
            _alumniArchive.add(AlumniRetentionRecord(
              studentId: stu.id,
              studentName: stu.name,
              rollNumber: stu.rollNumber,
              section: stu.section,
              batchYear: stu.batchYear,
              graduationDate: gradDate,
              retentionPeriodYears: 2,
              retentionExpiryDate: expiryDate,
              cumulativeAttendance: 94.2,
              totalODsAttended: 3,
            ));
          } else {
            // Year 1->2, 2->3, 3->4
            final nextYear = req.toYear;
            final nextSem = stu.currentSemester + 2;
            _dynamicStudents[i] = stu.copyWith(
              year: nextYear,
              currentSemester: nextSem,
              academicStatus: StudentAcademicStatus.promoted,
            );
          }
        }
      }

      _notifyUpdate();
      return true;
    }
    return false;
  }

  /// HOD rejects promotion
  static bool hodRejectPromotion(String requestId, {required String remarks}) {
    final idx = _promotionRequests.indexWhere((p) => p.id == requestId);
    if (idx != -1) {
      final req = _promotionRequests[idx];
      _promotionRequests[idx] = req.copyWith(
        status: PromotionApprovalStatus.rejected,
        hodRemarks: remarks,
        dateApprovedByHod: DateTime.now(),
      );
      _notifyUpdate();
      return true;
    }
    return false;
  }

  // ──────────────────── 2-Year Alumni Data Retention & Auto-Purge Policy ────────────────────
  // Rule: When 4th Year students graduate, records are archived for a minimum 2-year retention window.
  // After 2 years, student data is automatically purged from the active database.

  static final List<AlumniRetentionRecord> _alumniArchive = [
    // Batch 2020-2024: Graduated June 2024 -> 2-Year window expired (June 2026) -> Auto-purged!
    AlumniRetentionRecord(
      studentId: 'alum_001',
      studentName: 'KAVIN KUMAR S',
      rollNumber: '20243001',
      section: 'A',
      batchYear: '2024 BATCH',
      graduationDate: DateTime(2024, 6, 15),
      retentionPeriodYears: 2,
      retentionExpiryDate: DateTime(2026, 6, 15),
      isPurged: true,
      purgedAt: DateTime(2026, 6, 16),
      purgeAuditLog: 'Auto-Purged: 2-Year statutory data retention window completed on 15-06-2026. Data pruned from active storage in compliance with UGC/AICTE guidelines.',
      cumulativeAttendance: 95.8,
      totalODsAttended: 5,
    ),
    AlumniRetentionRecord(
      studentId: 'alum_002',
      studentName: 'MEENA K',
      rollNumber: '20243002',
      section: 'A',
      batchYear: '2024 BATCH',
      graduationDate: DateTime(2024, 6, 15),
      retentionPeriodYears: 2,
      retentionExpiryDate: DateTime(2026, 6, 15),
      isPurged: true,
      purgedAt: DateTime(2026, 6, 16),
      purgeAuditLog: 'Auto-Purged: 2-Year statutory data retention window completed on 15-06-2026. Student bio & daily attendance purged.',
      cumulativeAttendance: 91.2,
      totalODsAttended: 2,
    ),

    // Batch 2021-2025: Graduated June 2025 -> Expiry June 2027 (Active in 2-year retention window)
    AlumniRetentionRecord(
      studentId: 'alum_101',
      studentName: 'SARAVANAN M',
      rollNumber: '21243015',
      section: 'A',
      batchYear: '2025 BATCH',
      graduationDate: DateTime(2025, 6, 15),
      retentionPeriodYears: 2,
      retentionExpiryDate: DateTime(2027, 6, 15),
      isPurged: false,
      cumulativeAttendance: 93.6,
      totalODsAttended: 4,
    ),
    AlumniRetentionRecord(
      studentId: 'alum_102',
      studentName: 'PRIYA DHARSHINI R',
      rollNumber: '21243016',
      section: 'B',
      batchYear: '2025 BATCH',
      graduationDate: DateTime(2025, 6, 15),
      retentionPeriodYears: 2,
      retentionExpiryDate: DateTime(2027, 6, 15),
      isPurged: false,
      cumulativeAttendance: 96.1,
      totalODsAttended: 6,
    ),

    // Batch 2022-2026: Graduated June 2026 -> Expiry June 2028 (Full 2-year window active)
    AlumniRetentionRecord(
      studentId: 'alum_201',
      studentName: 'VIGNESHWARAN K',
      rollNumber: '22243050',
      section: 'A',
      batchYear: '2026 BATCH',
      graduationDate: DateTime(2026, 6, 15),
      retentionPeriodYears: 2,
      retentionExpiryDate: DateTime(2028, 6, 15),
      isPurged: false,
      cumulativeAttendance: 94.4,
      totalODsAttended: 3,
    ),
    AlumniRetentionRecord(
      studentId: 'alum_202',
      studentName: 'SOWMIYA T',
      rollNumber: '22243051',
      section: 'B',
      batchYear: '2026 BATCH',
      graduationDate: DateTime(2026, 6, 15),
      retentionPeriodYears: 2,
      retentionExpiryDate: DateTime(2028, 6, 15),
      isPurged: false,
      cumulativeAttendance: 92.8,
      totalODsAttended: 5,
    ),
  ];

  static List<AlumniRetentionRecord> get alumniArchiveRecords => List.unmodifiable(_alumniArchive);

  /// Auto-purge trigger: scans all archived alumni records. If retention period (>= 2 years) is exceeded,
  /// automatically purges the student data from the active system and writes to the audit log.
  static int triggerAlumniRetentionPurgeCheck([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime(2026, 9, 7);
    int purgedCount = 0;

    for (int i = 0; i < _alumniArchive.length; i++) {
      final rec = _alumniArchive[i];
      if (!rec.isPurged && rec.isExpired(now)) {
        _alumniArchive[i] = rec.copyWith(
          isPurged: true,
          purgedAt: now,
          purgeAuditLog: 'Auto-Purged on ${now.day}/${now.month}/${now.year}: Exceeded mandatory 2-Year retention window (${rec.retentionExpiryDate.day}/${rec.retentionExpiryDate.month}/${rec.retentionExpiryDate.year}). Successfully purged from active database.',
        );
        purgedCount++;
      }
    }

    if (purgedCount > 0) {
      _notifyUpdate();
    }
    return purgedCount;
  }

  // ──────────────────── Helper Utilities ────────────────────

  static String _getAdvisorName(int year, String section) {
    if (year == 4 && section == 'A') return 'Mr. Muthuselvan';
    if (year == 4 && section == 'B') return 'Mrs. Nandhinidevi';
    if (year == 3 && section == 'A') return 'Ms. C. Vishnupriya';
    if (year == 3 && section == 'B') return 'Dr. R. Murugesan';
    if (year == 3 && section == 'C') return 'Mrs. B. Bharathi';
    if (year == 3 && section == 'D') return 'Mr. Velusamy';
    if (year == 2 && section == 'A') return 'Dr. D. Anandhan';
    if (year == 2 && section == 'B') return 'Dr. M. Rajendiran';
    if (year == 2 && section == 'C') return 'Mr. A. Bharathidasan';
    if (year == 2 && section == 'D') return 'Mr. R. Palraj';
    return 'Class Advisor';
  }

  static String getDayAbbreviation(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Mon';
      case DateTime.tuesday: return 'Tue';
      case DateTime.wednesday: return 'Wed';
      case DateTime.thursday: return 'Thu';
      case DateTime.friday: return 'Fri';
      case DateTime.saturday: return 'Sat';
      case DateTime.sunday: return 'Sun';
      default: return '';
    }
  }

  // ──────────────────── Storage & System Telemetry ────────────────────

  static Map<String, dynamic> getStorageMetrics() {
    final activeAlumni = _alumniArchive.where((a) => !a.isPurged).length;
    final purgedAlumni = _alumniArchive.where((a) => a.isPurged).length;

    return {
      'totalStudents': allStudents.length, // 627
      'totalAdvisors': 10,
      'totalHods': 2,
      'totalSections': 10,
      'totalLeaveSlips': _leaveRequests.length,
      'totalAttendanceRecords': 627 * 30, // 30 days of persistent records
      'activeAlumniUnder2YrRetention': activeAlumni,
      'purgedAlumniRecords': purgedAlumni,
      'storageAllocatedMB': 100.0,
      'storageUsedMB': 34.20,
      'breakdown': [
        {'category': '627 Active Student Bio & Academic Data', 'size': '2.45 MB', 'records': '627 active'},
        {'category': 'Alumni 2-Year Retention Archive Vault', 'size': '1.85 MB', 'records': '$activeAlumni retained, $purgedAlumni auto-purged'},
        {'category': '10 Faculty Advisor & HOD Portals', 'size': '320 KB', 'records': '12 accounts'},
        {'category': 'Sep-Dec 2026 Attendance & Punch Logs', 'size': '6.40 MB', 'records': '18,660 logs'},
        {'category': 'OD & Medical Proof PDF Attachments', 'size': '18.60 MB', 'records': '6 documents'},
        {'category': 'Odd Sem 2026 Timetable Indices', 'size': '1.15 MB', 'records': '10 sections'},
        {'category': 'Smart Pro Jarvis AI Intelligence Engine', 'size': '3.88 MB', 'records': 'Full Index'},
      ],
      'systemHealth': '100% Operational',
      'syncStatus': 'Local Storage Synced with Dept Cloud Server',
      'lastSyncTime': '07-09-2026 01:50 PM',
      'retentionPolicyStatus': '2-Year Alumni Compliance: Active Automated Scheduler',
    };
  }

  static int get pendingSlips =>
      _leaveRequests.where((l) => l.letterStatus == LetterStatus.submitted || l.letterStatus == LetterStatus.forwarded).length;

  static int get pendingHodApprovals =>
      _leaveRequests.where((l) => l.letterStatus == LetterStatus.forwarded).length;

  static int get pendingHodPromotions =>
      _promotionRequests.where((p) => p.status == PromotionApprovalStatus.forwardedToHod || p.status == PromotionApprovalStatus.pendingAdvisorReview).length;
}
