/// The personal details and aggregate attendance exposed to a student.
class StudentDashboardData {
  const StudentDashboardData({
    required this.authId,
    required this.name,
    required this.email,
    required this.rollNumber,
    required this.registerNumber,
    required this.section,
    required this.department,
    required this.attendancePercentage,
  });

  final String authId;
  final String name;
  final String email;
  final String rollNumber;
  final String registerNumber;
  final String section;
  final String department;
  final double? attendancePercentage;

  factory StudentDashboardData.fromJson(Map<String, dynamic> json) {
    final value = json['attendance_percentage'];
    final percentage = value == null ? null : double.parse(value.toString());
    if (percentage != null &&
        (!percentage.isFinite || percentage < 0 || percentage > 100)) {
      throw const FormatException('Invalid attendance percentage');
    }
    return StudentDashboardData(
      authId: json['auth_id'] as String,
      name: json['full_name'] as String,
      email: json['email'] as String,
      rollNumber: json['roll_number'] as String,
      registerNumber: json['register_number'] as String,
      section: json['section_id'] as String? ?? 'Not assigned',
      department: json['department'] as String? ?? 'Not assigned',
      attendancePercentage: percentage,
    );
  }
}
