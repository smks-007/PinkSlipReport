/// Represents a student in the system.
class StudentModel {
  final String id;
  final String name;
  final String rollNumber;
  final String department;
  final String section;
  final int year;
  final String batchYear; // e.g. '2025 BATCH', '2024 BATCH', '2023 BATCH'
  final String advisorId;
  final String gender; // 'Male' or 'Female'
  final int totalLeavesTaken;
  final int dueLetters;
  final bool isPresentToday;

  const StudentModel({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.department,
    required this.section,
    required this.year,
    required this.batchYear,
    required this.advisorId,
    this.gender = 'Male',
    this.totalLeavesTaken = 0,
    this.dueLetters = 0,
    this.isPresentToday = true,
  });

  String get romanYear {
    switch (year) {
      case 1:
        return 'I';
      case 2:
        return 'II';
      case 3:
        return 'III';
      case 4:
        return 'IV';
      default:
        return '$year';
    }
  }

  String get classDisplay => '$romanYear $department - Section $section';
  String get fullClassDetails => '$romanYear $department - Section $section ($batchYear)';
}
