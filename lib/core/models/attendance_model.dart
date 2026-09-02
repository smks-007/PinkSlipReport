/// Represents a single attendance record for a student.
class AttendanceRecord {
  final String id;
  final String studentId;
  final DateTime date;
  final bool isPresent;
  final DateTime? biometricPunchIn;
  final DateTime? biometricPunchOut;
  final String source; // "biometric" or "manual"
  final String? recordedBy; // userId who recorded/edited
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.date,
    required this.isPresent,
    this.biometricPunchIn,
    this.biometricPunchOut,
    this.source = 'biometric',
    this.recordedBy,
    required this.createdAt,
    this.updatedAt,
  });

  AttendanceRecord copyWith({
    bool? isPresent,
    String? source,
    String? recordedBy,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id,
      studentId: studentId,
      date: date,
      isPresent: isPresent ?? this.isPresent,
      biometricPunchIn: biometricPunchIn,
      biometricPunchOut: biometricPunchOut,
      source: source ?? this.source,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
