/// Academic progression status of a student
enum StudentAcademicStatus {
  active,
  pendingPromotion,
  promoted,
  graduated,
  archived,
  purged,
}

/// Status of the promotion approval workflow
enum PromotionApprovalStatus {
  pendingAdvisorReview, // 7-10 days after 2nd semester completion, sent to Advisor
  forwardedToHod,        // Advisor reviewed & endorsed, sent to HOD
  approvedByHod,         // HOD approved, student promoted to next year
  rejected,              // Needs clearance or re-evaluation
}

/// Model representing a Year-End Batch / Student Promotion Request
class PromotionRequest {
  final String id;
  final int fromYear;            // e.g. 1, 2, 3, 4
  final int toYear;              // e.g. 2, 3, 4, 5 (5 represents Graduated / Alumni)
  final String section;          // e.g. 'A', 'B', 'C', 'D'
  final String batchYear;        // e.g. '2025 BATCH', '2024 BATCH', '2023 BATCH'
  final int semesterCompleted;   // e.g. 2, 4, 6, 8 (2nd semester of that year)
  final DateTime semesterEndDate;
  final int graceTransitionDays; // 7 to 10 days evaluation window
  final DateTime eligiblePromotionDate;
  final List<String> studentIds;
  final int totalStudents;
  final PromotionApprovalStatus status;
  final String? advisorName;
  final String? advisorRemarks;
  final DateTime? dateForwardedByAdvisor;
  final String? hodName;
  final String? hodRemarks;
  final DateTime? dateApprovedByHod;
  final DateTime createdAt;

  const PromotionRequest({
    required this.id,
    required this.fromYear,
    required this.toYear,
    required this.section,
    required this.batchYear,
    required this.semesterCompleted,
    required this.semesterEndDate,
    this.graceTransitionDays = 7,
    required this.eligiblePromotionDate,
    required this.studentIds,
    required this.totalStudents,
    this.status = PromotionApprovalStatus.pendingAdvisorReview,
    this.advisorName,
    this.advisorRemarks,
    this.dateForwardedByAdvisor,
    this.hodName,
    this.hodRemarks,
    this.dateApprovedByHod,
    required this.createdAt,
  });

  bool get isGraduation => fromYear >= 4;

  String get fromYearRoman {
    switch (fromYear) {
      case 1: return 'I Year';
      case 2: return 'II Year';
      case 3: return 'III Year';
      case 4: return 'IV Year (Final Year)';
      default: return 'Year ';
    }
  }

  String get toYearRoman {
    switch (toYear) {
      case 2: return 'II Year';
      case 3: return 'III Year';
      case 4: return 'IV Year';
      case 5: return 'Graduated / Alumni Archive';
      default: return 'Year ';
    }
  }

  String get promotionTitle => ' ➔  (Sec  - )';

  String get statusBadgeLabel {
    switch (status) {
      case PromotionApprovalStatus.pendingAdvisorReview:
        return 'Pending Advisor Endorsement';
      case PromotionApprovalStatus.forwardedToHod:
        return 'Awaiting HOD Approval';
      case PromotionApprovalStatus.approvedByHod:
        return isGraduation ? 'Graduation & Archive Confirmed' : 'Promoted to ';
      case PromotionApprovalStatus.rejected:
        return 'Promotion On Hold / Rejected';
    }
  }

