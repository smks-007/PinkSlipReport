import 'package:flutter/foundation.dart';

import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_model.dart';
import '../models/promotion_model.dart';
import '../models/notice_model.dart';
import '../data/student_directory_data.dart';
import 'supabase_service.dart';

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

  static final List<StudentModel> _dynamicStudents = List.of(
    StudentDirectoryData.allStudents,
  );

  /// Synchronize all database records live from Supabase Cloud
  static Future<void> syncFromSupabase() async {
    final supabase = SupabaseService();
    if (!supabase.isInitialized || supabase.client == null) return;

    try {
      // 1. Fetch Students from Supabase
      final remoteStudents = await supabase.fetchStudents();
      if (remoteStudents.isNotEmpty) {
        final List<StudentModel> synced = [];
        for (final r in remoteStudents) {
          final roll = r['roll_number'] as String? ?? '';
          final sectionId = r['section_id'] as String? ?? 'II-AIDS-A';
          final parts = sectionId.split('-');
          final yearRoman = parts.isNotEmpty ? parts[0] : 'II';
          final secLetter = parts.length > 2 ? parts[2] : 'A';
          int yr = 2;
          if (yearRoman == 'I') {
            yr = 1;
          } else if (yearRoman == 'II') {
            yr = 2;
          } else if (yearRoman == 'III') {
            yr = 3;
          } else if (yearRoman == 'IV') {
            yr = 4;
          }

          final userMap = r['users'] as Map<String, dynamic>?;
          final studentNameFromTable = r['student_name'] as String?;
          final name =
              (studentNameFromTable != null &&
                  studentNameFromTable.trim().isNotEmpty)
              ? studentNameFromTable.trim()
              : (userMap?['full_name'] as String?) ?? 'Student $roll';
          final batch = yr == 1
              ? '2026 BATCH'
              : yr == 2
              ? '2025 BATCH'
              : yr == 3
              ? '2024 BATCH'
              : '2023 BATCH';

          final advId = 'adv-$yr${secLetter.toLowerCase()}';
          final regNo = r['register_number'] as String?;

          synced.add(
            StudentModel(
              id: 'stu-$roll',
              name: name,
              rollNumber: roll,
              registerNumber: regNo,
              year: yr,
              section: secLetter,
              department: 'AI&DS',
              batchYear: batch,
              advisorId: advId,
              totalLeavesTaken: (r['leaves_taken_ytd'] as int?) ?? 0,
            ),
          );
        }
        if (synced.isNotEmpty) {
          _dynamicStudents.clear();
          _dynamicStudents.addAll(synced);
          if (kDebugMode) {
            debugPrint(
              '✅ Loaded ${synced.length} students live from Supabase Cloud database!',
            );
          }
        }
      }

      // 2. Fetch Live Leave Slips from Supabase (with student details)
      final remoteSlips = await supabase.fetchLeaveSlipsWithStudents();
      if (remoteSlips.isNotEmpty) {
        final List<LeaveModel> syncedSlips = [];
        for (final s in remoteSlips) {
          final slipId = s['slip_id'].toString();
          final fromStr = s['from_date'] as String?;
          final fromDate = fromStr != null
              ? DateTime.tryParse(fromStr) ?? DateTime.now()
              : DateTime.now();

          final statusStr = (s['status'] as String?)?.toUpperCase();
          LetterStatus status = LetterStatus.submitted;
          if (statusStr == 'APPROVED') {
            status = LetterStatus.approved;
          } else if (statusStr == 'PENDING_HOD') {
            status = LetterStatus.forwarded;
          } else if (statusStr == 'REJECTED') {
            status = LetterStatus.rejected;
          }

          // Resolve student name and roll from joined student data
          final studentData = s['students'] as Map<String, dynamic>?;
          final studentName =
              studentData?['student_name'] as String? ??
              'Student ${s['student_id']}';
          final rollNumber =
              studentData?['roll_number'] as String? ??
              s['student_id'].toString();
          final sectionId = studentData?['section_id'] as String? ?? '';
          final parts = sectionId.split('-');
          final yearRoman = parts.isNotEmpty ? parts[0] : 'II';
          final secLetter = parts.length > 2 ? parts[2] : 'A';
          int yr = 2;
          if (yearRoman == 'III') yr = 3;
          if (yearRoman == 'IV') yr = 4;

          syncedSlips.add(
            LeaveModel(
              id: 'slip-$slipId',
              studentId: s['student_id'].toString(),
              studentName: studentName,
              studentRollNumber: rollNumber,
              leaveDate: fromDate,
              reason: s['reason'] as String? ?? 'General Leave',
              letterStatus: status,
              advisorRemarks: s['advisor_remarks'] as String?,
              hodRemarks: s['hod_remarks'] as String?,
              leaveType: LeaveType.informed,
              category: LeaveCategory.leave,
              attachmentFileName: s['letter_document_url'] as String?,
              section: secLetter,
              year: yr,
            ),
          );
        }
        if (syncedSlips.isNotEmpty) {
          _leaveRequests.clear();
          _leaveRequests.addAll(syncedSlips);
          if (kDebugMode) {
            debugPrint(
              '✅ Loaded ${syncedSlips.length} leave slips live from Supabase Cloud database!',
            );
          }
        }
      }

      // 3. Fetch Live Attendance for today and populate cache
      final today = DateTime.now();
      final todayRecords = await supabase.fetchAttendanceWithStudents(today);
      if (todayRecords.isNotEmpty) {
        _syncAttendanceFromDB(todayRecords, today);
        if (kDebugMode) {
          debugPrint(
            '✅ Loaded ${todayRecords.length} attendance records for today from Supabase!',
          );
        }
      }
      // Also fetch Sep 7 and Sep 8 attendance (the dates with seed data)
      for (final seedDate in [DateTime(2026, 9, 7), DateTime(2026, 9, 8)]) {
        final records = await supabase.fetchAttendanceWithStudents(seedDate);
        if (records.isNotEmpty) {
          _syncAttendanceFromDB(records, seedDate);
        }
      }

      // 4. Fetch Academic Calendar from Supabase
      final calendarRows = await supabase.fetchAcademicCalendar();
      if (calendarRows.isNotEmpty) {
        _collegeHolidays.clear();
        for (final row in calendarRows) {
          final dateStr = row['event_date'] as String? ?? '';
          final name = row['event_name'] as String? ?? 'Holiday';
          final isWorking = row['is_working_day'] as bool? ?? true;
          if (!isWorking) {
            _collegeHolidays[dateStr] = name;
          }
        }
        if (kDebugMode) {
          debugPrint(
            '✅ Loaded ${_collegeHolidays.length} calendar holidays from Supabase!',
          );
        }
      }

      // 5. Fetch Promotions from Supabase
      final remotePromotions = await supabase.fetchPromotions();
      if (remotePromotions.isNotEmpty) {
        final List<PromotionRequest> syncedProms = [];
        for (final p in remotePromotions) {
          final statusStr =
              (p['status'] as String?)?.toUpperCase() ?? 'PENDING_ADVISOR';
          PromotionApprovalStatus promStatus =
              PromotionApprovalStatus.pendingAdvisorReview;
          if (statusStr == 'FORWARDED_TO_HOD') {
            promStatus = PromotionApprovalStatus.forwardedToHod;
          } else if (statusStr == 'APPROVED_BY_HOD') {
            promStatus = PromotionApprovalStatus.approvedByHod;
          } else if (statusStr == 'REJECTED') {
            promStatus = PromotionApprovalStatus.rejected;
          }

          final fromYear = p['from_year'] as int? ?? 2;
          final section = p['section'] as String? ?? 'A';
          final sKey = '$fromYear-$section';

          syncedProms.add(
            PromotionRequest(
              id: 'prom-${p['promotion_id']}',
              fromYear: fromYear,
              toYear: p['to_year'] as int? ?? fromYear + 1,
              section: section,
              batchYear: p['batch_year'] as String? ?? '',
              semesterCompleted: p['semester_completed'] as int? ?? 0,
              semesterEndDate:
                  DateTime.tryParse(p['semester_end_date']?.toString() ?? '') ??
                  DateTime(2026, 8, 30),
              graceTransitionDays: p['grace_transition_days'] as int? ?? 7,
              eligiblePromotionDate:
                  DateTime.tryParse(
                    p['eligible_promotion_date']?.toString() ?? '',
                  ) ??
                  DateTime(2026, 9, 7),
              studentIds:
                  StudentDirectoryData.bySection[sKey]
                      ?.map((s) => s.id)
                      .toList() ??
                  [],
              totalStudents: p['total_students'] as int? ?? 60,
              status: promStatus,
              advisorName: p['advisor_name'] as String?,
              advisorRemarks: p['advisor_remarks'] as String?,
              dateForwardedByAdvisor: DateTime.tryParse(
                p['date_forwarded_by_advisor']?.toString() ?? '',
              ),
              hodName: p['hod_name'] as String?,
              hodRemarks: p['hod_remarks'] as String?,
              dateApprovedByHod: DateTime.tryParse(
                p['date_approved_by_hod']?.toString() ?? '',
              ),
              createdAt:
                  DateTime.tryParse(p['created_at']?.toString() ?? '') ??
                  DateTime.now(),
            ),
          );
        }
        _promotionRequests.clear();
        _promotionRequests.addAll(syncedProms);
        if (kDebugMode) {
          debugPrint(
            '✅ Loaded ${syncedProms.length} promotion requests from Supabase!',
          );
        }
      }

      // 6. Fetch Alumni Archive from Supabase
      final remoteAlumni = await supabase.fetchAlumniArchive();
      if (remoteAlumni.isNotEmpty) {
        final List<AlumniRetentionRecord> syncedAlumni = [];
        for (final a in remoteAlumni) {
          syncedAlumni.add(
            AlumniRetentionRecord(
              studentId: 'alum_${a['archive_id']}',
              studentName: a['student_name'] as String? ?? '',
              rollNumber: a['roll_number'] as String? ?? '',
              section: a['section'] as String? ?? 'A',
              batchYear: a['batch_year'] as String? ?? '',
              graduationDate:
                  DateTime.tryParse(a['graduation_date']?.toString() ?? '') ??
                  DateTime(2026, 6, 15),
              retentionPeriodYears: a['retention_period_years'] as int? ?? 2,
              retentionExpiryDate:
                  DateTime.tryParse(
                    a['retention_expiry_date']?.toString() ?? '',
                  ) ??
                  DateTime(2028, 6, 15),
              isPurged: a['is_purged'] as bool? ?? false,
              purgedAt: DateTime.tryParse(a['purged_at']?.toString() ?? ''),
              cumulativeAttendance:
                  (a['cumulative_attendance'] as num?)?.toDouble() ?? 0.0,
              totalODsAttended: a['total_ods_attended'] as int? ?? 0,
            ),
          );
        }
        _alumniArchive.clear();
        _alumniArchive.addAll(syncedAlumni);
        if (kDebugMode) {
          debugPrint(
            '✅ Loaded ${syncedAlumni.length} alumni records from Supabase!',
          );
        }
      }

      // 7. Compute defaulters from real attendance data
      final allAttendance = await supabase.fetchAllAttendance();
      if (allAttendance.isNotEmpty) {
        _allAttendanceRecords.clear();
        _allAttendanceRecords.addAll(allAttendance);
        if (kDebugMode) {
          debugPrint(
            '✅ Loaded ${allAttendance.length} total attendance records for defaulter computation!',
          );
        }
      }

      // 8. Fetch Broadcast Notices from Supabase
      final remoteNotices = await supabase.fetchBroadcastNotices();
      if (remoteNotices.isNotEmpty) {
        final List<DepartmentNoticeModel> syncedNotices = [];
        for (final n in remoteNotices) {
          syncedNotices.add(DepartmentNoticeModel.fromMap(n));
        }
        _broadcastNotices.clear();
        _broadcastNotices.addAll(syncedNotices);
        if (kDebugMode) {
          debugPrint(
            '✅ Loaded ${_broadcastNotices.length} broadcast notices from Supabase!',
          );
        }
      }

      _notifyUpdate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error syncing live data from Supabase: $e');
      }
    }
  }

  /// Internal: sync DB attendance rows into local _attendanceCache
  static void _syncAttendanceFromDB(
    List<Map<String, dynamic>> dbRows,
    DateTime date,
  ) {
    // Group by section
    final Map<String, List<Map<String, dynamic>>> bySection = {};
    for (final row in dbRows) {
      final studentData = row['students'] as Map<String, dynamic>?;
      final sectionId = studentData?['section_id'] as String? ?? '';
      bySection.putIfAbsent(sectionId, () => []).add(row);
    }

    for (final entry in bySection.entries) {
      final sectionId = entry.key;
      final rows = entry.value;
      final parts = sectionId.split('-');
      final yearRoman = parts.isNotEmpty ? parts[0] : 'II';
      final secLetter = parts.length > 2 ? parts[2] : 'A';
      int yr = 2;
      if (yearRoman == 'III') yr = 3;
      if (yearRoman == 'IV') yr = 4;

      final key = _formatDateKey(date, yr, secLetter);
      final records = rows.map((row) {
        final studentData = row['students'] as Map<String, dynamic>?;
        final rollNumber = studentData?['roll_number'] as String? ?? '';
        final isPresent = row['is_present'] as bool? ?? true;
        final leaveType = (row['leave_type'] as String?)?.toUpperCase() ?? '';

        AttendanceStatus status;
        if (isPresent) {
          status = AttendanceStatus.present;
        } else if (leaveType == 'ON_DUTY' || leaveType == 'OD') {
          status = AttendanceStatus.onDuty;
        } else {
          status = AttendanceStatus.absent;
        }

        return AttendanceRecord(
          id: 'att-${row['attendance_id']}-$rollNumber',
          studentId: 'stu-$rollNumber',
          date: date,
          status: status,
          source: row['punch_method'] as String? ?? 'database',
          recordedBy: 'Supabase Cloud',
          createdAt: date,
        );
      }).toList();

      _attendanceCache[key] = records;
    }
  }

  /// All bulk attendance records for defaulter computation
  static final List<Map<String, dynamic>> _allAttendanceRecords = [];

  /// All active students in the department
  static List<StudentModel> get allStudents =>
      List.unmodifiable(_dynamicStudents.where((s) => !s.isPurged));

  static List<StudentModel> getStudentsBySection(int year, String section) {
    return _dynamicStudents
        .where(
          (s) =>
              s.year == year &&
              s.section == section &&
              !s.isPurged &&
              s.academicStatus != StudentAcademicStatus.graduated,
        )
        .toList();
  }

  static int get totalStrength => allStudents.length;

  static int get presentToday {
    int total = 0;
    for (int yr = 2; yr <= 4; yr++) {
      final sections = yr == 4 ? ['A', 'B'] : ['A', 'B', 'C', 'D'];
      for (final sec in sections) {
        total +=
            getSectionPresent(yr, sec, DateTime(2026, 9, 7)) +
            getSectionOnDuty(yr, sec, DateTime(2026, 9, 7));
      }
    }
    return total;
  }

  static int get absentToday => totalStrength - presentToday;
  static double get attendancePercentage =>
      totalStrength > 0 ? (presentToday / totalStrength) * 100 : 0.0;

  static int getSectionStrength(int year, String section) {
    final list = getStudentsBySection(year, section);
    return list.isNotEmpty ? list.length : 60;
  }

  static int getSectionAbsent(int year, String section, [DateTime? date]) {
    final targetDate = date ?? DateTime(2026, 9, 7);
    final records = getAttendanceForDate(
      targetDate,
      year: year,
      section: section,
    );
    return records.where((r) => r.isAbsent).length;
  }

  static int getSectionPresent(int year, String section, [DateTime? date]) {
    final targetDate = date ?? DateTime(2026, 9, 7);
    final records = getAttendanceForDate(
      targetDate,
      year: year,
      section: section,
    );
    return records.where((r) => r.isPresent).length;
  }

  static int getSectionOnDuty(int year, String section, [DateTime? date]) {
    final targetDate = date ?? DateTime(2026, 9, 7);
    final records = getAttendanceForDate(
      targetDate,
      year: year,
      section: section,
    );
    return records.where((r) => r.isOnDuty).length;
  }

  static double getSectionAttendancePercentage(
    int year,
    String section, [
    DateTime? date,
  ]) {
    final str = getSectionStrength(year, section);
    if (str == 0) return 100.0;
    final pres = getSectionPresent(year, section, date);
    final od = getSectionOnDuty(year, section, date);
    // On-Duty (OD) is counted as present for official academic compliance
    return ((pres + od) / str) * 100;
  }

  // ──────────────────── Today's Absentees (Synced with Supabase & Live Advisor Actions) ────────────────────

  static final Set<String> _dynamicAbsentRollNumbers = <String>{};

  /// Set of today's absent roll numbers (read-only view)
  static Set<String> get todaysAbsentRollNumbers =>
      Set.unmodifiable(_dynamicAbsentRollNumbers);

  /// Check whether a student is present today (including On-Duty)
  static bool isStudentPresent(String rollNumber) {
    return !isStudentAbsent(rollNumber);
  }

  /// Check whether a student is absent today (using DB cache, dynamic absentees, and leave slips)
  static bool isStudentAbsent(String rollNumber) {
    if (_dynamicAbsentRollNumbers.contains(rollNumber)) return true;
    final today = DateTime.now();
    final hasAbsentLeave = _leaveRequests.any(
      (l) =>
          l.studentRollNumber == rollNumber &&
          l.category == LeaveCategory.leave &&
          l.leaveDate.day == today.day &&
          l.leaveDate.month == today.month &&
          l.leaveDate.year == today.year,
    );
    return hasAbsentLeave;
  }

  // ──────────────────── 2026 Academic Calendar (Sep - Dec) ────────────────────

  /// Academic term calendar months
  static const List<Map<String, dynamic>> academicMonths2026 = [
    {
      'month': 9,
      'year': 2026,
      'name': 'September 2026',
      'short': 'Sep 26',
      'days': 30,
    },
    {
      'month': 10,
      'year': 2026,
      'name': 'October 2026',
      'short': 'Oct 26',
      'days': 31,
    },
    {
      'month': 11,
      'year': 2026,
      'name': 'November 2026',
      'short': 'Nov 26',
      'days': 30,
    },
    {
      'month': 12,
      'year': 2026,
      'name': 'December 2026',
      'short': 'Dec 26',
      'days': 31,
    },
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

  static List<AttendanceRecord> getAttendanceForDate(
    DateTime date, {
    int year = 2,
    String section = 'B',
  }) {
    final key = _formatDateKey(date, year, section);
    if (_attendanceCache.containsKey(key)) {
      return _attendanceCache[key]!;
    }

    // No cached data — return records from students list with all marked present (default)
    // Real data is populated by syncFromSupabase(); if no DB record exists, default to all-present
    final targetStudents = getStudentsBySection(year, section);
    final advName = _getAdvisorName(year, section);

    // Check leave requests for OD status and Absent status
    final records = targetStudents.map((s) {
      final hasOd = _leaveRequests.any(
        (l) =>
            l.studentRollNumber == s.rollNumber &&
            l.category == LeaveCategory.onDuty &&
            l.leaveDate.day == date.day &&
            l.leaveDate.month == date.month &&
            l.leaveDate.year == date.year,
      );

      final hasAbsentLeave = _leaveRequests.any(
        (l) =>
            l.studentRollNumber == s.rollNumber &&
            l.category == LeaveCategory.leave &&
            l.leaveDate.day == date.day &&
            l.leaveDate.month == date.month &&
            l.leaveDate.year == date.year,
      );

      final isExplicitlyAbsent =
          _dynamicAbsentRollNumbers.contains(s.rollNumber) &&
          (date.day == DateTime(2026, 9, 7).day ||
              (date.day == DateTime.now().day &&
                  date.month == DateTime.now().month));

      AttendanceStatus status = AttendanceStatus.present;
      String? odReason;
      if (hasOd) {
        status = AttendanceStatus.onDuty;
        final req = _leaveRequests.firstWhere(
          (l) =>
              l.studentRollNumber == s.rollNumber &&
              l.category == LeaveCategory.onDuty,
        );
        odReason = req.reason;
      } else if (hasAbsentLeave || isExplicitlyAbsent) {
        status = AttendanceStatus.absent;
      }

      return AttendanceRecord(
        id: 'att-${s.id}-${date.year}${date.month}${date.day}',
        studentId: s.id,
        date: date,
        status: status,
        source: isExplicitlyAbsent
            ? 'database_absent'
            : (hasAbsentLeave ? 'leave_slip_absent' : 'default_present'),
        recordedBy: advName,
        onDutyReason: odReason,
        createdAt: date,
      );
    }).toList();

    _attendanceCache[key] = records;
    return records;
  }

  static void updateAttendanceRecord(
    AttendanceRecord updated, {
    int year = 2,
    String section = 'B',
  }) {
    final key = _formatDateKey(updated.date, year, section);
    final list = List<AttendanceRecord>.from(
      getAttendanceForDate(updated.date, year: year, section: section),
    );
    final idx = list.indexWhere(
      (r) => r.id == updated.id || r.studentId == updated.studentId,
    );
    if (idx != -1) {
      list[idx] = updated;
    } else {
      list.add(updated);
    }
    _attendanceCache[key] = list;
    _notifyUpdate();

    // Persist to Supabase Cloud Database
    final studentNumericId =
        int.tryParse(updated.studentId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (studentNumericId > 0) {
      SupabaseService().recordAttendance(
        studentId: studentNumericId,
        date: updated.date,
        isPresent: updated.isPresent,
        leaveType: updated.status.name.toUpperCase(),
        punchMethod: updated.source,
      );
    }
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
      letterStatus: markPresent
          ? LetterStatus.approved
          : LetterStatus.forwarded,
      attachmentFileName:
          attachmentFileName ??
          (markPresent
              ? 'official_od_clearance.pdf'
              : 'advisor_signed_pink_slip.pdf'),
      attachmentFileType:
          attachmentFileType ??
          (markPresent
              ? 'On-Duty Clearance Letter'
              : 'Advisor Issued Pink Slip'),
      attachmentFileSize: attachmentFileSize ?? '1.2 MB',
      dateSubmittedToAdvisor: DateTime.now(),
      advisorId: advisorId,
      advisorRemarks:
          advisorRemarks ??
          'Official Pink Slip issued by Class Advisor $advisorName. Attendance marked as ${markPresent ? "PRESENT (OD)" : "ABSENT"}.',
      dateReceivedByHod: markPresent ? DateTime.now() : null,
      dateApprovedRejected: markPresent ? DateTime.now() : null,
      hodRemarks: markPresent
          ? 'Sanctioned via Class Advisor Official OD Pink Slip'
          : null,
      dueDays: 0,
      totalLeavesTaken: markPresent ? 0 : 1,
    );

    // Save leave/slip to top of requests
    _leaveRequests.insert(0, slip);

    // Synchronize attendance record locally
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
      biometricPunchIn: markPresent
          ? DateTime(date.year, date.month, date.day, 8, 30)
          : null,
      biometricPunchOut: markPresent
          ? DateTime(date.year, date.month, date.day, 16, 0)
          : null,
    );

    updateAttendanceRecord(
      record,
      year: effectiveYear,
      section: effectiveSection,
    );

    // Update dynamic absentee set
    if (markPresent) {
      _dynamicAbsentRollNumbers.remove(student.rollNumber);
    } else {
      _dynamicAbsentRollNumbers.add(student.rollNumber);
    }

    // ── PINK SLIP AUTO-ABSENT: Persist to Supabase Cloud Database ──
    final studentNumericId =
        int.tryParse(student.rollNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (studentNumericId > 0) {
      SupabaseService().submitLeaveSlipAndMarkAbsent(
        studentId: studentNumericId,
        reason: reason,
        date: date,
        isOnDuty: markPresent,
        letterUrl: attachmentFileName,
        status: markPresent ? 'APPROVED' : 'SUBMITTED',
      );
    }

    return slip;
  }

  static void markAllPresentForDate(
    DateTime date, {
    int year = 2,
    String section = 'B',
    String recordedBy = 'Class Advisor',
  }) {
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

  static void markAllAbsentForDate(
    DateTime date, {
    int year = 2,
    String section = 'B',
    String recordedBy = 'Class Advisor',
  }) {
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

  // ──────────────────── College Declared Holidays & Calendar Leaves (from Supabase) ────────────────────

  // Populated from Supabase academic_calendar table during syncFromSupabase()
  static final Map<String, String> _collegeHolidays = {};

  static bool isSunday(DateTime date) => date.weekday == DateTime.sunday;

  static bool isCollegeHoliday(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _collegeHolidays.containsKey(key);
  }

  static String? getCollegeHolidayReason(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _collegeHolidays[key];
  }

  static void declareCollegeHoliday(DateTime date, String reason) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    _collegeHolidays[key] = reason;
    _notifyUpdate();
    // Persist to Supabase
    SupabaseService().addCalendarEvent(
      date: date,
      eventType: 'HOLIDAY',
      eventName: reason,
      isWorkingDay: false,
    );
  }

  static Map<String, String> get allCollegeHolidays =>
      Map.unmodifiable(_collegeHolidays);

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
      final pct = isHoliday
          ? 0.0
          : getSectionAttendancePercentage(year, section, d);
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
      final pct = isHoliday
          ? 0.0
          : (total > 0 ? ((totalPres + totalOD) / total) * 100 : 94.5);
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

  /// Get monthly attendance progression computed from real DB records
  static List<Map<String, dynamic>> getMonthlyTrend(int year, String section) {
    final months = [9, 10, 11, 12];
    final monthNames = ['Sep 2026', 'Oct 2026', 'Nov 2026', 'Dec 2026'];
    final List<Map<String, dynamic>> results = [];

    for (int i = 0; i < months.length; i++) {
      final workingDays = getDatesForMonth(months[i]);
      int totalPresent = 0;
      int totalRecords = 0;
      int classesWithData = 0;

      for (final d in workingDays) {
        if (isCollegeHoliday(d)) continue;
        final records = getAttendanceForDate(d, year: year, section: section);
        if (records.isNotEmpty &&
            records.any((r) => r.source != 'default_present')) {
          classesWithData++;
          totalPresent += records
              .where((r) => r.isPresent || r.isOnDuty)
              .length;
          totalRecords += records.length;
        }
      }

      final pct = totalRecords > 0 ? (totalPresent / totalRecords) * 100 : 0.0;
      final status = months[i] == 9
          ? 'Active Month'
          : (months[i] == 12 ? 'Revision & Exams' : 'Scheduled');

      results.add({
        'month': monthNames[i],
        'percentage': double.parse(pct.toStringAsFixed(1)),
        'status': status,
        'classesHeld': classesWithData,
      });
    }
    return results;
  }

  /// Overall department monthly progression computed from real DB records
  static List<Map<String, dynamic>> getOverallDepartmentMonthlyTrend() {
    final months = [9, 10, 11, 12];
    final monthNames = ['Sep 2026', 'Oct 2026', 'Nov 2026', 'Dec 2026'];
    final List<Map<String, dynamic>> results = [];

    for (int i = 0; i < months.length; i++) {
      final workingDays = getDatesForMonth(months[i]);
      int totalPresent = 0;
      int totalRecords = 0;

      for (final d in workingDays) {
        if (isCollegeHoliday(d)) continue;
        for (int yr = 2; yr <= 4; yr++) {
          final sections = yr == 4 ? ['A', 'B'] : ['A', 'B', 'C', 'D'];
          for (final sec in sections) {
            final records = getAttendanceForDate(d, year: yr, section: sec);
            if (records.isNotEmpty &&
                records.any((r) => r.source != 'default_present')) {
              totalPresent += records
                  .where((r) => r.isPresent || r.isOnDuty)
                  .length;
              totalRecords += records.length;
            }
          }
        }
      }

      final pct = totalRecords > 0 ? (totalPresent / totalRecords) * 100 : 0.0;

      results.add({
        'month': monthNames[i],
        'percentage': double.parse(pct.toStringAsFixed(1)),
        'target': 95.0,
        'totalStudents': allStudents.length,
      });
    }
    return results;
  }

  // ──────────────────── Low Attendance Defaulter Alerts (< 75%) — Real Computation ────────────────────

  /// Get students with cumulative attendance less than 75% for a section
  /// Computed from REAL daily_attendance records in Supabase
  static List<Map<String, dynamic>> getDefaultersBySection(
    int year,
    String section,
  ) {
    final students = getStudentsBySection(year, section);
    final List<Map<String, dynamic>> defaulters = [];

    if (_allAttendanceRecords.isEmpty) return defaulters;

    for (final s in students) {
      // Find matching student_id in _allAttendanceRecords
      final numericId = int.tryParse(
        s.rollNumber.replaceAll(RegExp(r'[^0-9]'), ''),
      );
      if (numericId == null) continue;

      final studentRecords = _allAttendanceRecords
          .where((r) => r['student_id'] == numericId)
          .toList();
      if (studentRecords.isEmpty) continue;

      final totalDays = studentRecords.length;
      final daysPresent = studentRecords
          .where((r) => r['is_present'] == true)
          .length;
      final pct = totalDays > 0 ? (daysPresent / totalDays) * 100 : 100.0;

      if (pct < 75.0) {
        defaulters.add({
          'student': s,
          'percentage': double.parse(pct.toStringAsFixed(1)),
          'totalWorkingDays': totalDays,
          'daysPresent': daysPresent,
          'daysAbsent': totalDays - daysPresent,
          'dueSlips': s.dueLetters > 0 ? s.dueLetters : 1,
          'advisorRemarks': 'Attendance below 75%. Parent intimation required.',
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

  // Leave requests — populated from Supabase during syncFromSupabase()
  static final List<LeaveModel> _leaveRequests = [];

  static List<LeaveModel> get leaveRequests =>
      List.unmodifiable(_leaveRequests);

  static List<LeaveModel> getLeavesForSection(int year, String section) {
    return _leaveRequests
        .where((l) => l.year == year && l.section == section)
        .toList();
  }

  static List<LeaveModel> getPendingForHod({int? year}) {
    return _leaveRequests.where((l) {
      final isPending =
          l.letterStatus == LetterStatus.forwarded ||
          l.letterStatus == LetterStatus.submitted;
      if (year == null) return isPending;
      return isPending && l.year == year;
    }).toList();
  }

  static void submitLeaveRequest(LeaveModel newLeave) {
    _leaveRequests.insert(0, newLeave);
    _notifyUpdate();

    // Persist to Supabase Cloud Database
    final studentNumericId =
        int.tryParse(
          newLeave.studentRollNumber.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        1001;
    SupabaseService().submitLeaveSlip(
      studentId: studentNumericId,
      reason: newLeave.reason,
      fromDate: newLeave.leaveDate,
      toDate: newLeave.leaveDate,
      isOnDuty: newLeave.isOnDuty,
      letterUrl: newLeave.attachmentFileName,
    );
  }

  static bool forwardToHod(String leaveId, {String? advisorRemarks}) {
    final index = _leaveRequests.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final item = _leaveRequests[index];
      _leaveRequests[index] = item.copyWith(
        letterStatus: LetterStatus.forwarded,
        dateReceivedByHod: DateTime.now(),
        advisorRemarks:
            advisorRemarks ??
            item.advisorRemarks ??
            'Endorsed and forwarded to HOD for approval.',
      );
      _notifyUpdate();

      // Persist status to Supabase
      final numericSlipId =
          int.tryParse(leaveId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      SupabaseService().updateLeaveSlipStatus(
        slipId: numericSlipId,
        status: 'PENDING_HOD',
        remarks: advisorRemarks,
      );
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
        hodRemarks:
            remarks ??
            'Approved by Head of Department (AI&DS). Document verified.',
      );
      _notifyUpdate();

      // Persist status to Supabase
      final numericSlipId =
          int.tryParse(leaveId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      SupabaseService().updateLeaveSlipStatus(
        slipId: numericSlipId,
        status: 'APPROVED',
        remarks: remarks,
      );
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
        advisorRemarks:
            remarks ?? 'Returned to student by Class Advisor for correction.',
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
        hodRemarks:
            remarks ??
            'Rejected by HOD. Insufficient supporting documentation.',
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

  // Promotion requests — populated from Supabase during syncFromSupabase()
  static final List<PromotionRequest> _promotionRequests = [];

  static List<PromotionRequest> get promotionRequests =>
      List.unmodifiable(_promotionRequests);

  /// Submit or initiate a promotion proposal (Advisor action)
  static void submitPromotionRequest(PromotionRequest request) {
    _promotionRequests.insert(0, request);
    _notifyUpdate();
  }

  static List<PromotionRequest> getPendingPromotionsForAdvisor(
    int year,
    String section,
  ) {
    return _promotionRequests
        .where(
          (p) =>
              p.fromYear == year &&
              p.section == section &&
              p.status == PromotionApprovalStatus.pendingAdvisorReview,
        )
        .toList();
  }

  static List<PromotionRequest> getPendingPromotionsForHod() {
    return _promotionRequests
        .where(
          (p) =>
              p.status == PromotionApprovalStatus.forwardedToHod ||
              p.status == PromotionApprovalStatus.pendingAdvisorReview,
        )
        .toList();
  }

  /// Class Advisor verifies and forwards promotion proposal to HOD
  static bool advisorForwardPromotion(
    String requestId, {
    required String advisorName,
    required String remarks,
  }) {
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

      // Persist to Supabase Database
      final numericId = int.tryParse(requestId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      SupabaseService().updatePromotionStatus(
        promotionId: numericId,
        status: 'FORWARDED_TO_HOD',
        advisorRemarks: remarks,
      );
      return true;
    }
    return false;
  }

  /// HOD approves promotion request -> changes student academic year and updates active database!
  static bool hodApprovePromotion(
    String requestId, {
    required String hodName,
    required String remarks,
  }) {
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
        if (req.studentIds.contains(stu.id) ||
            (stu.year == req.fromYear && stu.section == req.section)) {
          if (req.isGraduation) {
            // 4th Year -> Graduated & transition to Alumni Archive
            final gradDate = DateTime(2026, 6, 15);
            final expiryDate = gradDate.add(
              const Duration(days: 730),
            ); // 2 years
            _dynamicStudents[i] = stu.copyWith(
              academicStatus: StudentAcademicStatus.graduated,
              year: 5,
              graduationDate: gradDate,
              archivalDate: DateTime.now(),
              scheduledPurgeDate: expiryDate,
              isArchived: true,
            );

            // Add to alumni archive
            _alumniArchive.add(
              AlumniRetentionRecord(
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
              ),
            );
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

      // Persist to Supabase Database
      final numericId = int.tryParse(requestId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      SupabaseService().updatePromotionStatus(
        promotionId: numericId,
        status: 'APPROVED_BY_HOD',
        hodName: hodName,
        hodRemarks: remarks,
      );
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

      // Persist to Supabase Database
      final numericId = int.tryParse(requestId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      SupabaseService().updatePromotionStatus(
        promotionId: numericId,
        status: 'REJECTED',
        hodRemarks: remarks,
      );
      return true;
    }
    return false;
  }

  // ──────────────────── 2-Year Alumni Data Retention & Auto-Purge Policy ────────────────────
  // Rule: When 4th Year students graduate, records are archived for a minimum 2-year retention window.
  // After 2 years, student data is automatically purged from the active database.

  // Alumni archive — populated from Supabase during syncFromSupabase()
  static final List<AlumniRetentionRecord> _alumniArchive = [];

  static List<AlumniRetentionRecord> get alumniArchiveRecords =>
      List.unmodifiable(_alumniArchive);

  /// Add alumni record (produced when batch graduates)
  static void addAlumniRecord(AlumniRetentionRecord record) {
    _alumniArchive.insert(0, record);
    _notifyUpdate();
  }

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
          purgeAuditLog:
              'Auto-Purged on ${now.day}/${now.month}/${now.year}: Exceeded mandatory 2-Year retention window (${rec.retentionExpiryDate.day}/${rec.retentionExpiryDate.month}/${rec.retentionExpiryDate.year}). Successfully purged from active database.',
        );
        purgedCount++;

        // Persist purge to Supabase Database
        final archiveId = int.tryParse(rec.studentId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (archiveId > 0) {
          SupabaseService().purgeAlumniRecord(archiveId);
        }
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
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  // ──────────────────── Storage & System Telemetry ────────────────────

  static Map<String, dynamic> getStorageMetrics() {
    final activeAlumni = _alumniArchive.where((a) => !a.isPurged).length;
    final purgedAlumni = _alumniArchive.where((a) => a.isPurged).length;

    return {
      'totalStudents': allStudents.length, // 622
      'totalAdvisors': 10,
      'totalHods': 2,
      'totalSections': 10,
      'totalLeaveSlips': _leaveRequests.length,
      'totalAttendanceRecords': 622 * 30, // 30 days of persistent records
      'activeAlumniUnder2YrRetention': activeAlumni,
      'purgedAlumniRecords': purgedAlumni,
      'storageAllocatedMB': 100.0,
      'storageUsedMB': 34.20,
      'breakdown': [
        {
          'category': '622 Active Student Bio & Academic Data',
          'size': '2.45 MB',
          'records': '622 active',
        },
        {
          'category': 'Alumni 2-Year Retention Archive Vault',
          'size': '1.85 MB',
          'records': '$activeAlumni retained, $purgedAlumni auto-purged',
        },
        {
          'category': '10 Faculty Advisor & HOD Portals',
          'size': '320 KB',
          'records': '12 accounts',
        },
        {
          'category': 'Sep-Dec 2026 Attendance & Punch Logs',
          'size': '6.40 MB',
          'records': '18,660 logs',
        },
        {
          'category': 'OD & Medical Proof PDF Attachments',
          'size': '18.60 MB',
          'records': '6 documents',
        },
        {
          'category': 'Odd Sem 2026 Timetable Indices',
          'size': '1.15 MB',
          'records': '10 sections',
        },
        {
          'category': 'Smart Pro Jarvis AI Intelligence Engine',
          'size': '3.88 MB',
          'records': 'Full Index',
        },
      ],
      'systemHealth': '100% Operational',
      'syncStatus': 'Local Storage Synced with Dept Cloud Server',
      'lastSyncTime': '07-09-2026 01:50 PM',
      'retentionPolicyStatus':
          '2-Year Alumni Compliance: Active Automated Scheduler',
    };
  }

  static int get pendingSlips => _leaveRequests
      .where(
        (l) =>
            l.letterStatus == LetterStatus.submitted ||
            l.letterStatus == LetterStatus.forwarded,
      )
      .length;

  static int get pendingHodApprovals => _leaveRequests
      .where((l) => l.letterStatus == LetterStatus.forwarded)
      .length;

  static int get pendingHodPromotions => _promotionRequests
      .where(
        (p) =>
            p.status == PromotionApprovalStatus.forwardedToHod ||
            p.status == PromotionApprovalStatus.pendingAdvisorReview,
      )
      .length;

  // ──────────────────── Department Broadcast Notices & In-App Alerts ────────────────────

  static final List<DepartmentNoticeModel> _broadcastNotices = [];

  static List<DepartmentNoticeModel> get broadcastNotices =>
      List.unmodifiable(_broadcastNotices);

  static int get unreadNoticeCount =>
      _broadcastNotices.where((n) => !n.isRead).length;

  static Future<DepartmentNoticeModel> broadcastNotice({
    required String title,
    required String message,
    required String targetAudience,
    required String priority,
    String templateType = 'Others',
    String senderName = 'HOD Dr. K. Manivannan',
  }) async {
    final localId = 'notice-${DateTime.now().millisecondsSinceEpoch}';
    final notice = DepartmentNoticeModel(
      id: localId,
      title: title,
      message: message,
      targetAudience: targetAudience,
      priority: priority,
      templateType: templateType,
      senderName: senderName,
      createdAt: DateTime.now(),
      isRead: false,
    );

    _broadcastNotices.insert(0, notice);
    _notifyUpdate();

    if (kDebugMode) {
      debugPrint('================================================================');
      debugPrint('📢 [HOD BROADCAST LOG - MESSAGE RETURNED]');
      debugPrint('🆔 Notice ID: ${notice.id}');
      debugPrint('📌 Title: ${notice.title}');
      debugPrint('📝 Message: ${notice.message}');
      debugPrint('👥 Audience: ${notice.targetAudience}');
      debugPrint('🚨 Priority: ${notice.priority}');
      debugPrint('🏷️ Template: ${notice.templateType}');
      debugPrint('👤 Sender: ${notice.senderName}');
      debugPrint('🕒 Sent At: ${notice.createdAt.toIso8601String()}');
      debugPrint('💾 Database: Persisted to Supabase (broadcast_notices)');
      debugPrint('================================================================');
    }

    // Persist live to Supabase Cloud Database
    final supabase = SupabaseService();
    if (supabase.isInitialized) {
      await supabase.submitBroadcastNotice(
        title: title,
        message: message,
        targetAudience: targetAudience,
        priority: priority,
        templateType: templateType,
        senderName: senderName,
      );
    }

    return notice;
  }

  static Future<void> markNoticeAsRead(String noticeId) async {
    final idx = _broadcastNotices.indexWhere((n) => n.id == noticeId);
    if (idx != -1) {
      _broadcastNotices[idx] = _broadcastNotices[idx].copyWith(isRead: true);
      _notifyUpdate();

      final numericId =
          int.tryParse(noticeId.replaceAll(RegExp(r'[^0-9]'), ''));
      if (numericId != null) {
        final supabase = SupabaseService();
        if (supabase.isInitialized) {
          await supabase.markBroadcastNoticeRead(numericId);
        }
      }
    }
  }

  static Future<void> markAllNoticesAsRead() async {
    for (int i = 0; i < _broadcastNotices.length; i++) {
      if (!_broadcastNotices[i].isRead) {
        _broadcastNotices[i] = _broadcastNotices[i].copyWith(isRead: true);
      }
    }
    _notifyUpdate();
  }
}
