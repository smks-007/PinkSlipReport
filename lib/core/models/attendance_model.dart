/// Attendance status options
enum AttendanceStatus {
  present,
  absent,
  onDuty,
}

/// Represents a single attendance record for a student.
class AttendanceRecord {
  final String id;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? biometricPunchIn;
  final DateTime? biometricPunchOut;
  final String source; // "biometric" or "manual"
  final String? recordedBy; // userId/advisor who recorded
  final String? onDutyReason;
  final String? typedLetter;
  final String? attachmentFileName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.date,
    this.status = AttendanceStatus.present,
    this.biometricPunchIn,
    this.biometricPunchOut,
    this.source = 'manual',
    this.recordedBy,
    this.onDutyReason,
    this.typedLetter,
    this.attachmentFileName,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;
  bool get isOnDuty => status == AttendanceStatus.onDuty;

  String get punchInFormatted {
    if (biometricPunchIn == null) return 'No Punch';
    final h = biometricPunchIn!.hour;
    final m = biometricPunchIn!.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${displayH.toString().padLeft(2, '0')}:$m $period';
  }

  String get punchOutFormatted {
    if (biometricPunchOut == null) return 'Pending (04:30 PM)';
    final h = biometricPunchOut!.hour;
    final m = biometricPunchOut!.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${displayH.toString().padLeft(2, '0')}:$m $period';
  }

  String get statusDisplay {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.onDuty:
        return 'On-Duty (OD)';
    }
  }

  AttendanceRecord copyWith({
    AttendanceStatus? status,
    bool? isPresent,
    String? source,
    String? recordedBy,
    String? onDutyReason,
    String? typedLetter,
    String? attachmentFileName,
    DateTime? updatedAt,
  }) {
    AttendanceStatus newStatus = status ?? this.status;
    if (status == null && isPresent != null) {
      newStatus = isPresent ? AttendanceStatus.present : AttendanceStatus.absent;
    }

    return AttendanceRecord(
      id: id,
      studentId: studentId,
      date: date,
      status: newStatus,
      biometricPunchIn: biometricPunchIn,
      biometricPunchOut: biometricPunchOut,
      source: source ?? this.source,
      recordedBy: recordedBy ?? this.recordedBy,
      onDutyReason: onDutyReason ?? this.onDutyReason,
      typedLetter: typedLetter ?? this.typedLetter,
      attachmentFileName: attachmentFileName ?? this.attachmentFileName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
