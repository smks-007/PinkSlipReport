/// Represents a student in the system.
class StudentModel {
  final String id;
  final String name;
  final String rollNumber;
  final String department;
  final String section;
  final int year;
  final String advisorId;
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
    required this.advisorId,
    this.totalLeavesTaken = 0,
    this.dueLetters = 0,
    this.isPresentToday = true,
  });

  String get classDisplay => '${'I' * year} $department - Section $section';
}
