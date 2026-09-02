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
  final String? hodScope; // e.g., "1st & 2nd Year" or "Overall & 3rd/4th Year"
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.college = 'V.S.B. Engineering College',
    this.classSection,
    this.hodScope,
    this.avatarUrl,
  });

  String get roleDisplayName {
    switch (role) {
      case UserRole.hod:
        return hodScope != null ? 'HOD ($hodScope)' : 'Head of Department';
      case UserRole.advisor:
        return 'Class Adviser';
      case UserRole.student:
        return 'Student';
    }
  }

  String get roleBadge {
    switch (role) {
      case UserRole.hod:
        return hodScope != null ? 'HOD ($hodScope)' : 'HOD';
      case UserRole.advisor:
        return 'Class Adviser';
      case UserRole.student:
        return 'Student';
    }
  }
}
