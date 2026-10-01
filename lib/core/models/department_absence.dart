/// A single student absent from the department on a selected attendance day.
class DepartmentAbsence {
  const DepartmentAbsence({
    required this.studentId,
    required this.name,
    required this.rollNumber,
    required this.registerNumber,
    required this.section,
  });

  final int studentId;
  final String name;
  final String rollNumber;
  final String registerNumber;
  final String section;

  factory DepartmentAbsence.fromJson(Map<String, dynamic> json) =>
      DepartmentAbsence(
        studentId: json['student_id'] as int,
        name: json['student_name'] as String,
        rollNumber: json['roll_number'] as String,
        registerNumber: json['register_number'] as String,
        section: json['section_id'] as String,
      );
}

/// Results for a selected department chart day.
class DepartmentAbsenceReport {
  const DepartmentAbsenceReport({
    required this.recordedCount,
    required this.absences,
  });

  final int recordedCount;
  final List<DepartmentAbsence> absences;

  factory DepartmentAbsenceReport.fromJson(Map<String, dynamic> json) {
    final rawAbsences = json['absences'];
    if (rawAbsences is! List) {
      throw const FormatException('Invalid absence list.');
    }
    return DepartmentAbsenceReport(
      recordedCount: json['recorded_count'] as int,
      absences: rawAbsences
          .map(
            (row) => DepartmentAbsence.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}
