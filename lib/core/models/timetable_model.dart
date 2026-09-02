class TimetableEntry {
  final int periodNumber;
  final String timeSlot;
  final String subjectCode;
  final String subjectName;
  final String subjectShort;
  final String facultyName;
  final String facultyShort;
  final bool isLab;

  const TimetableEntry({
    required this.periodNumber,
    required this.timeSlot,
    required this.subjectCode,
    required this.subjectName,
    required this.subjectShort,
    required this.facultyName,
    required this.facultyShort,
    this.isLab = false,
  });
}

class SubjectFacultyInfo {
  final String code;
  final String name;
  final String shortName;
  final String facultyName;
  final String facultyShort;
  final int periodsPerWeek;
  final bool isLab;

  const SubjectFacultyInfo({
    required this.code,
    required this.name,
    required this.shortName,
    required this.facultyName,
    required this.facultyShort,
    required this.periodsPerWeek,
    this.isLab = false,
  });
}

class SectionTimetable {
  final String section;
  final String year;
  final String semester;
  final String department;
  final String classRoom;
  final String classAdvisor;
  final String counselingDetails;
  final Map<String, List<TimetableEntry>> schedule; // 'Monday', 'Tuesday', ...
  final List<SubjectFacultyInfo> subjects;

  const SectionTimetable({
    required this.section,
    required this.year,
    required this.semester,
    required this.department,
    required this.classRoom,
    required this.classAdvisor,
    required this.counselingDetails,
    required this.schedule,
    required this.subjects,
  });
}
