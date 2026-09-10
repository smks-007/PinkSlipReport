import 'promotion_model.dart';

/// Represents a student in the system with academic progression & lifecycle tracking.
class StudentModel {
  final String id;
  final String name;
  final String rollNumber;
  final String? registerNumber;
  final String department;
  final String section;
  final int year;
  final int currentSemester; // 1 to 8 (e.g. Year 1 = Sem 1 & 2, Year 2 = Sem 3 & 4, etc.)
  final String batchYear; // e.g. '2025 BATCH', '2024 BATCH', '2023 BATCH'
  final String advisorId;
  final String gender; // 'Male' or 'Female'
  final int totalLeavesTaken;
  final int dueLetters;
  final bool isPresentToday;
  final StudentAcademicStatus academicStatus;
  final DateTime? graduationDate;
  final DateTime? archivalDate;
  final DateTime? scheduledPurgeDate;
  final bool isArchived;
  final bool isPurged;

  const StudentModel({
    required this.id,
    required this.name,
    required this.rollNumber,
    this.registerNumber,
    required this.department,
    required this.section,
    required this.year,
    this.currentSemester = 3,
    required this.batchYear,
    required this.advisorId,
    this.gender = 'Male',
    this.totalLeavesTaken = 0,
    this.dueLetters = 0,
    this.isPresentToday = true,
    this.academicStatus = StudentAcademicStatus.active,
    this.graduationDate,
    this.archivalDate,
    this.scheduledPurgeDate,
    this.isArchived = false,
    this.isPurged = false,
  });

  String get romanYear {
    if (year >= 5 || academicStatus == StudentAcademicStatus.graduated || academicStatus == StudentAcademicStatus.archived) {
      return 'Alumni';
    }
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
        return '';
    }
  }

  String get classDisplay => year >= 5 ? 'Graduated Alumni ($batchYear)' : '$romanYear AI&DS - Section $section';
  String get fullClassDetails => year >= 5 ? 'Graduated Alumni - $name ($batchYear)' : '$romanYear AI&DS - Section $section ($batchYear)';

  StudentModel copyWith({
    String? id,
    String? name,
    String? rollNumber,
    String? registerNumber,
    String? department,
    String? section,
    int? year,
    int? currentSemester,
    String? batchYear,
    String? advisorId,
    String? gender,
    int? totalLeavesTaken,
    int? dueLetters,
    bool? isPresentToday,
    StudentAcademicStatus? academicStatus,
    DateTime? graduationDate,
    DateTime? archivalDate,
    DateTime? scheduledPurgeDate,
    bool? isArchived,
    bool? isPurged,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      registerNumber: registerNumber ?? this.registerNumber,
      department: department ?? this.department,
      section: section ?? this.section,
      year: year ?? this.year,
      currentSemester: currentSemester ?? this.currentSemester,
      batchYear: batchYear ?? this.batchYear,
      advisorId: advisorId ?? this.advisorId,
      gender: gender ?? this.gender,
      totalLeavesTaken: totalLeavesTaken ?? this.totalLeavesTaken,
      dueLetters: dueLetters ?? this.dueLetters,
      isPresentToday: isPresentToday ?? this.isPresentToday,
      academicStatus: academicStatus ?? this.academicStatus,
      graduationDate: graduationDate ?? this.graduationDate,
      archivalDate: archivalDate ?? this.archivalDate,
      scheduledPurgeDate: scheduledPurgeDate ?? this.scheduledPurgeDate,
      isArchived: isArchived ?? this.isArchived,
      isPurged: isPurged ?? this.isPurged,
    );
  }
}
