/// Roles available in the PinkSlipReport system.
enum UserRole { hod, advisor, student }

/// Represents an authenticated user in the system.
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String college;
  final String? classSection; // e.g., "II AI&DS - Section B"
  final String? batchYear; // e.g., "2025 BATCH"
  final String? hodScope; // e.g., "1st & 2nd Year" or "Overall & 3rd/4th Year"
  final String? avatarUrl;
  final bool isClassRepresentative;
  final String? rollNumber;
  final String? gender; // 'Boy' or 'Girl'
  final int? year; // 2, 3, 4
  final String? section; // 'A', 'B', 'C', 'D'
  final String? customUsername;
  final String? customPassword;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.college = 'V.S.B. Engineering College',
    this.classSection,
    this.batchYear,
    this.hodScope,
    this.avatarUrl,
    this.isClassRepresentative = false,
    this.rollNumber,
    this.gender,
    this.year,
    this.section,
    this.customUsername,
    this.customPassword,
  });

  String get username => customUsername ?? (rollNumber ?? email.split('@').first);
  String get password => customPassword ?? (rollNumber != null ? 'Stu@$rollNumber' : 'password123');

  String get roleDisplayName {
    switch (role) {
      case UserRole.hod:
        return hodScope != null ? 'HOD ($hodScope)' : 'Head of Department';
      case UserRole.advisor:
        return 'Class Adviser';
      case UserRole.student:
        return isClassRepresentative
            ? 'Class Representative ($gender CR - $classSection)'
            : 'Student';
    }
  }

  String get roleBadge {
    switch (role) {
      case UserRole.hod:
        return hodScope != null ? 'HOD ($hodScope)' : 'HOD';
      case UserRole.advisor:
        return 'Class Adviser';
      case UserRole.student:
        return isClassRepresentative
            ? '${gender == "Girl" ? "♀" : "♂"} $gender CR'
            : 'Student';
    }
  }
}