  PromotionRequest copyWith({
    String? id,
    int? fromYear,
    int? toYear,
    String? section,
    String? batchYear,
    int? semesterCompleted,
    DateTime? semesterEndDate,
    int? graceTransitionDays,
    DateTime? eligiblePromotionDate,
    List<String>? studentIds,
    int? totalStudents,
    PromotionApprovalStatus? status,
    String? advisorName,
    String? advisorRemarks,
    DateTime? dateForwardedByAdvisor,
    String? hodName,
    String? hodRemarks,
    DateTime? dateApprovedByHod,
    DateTime? createdAt,
  }) {
    return PromotionRequest(
      id: id ?? this.id,
      fromYear: fromYear ?? this.fromYear,
      toYear: toYear ?? this.toYear,
      section: section ?? this.section,
      batchYear: batchYear ?? this.batchYear,
      semesterCompleted: semesterCompleted ?? this.semesterCompleted,
      semesterEndDate: semesterEndDate ?? this.semesterEndDate,
      graceTransitionDays: graceTransitionDays ?? this.graceTransitionDays,
      eligiblePromotionDate: eligiblePromotionDate ?? this.eligiblePromotionDate,
      studentIds: studentIds ?? this.studentIds,
      totalStudents: totalStudents ?? this.totalStudents,
      status: status ?? this.status,
      advisorName: advisorName ?? this.advisorName,
      advisorRemarks: advisorRemarks ?? this.advisorRemarks,
      dateForwardedByAdvisor: dateForwardedByAdvisor ?? this.dateForwardedByAdvisor,
      hodName: hodName ?? this.hodName,
      hodRemarks: hodRemarks ?? this.hodRemarks,
      dateApprovedByHod: dateApprovedByHod ?? this.dateApprovedByHod,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Model tracking 4th Year Graduated Students under the 2-Year Data Retention Policy
class AlumniRetentionRecord {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String department;
  final String section;
  final String batchYear;
  final DateTime graduationDate;
  final int retentionPeriodYears; // Minimum 2 years
  final DateTime retentionExpiryDate;
  final bool isPurged;
  final DateTime? purgedAt;
  final String? purgeAuditLog;
  final double cumulativeAttendance;
  final int totalODsAttended;

  const AlumniRetentionRecord({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    this.department = 'AI&DS',
    required this.section,
    required this.batchYear,
    required this.graduationDate,
    this.retentionPeriodYears = 2,
    required this.retentionExpiryDate,
    this.isPurged = false,
    this.purgedAt,
    this.purgeAuditLog,
    this.cumulativeAttendance = 92.4,
    this.totalODsAttended = 4,
  });

  /// Check if retention duration has exceeded 2 years relative to reference date
  bool isExpired([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    return now.isAfter(retentionExpiryDate);
  }

  /// Days remaining in active 2-year retention window
  int daysRemaining([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final diff = retentionExpiryDate.difference(now).inDays;
    return diff > 0 ? diff : 0;
  }

  String get retentionTimelineLabel {
    if (isPurged) {
      final p = purgedAt;
      return p != null
          ? 'Purged from Active Database (${p.day.toString().padLeft(2, '0')}/${p.month.toString().padLeft(2, '0')}/${p.year})'
          : 'Purged from Active Database';
    }
    final days = daysRemaining(DateTime(2026, 9, 7));
    if (days == 0) {
      return '2-Year Retention Expired -> Ready for Auto-Purge';
    }
    final months = (days / 30).floor();
    return 'Retained (2-Yr Rule): $months months ($days days remaining)';
  }

  AlumniRetentionRecord copyWith({
    String? studentId,
    String? studentName,
    String? rollNumber,
    String? department,
    String? section,
    String? batchYear,
    DateTime? graduationDate,
    int? retentionPeriodYears,
    DateTime? retentionExpiryDate,
    bool? isPurged,
    DateTime? purgedAt,
    String? purgeAuditLog,
    double? cumulativeAttendance,
    int? totalODsAttended,
  }) {
    return AlumniRetentionRecord(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      department: department ?? this.department,
      section: section ?? this.section,
      batchYear: batchYear ?? this.batchYear,
      graduationDate: graduationDate ?? this.graduationDate,
      retentionPeriodYears: retentionPeriodYears ?? this.retentionPeriodYears,
      retentionExpiryDate: retentionExpiryDate ?? this.retentionExpiryDate,
      isPurged: isPurged ?? this.isPurged,
      purgedAt: purgedAt ?? this.purgedAt,
      purgeAuditLog: purgeAuditLog ?? this.purgeAuditLog,
      cumulativeAttendance: cumulativeAttendance ?? this.cumulativeAttendance,
      totalODsAttended: totalODsAttended ?? this.totalODsAttended,
    );
  }
}
