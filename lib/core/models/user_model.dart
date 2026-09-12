/// Roles available in the PinkSlipReport system.
enum UserRole { hod, advisor, student }

/// Represents an authenticated user in the system.
/// NOTE: No credentials (passwords, tokens) are stored in this model.
/// All authentication is handled exclusively by Supabase Auth.
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String college;
  final String? classSection; // e.g., "II AI&DS - Section B"
  final String? customUsername;
  final String? batchYear; // e.g., "2025 BATCH"
  final String? hodScope; // e.g., "1st & 2nd Year" or "Overall & 3rd/4th Year"
  final String? avatarUrl;
  final bool isClassRepresentative;
  final String? rollNumber;
  final String? gender; // 'Boy' or 'Girl'
  final int? year; // 2, 3, 4
  final String? section; // 'A', 'B', 'C', 'D'

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.college = 'V.S.B. Engineering College',
    this.customUsername,
    this.classSection,
    this.batchYear,
    this.hodScope,
    this.avatarUrl,
    this.isClassRepresentative = false,
    this.rollNumber,
    this.gender,
    this.year,
    this.section,
  });

  /// Display-safe username derived from official handle or email (no credentials stored)
  String get username => customUsername ?? rollNumber ?? email.split('@').first;

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

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? department,
    String? college,
    String? customUsername,
    String? classSection,
    String? batchYear,
    String? hodScope,
    String? avatarUrl,
    bool? isClassRepresentative,
    String? rollNumber,
    String? gender,
    int? year,
    String? section,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      college: college ?? this.college,
      customUsername: customUsername ?? this.customUsername,
      classSection: classSection ?? this.classSection,
      batchYear: batchYear ?? this.batchYear,
      hodScope: hodScope ?? this.hodScope,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isClassRepresentative: isClassRepresentative ?? this.isClassRepresentative,
      rollNumber: rollNumber ?? this.rollNumber,
      gender: gender ?? this.gender,
      year: year ?? this.year,
      section: section ?? this.section,
    );
  }
}
