import '../models/timetable_model.dart';
import 'supabase_service.dart';

/// Complete Timetable repository for II Year (Semester III) AI&DS — Sections A, B, C, and D.
/// Source: V.S.B. Engineering College, Karur (Autonomous)
class TimetableDataService {
  TimetableDataService._();

  static const List<String> timeSlots = [
    '09:15 - 10:00', // P1
    '10:00 - 10:45', // P2
    '11:00 - 11:45', // P3
    '11:45 - 12:30', // P4
    '01:20 - 02:05', // P5
    '02:05 - 02:50', // P6
    '03:05 - 03:50', // P7
    '03:50 - 04:30', // P8
  ];

  static const List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static final Map<String, SectionTimetable> _sections = {
    'A': _sectionA,
    'B': _sectionB,
    'C': _sectionC,
    'D': _sectionD,
  };

  static List<String> get availableSections => ['A', 'B', 'C', 'D'];

  static List<String> getAvailableSectionsForYear(int year) {
    if (year == 4) return ['A', 'B'];
    return ['A', 'B', 'C', 'D'];
  }

  static SectionTimetable _createDefaultTimetable(String section, int year) {
    final roman = year == 1 ? 'I' : year == 2 ? 'II' : year == 3 ? 'III' : 'IV';
    final sem = year == 1 ? 'I' : year == 2 ? 'III' : year == 3 ? 'V' : 'VII';
    return SectionTimetable(
      section: section,
      year: '$roman Year',
      semester: '$sem Semester',
      department: 'Artificial Intelligence and Data Science',
      classRoom: 'MB $roman $section-Hall',
      classAdvisor: 'Section $section Advisor',
      counselingDetails: 'Counseling by Class Advisor',
      subjects: const [],
      schedule: {
        for (final day in days) day: [],
      },
    );
  }

  static SectionTimetable getSectionTimetable(String section, {int year = 2}) {
    final clean = section.toUpperCase().trim();
    final key = '$year-$clean';
    if (_sections.containsKey(key)) {
      return _sections[key]!;
    }
    if (_sections.containsKey(clean)) {
      return _sections[clean]!;
    }
    return _createDefaultTimetable(clean, year);
  }

  /// Asynchronously fetch timetable from Supabase public.timetables, updating cache with resilient fallback
  static Future<SectionTimetable> fetchTimetableFromDb(String section, {int year = 2}) async {
    final cleanSection = section.toUpperCase().trim();
    final defaultSection = getSectionTimetable(cleanSection, year: year);

    try {
      final roman = year == 1 ? 'I' : year == 2 ? 'II' : year == 3 ? 'III' : 'IV';
      var records = await SupabaseService().fetchTimetable('$roman-$cleanSection');
      if (records.isEmpty) {
        records = await SupabaseService().fetchTimetable('$year-$cleanSection');
      }
      if (records.isEmpty) {
        records = await SupabaseService().fetchTimetable(cleanSection);
      }

      if (records.isNotEmpty) {
        final Map<String, List<TimetableEntry>> schedule = {};
        final Map<String, SubjectFacultyInfo> subjectsMap = {};

        for (final r in records) {
          final day = r['day_of_week'] as String? ?? 'Monday';
          final periodNum = (r['period_number'] as int?) ?? 1;
          final timeSlot = r['time_slot'] as String? ??
              (periodNum <= timeSlots.length ? timeSlots[periodNum - 1] : '09:15 - 10:00');
          final subCode = r['subject_code'] as String? ?? '';
          final subName = r['subject_name'] as String? ?? '';
          final shortName = r['short_name'] as String? ?? subCode;
          final faculty = r['faculty_name'] as String? ?? '';
          final facultyShort = r['faculty_short'] as String? ?? '';
          final isLab = r['is_lab'] as bool? ?? false;

          final entry = TimetableEntry(
            periodNumber: periodNum,
            timeSlot: timeSlot,
            subjectCode: subCode,
            subjectName: subName,
            subjectShort: shortName,
            facultyName: faculty,
            facultyShort: facultyShort,
            isLab: isLab,
          );

          schedule.putIfAbsent(day, () => []).add(entry);

          if (!subjectsMap.containsKey(subCode) && subCode.isNotEmpty) {
            subjectsMap[subCode] = SubjectFacultyInfo(
              code: subCode,
              name: subName,
              shortName: shortName,
              facultyName: faculty,
              facultyShort: facultyShort,
              periodsPerWeek: 4,
              isLab: isLab,
            );
          }
        }

        for (final dayList in schedule.values) {
          dayList.sort((a, b) => a.periodNumber.compareTo(b.periodNumber));
        }

        final dynamicTimetable = SectionTimetable(
          section: cleanSection,
          year: defaultSection.year,
          semester: defaultSection.semester,
          department: defaultSection.department,
          classRoom: (records.first['room_number'] as String?) ?? defaultSection.classRoom,
          classAdvisor: defaultSection.classAdvisor,
          counselingDetails: defaultSection.counselingDetails,
          subjects: subjectsMap.values.toList(),
          schedule: schedule,
        );

        _sections[cleanSection] = dynamicTimetable;
        return dynamicTimetable;
      }
    } catch (_) {
      // Resilient fallback to static cache
    }

    return defaultSection;
  }

  // ════════════════════════════════════════════════════════════════════════
  // SECTION A
  // ════════════════════════════════════════════════════════════════════════
  static final SectionTimetable _sectionA = SectionTimetable(
    section: 'A',
    year: 'II Year',
    semester: 'III Semester',
    department: 'Artificial Intelligence and Data Science',
    classRoom: 'MB III A-201',
    classAdvisor: 'Dr. D. Anandan [DA]',
    counselingDetails: 'Wednesday 12:30 PM - 01:20 PM by Dr. D. Anandan',
    subjects: [
      const SubjectFacultyInfo(code: '23MAT302', name: 'Discrete Mathematics', shortName: 'DM', facultyName: 'Mr. D. Nagaraj', facultyShort: 'DN', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23ADT304R', name: 'Artificial Intelligence', shortName: 'AI', facultyName: 'Mr. A. Bharathidasan', facultyShort: 'AB', periodsPerWeek: 4),
      const SubjectFacultyInfo(code: '23ADT403R', name: 'Fundamentals of Data Science and Analytics', shortName: 'FDSA', facultyName: 'Dr. M. Rajendiran', facultyShort: 'MR', periodsPerWeek: 4),
      const SubjectFacultyInfo(code: '23ITT301R', name: 'Data Structures and Algorithms', shortName: 'DSA', facultyName: 'Mr. S. Sadeeshkumar', facultyShort: 'SS', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23CST302R', name: 'Object Oriented Programming', shortName: 'OOP', facultyName: 'Mr. V. Kumaresan', facultyShort: 'VK', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23CST403R', name: 'Database Management Systems', shortName: 'DBMS', facultyName: 'Ms. B. Bharathi', facultyShort: 'BB', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23ITP301R', name: 'Data Structures and Algorithms Laboratory', shortName: 'DSA LAB', facultyName: 'Mr. S. Sadeeshkumar', facultyShort: 'SS', periodsPerWeek: 4, isLab: true),
      const SubjectFacultyInfo(code: '23CSP302R', name: 'Object Oriented Programming Laboratory', shortName: 'OOP LAB', facultyName: 'Mr. V. Kumaresan', facultyShort: 'VK', periodsPerWeek: 6, isLab: true),
      const SubjectFacultyInfo(code: '23CSP402R', name: 'Database Management Systems Laboratory', shortName: 'DBMS LAB', facultyName: 'Mrs. B. Bharathi', facultyShort: 'BB', periodsPerWeek: 4, isLab: true),
      const SubjectFacultyInfo(code: 'COMM LAB', name: 'Communication Laboratory', shortName: 'COMM LAB', facultyName: 'Dr. D. Anandan & Dr. M. Rajendiran', facultyShort: 'DA / MR', periodsPerWeek: 6, isLab: true),
    ],
    schedule: {
      'Monday': [
        _p(1, 'OOP LAB', 'OOP LAB', 'Mr. V. Kumaresan', 'VK', isLab: true),
        _p(2, 'OOP LAB', 'OOP LAB', 'Mr. V. Kumaresan', 'VK', isLab: true),
        _p(3, 'OOP LAB', 'OOP LAB', 'Mr. V. Kumaresan', 'VK', isLab: true),
        _p(4, 'OOP LAB', 'OOP LAB', 'Mr. V. Kumaresan', 'VK', isLab: true),
        _p(5, 'OOP', 'Object Oriented Programming', 'Mr. V. Kumaresan', 'VK'),
        _p(6, 'DSA', 'Data Structures & Algorithms', 'Mr. S. Sadeeshkumar', 'SS'),
        _p(7, 'DBMS', 'Database Management Systems', 'Ms. B. Bharathi', 'BB'),
        _p(8, 'DSA', 'Data Structures & Algorithms', 'Mr. S. Sadeeshkumar', 'SS'),
      ],
      'Tuesday': [
        _p(1, 'DSA LAB', 'DSA Laboratory', 'Mr. S. Sadeeshkumar', 'SS', isLab: true),
        _p(2, 'DSA LAB', 'DSA Laboratory', 'Mr. S. Sadeeshkumar', 'SS', isLab: true),
        _p(3, 'DSA LAB', 'DSA Laboratory', 'Mr. S. Sadeeshkumar', 'SS', isLab: true),
        _p(4, 'DSA LAB', 'DSA Laboratory', 'Mr. S. Sadeeshkumar', 'SS', isLab: true),
        _p(5, 'DBMS', 'Database Management Systems', 'Ms. B. Bharathi', 'BB'),
        _p(6, 'AI', 'Artificial Intelligence', 'Mr. A. Bharathidasan', 'AB'),
        _p(7, 'DM', 'Discrete Mathematics', 'Mr. D. Nagaraj', 'DN'),
        _p(8, 'FDSA', 'Data Science & Analytics', 'Dr. M. Rajendiran', 'MR'),
      ],
      'Wednesday': [
        _p(1, 'COMM LAB', 'Communication Lab', 'Dr. D. Anandan', 'DA', isLab: true),
        _p(2, 'COMM LAB', 'Communication Lab', 'Dr. D. Anandan', 'DA', isLab: true),
        _p(3, 'FDSA', 'Data Science & Analytics', 'Dr. M. Rajendiran', 'MR'),
        _p(4, 'AI', 'Artificial Intelligence', 'Mr. A. Bharathidasan', 'AB'),
        _p(5, 'DBMS', 'Database Management Systems', 'Ms. B. Bharathi', 'BB'),
        _p(6, 'OOP', 'Object Oriented Programming', 'Mr. V. Kumaresan', 'VK'),
        _p(7, 'DM', 'Discrete Mathematics', 'Mr. D. Nagaraj', 'DN'),
        _p(8, 'DBMS', 'Database Management Systems', 'Ms. B. Bharathi', 'BB'),
      ],
      'Thursday': [
        _p(1, 'DBMS LAB', 'DBMS Laboratory', 'Mrs. B. Bharathi', 'BB', isLab: true),
        _p(2, 'DBMS LAB', 'DBMS Laboratory', 'Mrs. B. Bharathi', 'BB', isLab: true),
        _p(3, 'DBMS LAB', 'DBMS Laboratory', 'Mrs. B. Bharathi', 'BB', isLab: true),
        _p(4, 'DBMS LAB', 'DBMS Laboratory', 'Mrs. B. Bharathi', 'BB', isLab: true),
        _p(5, 'DM', 'Discrete Mathematics', 'Mr. D. Nagaraj', 'DN'),
        _p(6, 'DSA', 'Data Structures & Algorithms', 'Mr. S. Sadeeshkumar', 'SS'),
        _p(7, 'FDSA', 'Data Science & Analytics', 'Dr. M. Rajendiran', 'MR'),
        _p(8, 'AI', 'Artificial Intelligence', 'Mr. A. Bharathidasan', 'AB'),
      ],
      'Friday': [
        _p(1, 'OOP LAB', 'OOP Laboratory', 'Mr. V. Kumaresan', 'VK', isLab: true),
        _p(2, 'OOP LAB', 'OOP Laboratory', 'Mr. V. Kumaresan', 'VK', isLab: true),
        _p(3, 'COMM LAB', 'Communication Lab', 'Dr. D. Anandan', 'DA', isLab: true),
        _p(4, 'COMM LAB', 'Communication Lab', 'Dr. D. Anandan', 'DA', isLab: true),
        _p(5, 'AI', 'Artificial Intelligence', 'Mr. A. Bharathidasan', 'AB'),
        _p(6, 'OOP', 'Object Oriented Programming', 'Mr. V. Kumaresan', 'VK'),
        _p(7, 'DSA', 'Data Structures & Algorithms', 'Mr. S. Sadeeshkumar', 'SS'),
        _p(8, 'DM', 'Discrete Mathematics', 'Mr. D. Nagaraj', 'DN'),
      ],
      'Saturday': [
        _p(1, 'COMM LAB', 'Communication Lab', 'Dr. M. Rajendiran', 'MR', isLab: true),
        _p(2, 'COMM LAB', 'Communication Lab', 'Dr. M. Rajendiran', 'MR', isLab: true),
        _p(3, 'DM', 'Discrete Mathematics', 'Mr. D. Nagaraj', 'DN'),
        _p(4, 'OOP', 'Object Oriented Programming', 'Mr. V. Kumaresan', 'VK'),
        _p(5, 'OOP', 'Object Oriented Programming', 'Mr. V. Kumaresan', 'VK'),
        _p(6, 'DBMS', 'Database Management Systems', 'Ms. B. Bharathi', 'BB'),
        _p(7, 'FDSA', 'Data Science & Analytics', 'Dr. M. Rajendiran', 'MR'),
        _p(8, 'DSA', 'Data Structures & Algorithms', 'Mr. S. Sadeeshkumar', 'SS'),
      ],
    },
  );

  // ════════════════════════════════════════════════════════════════════════
  // SECTION B
  // ════════════════════════════════════════════════════════════════════════
  static final SectionTimetable _sectionB = SectionTimetable(
    section: 'B',
    year: 'II Year',
    semester: 'III Semester',
    department: 'Artificial Intelligence and Data Science',
    classRoom: 'MB III A-202',
    classAdvisor: 'Dr. M. Rajendiran [MR]',
    counselingDetails: 'Wednesday 12:30 PM - 01:20 PM by Dr. M. Rajendiran',
    subjects: [
      const SubjectFacultyInfo(code: '23MAT302', name: 'Discrete Mathematics', shortName: 'DM', facultyName: 'Mr. D. Nagaraj', facultyShort: 'DN', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23ADT304R', name: 'Artificial Intelligence', shortName: 'AI', facultyName: 'Mrs. V. Kavitha', facultyShort: 'VK', periodsPerWeek: 4),
      const SubjectFacultyInfo(code: '23ADT403R', name: 'Fundamentals of Data Science and Analytics', shortName: 'FDSA', facultyName: 'Dr. M. Rajendiran', facultyShort: 'MR', periodsPerWeek: 4),
      const SubjectFacultyInfo(code: '23ITT301R', name: 'Data Structures and Algorithms', shortName: 'DSA', facultyName: 'Mr. S. Sadeeshkumar', facultyShort: 'SS', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23CST302R', name: 'Object Oriented Programming', shortName: 'OOP', facultyName: 'Mrs. S. Nandhini Devi', facultyShort: 'SN', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23CST403R', name: 'Database Management Systems', shortName: 'DBMS', facultyName: 'Ms. B. Bharathi', facultyShort: 'BB', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23ITP301R', name: 'Data Structures and Algorithms Laboratory', shortName: 'DSA LAB', facultyName: 'Mr. S. Sadeeshkumar', facultyShort: 'SS', periodsPerWeek: 4, isLab: true),
      const SubjectFacultyInfo(code: '23CSP302R', name: 'Object Oriented Programming Laboratory', shortName: 'OOP LAB', facultyName: 'Ms. S. Muthulakshmi', facultyShort: 'SM', periodsPerWeek: 6, isLab: true),
      const SubjectFacultyInfo(code: '23CSP402R', name: 'Database Management Systems Laboratory', shortName: 'DBMS LAB', facultyName: 'Ms. B. Bharathi', facultyShort: 'BB', periodsPerWeek: 4, isLab: true),
      const SubjectFacultyInfo(code: 'COMM LAB', name: 'Communication Laboratory', shortName: 'COMM LAB', facultyName: 'Dr. M. Rajendiran & Mr. R. Palraj', facultyShort: 'MR / RP', periodsPerWeek: 6, isLab: true),
    ],
    schedule: {
      'Monday': [
        _p(1, 'FDSA', 'Data Science & Analytics', 'Dr. M. Rajendiran', 'MR'),
        _p(2, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(3, 'FDSA', 'Data Science & Analytics', 'Dr. M. Rajendiran', 'MR'),
        _p(4, 'AI', 'Artificial Intelligence', 'Mrs. V. Kavitha', 'VK'),
        _p(5, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(6, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(7, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(8, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
      ],
      'Tuesday': [
        _p(1, 'DBMS', 'Database Management Systems', 'Ms. B. Bharathi', 'BB'),
        _p(2, 'DM', 'Discrete Mathematics', 'Mr. D. Nagaraj', 'DN'),
        _p(3, 'DBMS', 'Database Management Systems', 'Ms. B. Bharathi', 'BB'),
        _p(4, 'AI', 'Artificial Intelligence', 'Mrs. V. Kavitha', 'VK'),
        _p(5, 'DSA LAB', 'DSA Laboratory', 'Mr. S. Sadeeshkumar', 'SS', isLab: true),
        _p(6, 'DSA LAB', 'DSA Laboratory', 'Mr. S. Sadeeshkumar', 'SS', isLab: true),
        _p(7, 'DSA LAB', 'DSA Laboratory', 'Mr. S. Sadeeshkumar', 'SS', isLab: true),
        _p(8, 'DSA LAB', 'DSA Laboratory', 'Mr. S. Sadeeshkumar', 'SS', isLab: true),
      ],
      'Wednesday': [
        _p(1, 'DBMS', 'Database Management Systems', 'Ms. B. Bharathi', 'BB'),
        _p(2, 'DM', 'Discrete Mathematics', 'Mr. D. Nagaraj', 'DN'),
        _p(3, 'DBMS', 'Database Management Systems', 'Ms. B. Bharathi', 'BB'),
        _p(4, 'DSA', 'Data Structures & Algorithms', 'Mr. S. Sadeeshkumar', 'SS'),
        _p(5, 'COMM LAB', 'Communication Lab', 'Dr. M. Rajendiran', 'MR', isLab: true),
        _p(6, 'COMM LAB', 'Communication Lab', 'Dr. M. Rajendiran', 'MR', isLab: true),
        _p(7, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(8, 'DM', 'Discrete Mathematics', 'Mr. D. Nagaraj', 'DN'),
      ],
      'Thursday': [
        _p(1, 'DSA', 'Data Structures & Algorithms', 'Mr. S. Sadeeshkumar', 'SS'),
        _p(2, 'DM', 'Discrete Mathematics', 'Mr. D. Nagaraj', 'DN'),
        _p(3, 'FDSA', 'Data Science & Analytics', 'Dr. M. Rajendiran', 'MR'),
        _p(4, 'DSA', 'Data Structures & Algorithms', 'Mr. S. Sadeeshkumar', 'SS'),
        _p(5, 'DBMS LAB', 'DBMS Laboratory', 'Ms. B. Bharathi', 'BB', isLab: true),
        _p(6, 'DBMS LAB', 'DBMS Laboratory', 'Ms. B. Bharathi', 'BB', isLab: true),
        _p(7, 'DBMS LAB', 'DBMS Laboratory', 'Ms. B. Bharathi', 'BB', isLab: true),
        _p(8, 'DBMS LAB', 'DBMS Laboratory', 'Ms. B. Bharathi', 'BB', isLab: true),
      ],
      'Friday': [
        _p(1, 'DSA', 'Data Structures & Algorithms', 'Mr. S. Sadeeshkumar', 'SS'),
        _p(2, 'FDSA', 'Data Science & Analytics', 'Dr. M. Rajendiran', 'MR'),
        _p(3, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(4, 'AI', 'Artificial Intelligence', 'Mrs. V. Kavitha', 'VK'),
        _p(5, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(6, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(7, 'COMM LAB', 'Communication Lab', 'Dr. M. Rajendiran', 'MR', isLab: true),
        _p(8, 'COMM LAB', 'Communication Lab', 'Dr. M. Rajendiran', 'MR', isLab: true),
      ],
      'Saturday': [
        _p(1, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(2, 'DM', 'Discrete Mathematics', 'Mr. D. Nagaraj', 'DN'),
        _p(3, 'AI', 'Artificial Intelligence', 'Mrs. V. Kavitha', 'VK'),
        _p(4, 'DSA', 'Data Structures & Algorithms', 'Mr. S. Sadeeshkumar', 'SS'),
        _p(5, 'COMM LAB', 'Communication Lab', 'Mr. R. Palraj', 'RP', isLab: true),
        _p(6, 'COMM LAB', 'Communication Lab', 'Mr. R. Palraj', 'RP', isLab: true),
        _p(7, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(8, 'DBMS', 'Database Management Systems', 'Ms. B. Bharathi', 'BB'),
      ],
    },
  );

  // ════════════════════════════════════════════════════════════════════════
  // SECTION C
  // ════════════════════════════════════════════════════════════════════════
  static final SectionTimetable _sectionC = SectionTimetable(
    section: 'C',
    year: 'II Year',
    semester: 'III Semester',
    department: 'Artificial Intelligence and Data Science',
    classRoom: 'MB III A-203',
    classAdvisor: 'Mr. A. Bharathidasan [AB]',
    counselingDetails: 'Wednesday 12:30 PM - 01:20 PM by Mr. A. Bharathidasan',
    subjects: [
      const SubjectFacultyInfo(code: '23MAT302', name: 'Discrete Mathematics', shortName: 'DM', facultyName: 'Mr. S. Syed Fazalullah', facultyShort: 'SS', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23ADT304R', name: 'Artificial Intelligence', shortName: 'AI', facultyName: 'Mr. A. Bharathidasan', facultyShort: 'AB', periodsPerWeek: 4),
      const SubjectFacultyInfo(code: '23ADT403R', name: 'Fundamentals of Data Science and Analytics', shortName: 'FDSA', facultyName: 'Dr. M. Rajendiran', facultyShort: 'MR', periodsPerWeek: 4),
      const SubjectFacultyInfo(code: '23ITT301R', name: 'Data Structures and Algorithms', shortName: 'DSA', facultyName: 'Mr. R. Sulaiman', facultyShort: 'RS', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23CST302R', name: 'Object Oriented Programming', shortName: 'OOP', facultyName: 'Mrs. S. Nandhini Devi', facultyShort: 'SN', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23CST403R', name: 'Database Management Systems', shortName: 'DBMS', facultyName: 'Mrs. B. Bharathi', facultyShort: 'BB', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23ITP301R', name: 'Data Structures and Algorithms Laboratory', shortName: 'DSA LAB', facultyName: 'Mr. R. Sulaiman', facultyShort: 'RS', periodsPerWeek: 4, isLab: true),
      const SubjectFacultyInfo(code: '23CSP302R', name: 'Object Oriented Programming Laboratory', shortName: 'OOP LAB', facultyName: 'Ms. S. Muthulakshmi', facultyShort: 'SM', periodsPerWeek: 6, isLab: true),
      const SubjectFacultyInfo(code: '23CSP402R', name: 'Database Management Systems Laboratory', shortName: 'DBMS LAB', facultyName: 'Mrs. B. Bharathi', facultyShort: 'BB', periodsPerWeek: 4, isLab: true),
      const SubjectFacultyInfo(code: 'COMM LAB', name: 'Communication Laboratory', shortName: 'COMM LAB', facultyName: 'Mr. A. Bharathidasan', facultyShort: 'AB', periodsPerWeek: 6, isLab: true),
    ],
    schedule: {
      'Monday': [
        _p(1, 'COMM LAB', 'Communication Lab', 'Mr. A. Bharathidasan', 'AB', isLab: true),
        _p(2, 'COMM LAB', 'Communication Lab', 'Mr. A. Bharathidasan', 'AB', isLab: true),
        _p(3, 'DBMS', 'Database Management Systems', 'Mrs. B. Bharathi', 'BB'),
        _p(4, 'DSA', 'Data Structures & Algorithms', 'Mr. R. Sulaiman', 'RS'),
        _p(5, 'DBMS', 'Database Management Systems', 'Mrs. B. Bharathi', 'BB'),
        _p(6, 'AI', 'Artificial Intelligence', 'Mr. A. Bharathidasan', 'AB'),
        _p(7, 'FDSA', 'Data Science & Analytics', 'Dr. M. Rajendiran', 'MR'),
        _p(8, 'DSA', 'Data Structures & Algorithms', 'Mr. R. Sulaiman', 'RS'),
      ],
      'Tuesday': [
        _p(1, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(2, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(3, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(4, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(5, 'DM', 'Discrete Mathematics', 'Mr. S. Syed Fazalullah', 'SS'),
        _p(6, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(7, 'DSA', 'Data Structures & Algorithms', 'Mr. R. Sulaiman', 'RS'),
        _p(8, 'DBMS', 'Database Management Systems', 'Mrs. B. Bharathi', 'BB'),
      ],
      'Wednesday': [
        _p(1, 'DSA LAB', 'DSA Laboratory', 'Mr. R. Sulaiman', 'RS', isLab: true),
        _p(2, 'DSA LAB', 'DSA Laboratory', 'Mr. R. Sulaiman', 'RS', isLab: true),
        _p(3, 'DSA LAB', 'DSA Laboratory', 'Mr. R. Sulaiman', 'RS', isLab: true),
        _p(4, 'DSA LAB', 'DSA Laboratory', 'Mr. R. Sulaiman', 'RS', isLab: true),
        _p(5, 'DM', 'Discrete Mathematics', 'Mr. S. Syed Fazalullah', 'SS'),
        _p(6, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(7, 'FDSA', 'Data Science & Analytics', 'Dr. M. Rajendiran', 'MR'),
        _p(8, 'AI', 'Artificial Intelligence', 'Mr. A. Bharathidasan', 'AB'),
      ],
      'Thursday': [
        _p(1, 'COMM LAB', 'Communication Lab', 'Mr. A. Bharathidasan', 'AB', isLab: true),
        _p(2, 'COMM LAB', 'Communication Lab', 'Mr. A. Bharathidasan', 'AB', isLab: true),
        _p(3, 'DSA', 'Data Structures & Algorithms', 'Mr. R. Sulaiman', 'RS'),
        _p(4, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(5, 'AI', 'Artificial Intelligence', 'Mr. A. Bharathidasan', 'AB'),
        _p(6, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(7, 'DM', 'Discrete Mathematics', 'Mr. S. Syed Fazalullah', 'SS'),
        _p(8, 'FDSA', 'Data Science & Analytics', 'Dr. M. Rajendiran', 'MR'),
      ],
      'Friday': [
        _p(1, 'DBMS LAB', 'DBMS Laboratory', 'Mrs. B. Bharathi', 'BB', isLab: true),
        _p(2, 'DBMS LAB', 'DBMS Laboratory', 'Mrs. B. Bharathi', 'BB', isLab: true),
        _p(3, 'DBMS LAB', 'DBMS Laboratory', 'Mrs. B. Bharathi', 'BB', isLab: true),
        _p(4, 'DBMS LAB', 'DBMS Laboratory', 'Mrs. B. Bharathi', 'BB', isLab: true),
        _p(5, 'DBMS', 'Database Management Systems', 'Mrs. B. Bharathi', 'BB'),
        _p(6, 'AI', 'Artificial Intelligence', 'Mr. A. Bharathidasan', 'AB'),
        _p(7, 'DM', 'Discrete Mathematics', 'Mr. S. Syed Fazalullah', 'SS'),
        _p(8, 'DM', 'Discrete Mathematics', 'Mr. S. Syed Fazalullah', 'SS'),
      ],
      'Saturday': [
        _p(1, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(2, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(3, 'COMM LAB', 'Communication Lab', 'Mr. A. Bharathidasan', 'AB', isLab: true),
        _p(4, 'COMM LAB', 'Communication Lab', 'Mr. A. Bharathidasan', 'AB', isLab: true),
        _p(5, 'DBMS', 'Database Management Systems', 'Mrs. B. Bharathi', 'BB'),
        _p(6, 'DSA', 'Data Structures & Algorithms', 'Mr. R. Sulaiman', 'RS'),
        _p(7, 'FDSA', 'Data Science & Analytics', 'Dr. M. Rajendiran', 'MR'),
        _p(8, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
      ],
    },
  );

  // ════════════════════════════════════════════════════════════════════════
  // SECTION D
  // ════════════════════════════════════════════════════════════════════════
  static final SectionTimetable _sectionD = SectionTimetable(
    section: 'D',
    year: 'II Year',
    semester: 'III Semester',
    department: 'Artificial Intelligence and Data Science',
    classRoom: 'MB III A-204',
    classAdvisor: 'Mr. R. Palraj [RP]',
    counselingDetails: 'Wednesday 12:30 PM - 01:20 PM by Mr. R. Palraj',
    subjects: [
      const SubjectFacultyInfo(code: '23MAT302', name: 'Discrete Mathematics', shortName: 'DM', facultyName: 'Mr. S. Syed Fazalullah', facultyShort: 'SS', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23ADT304R', name: 'Artificial Intelligence', shortName: 'AI', facultyName: 'Mr. A. Bharathidasan', facultyShort: 'AB', periodsPerWeek: 4),
      const SubjectFacultyInfo(code: '23ADT403R', name: 'Fundamentals of Data Science and Analytics', shortName: 'FDSA', facultyName: 'Mr. R. Palraj', facultyShort: 'RP', periodsPerWeek: 4),
      const SubjectFacultyInfo(code: '23ITT301R', name: 'Data Structures and Algorithms', shortName: 'DSA', facultyName: 'Mr. R. Sulaiman', facultyShort: 'RS', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23CST302R', name: 'Object Oriented Programming', shortName: 'OOP', facultyName: 'Mrs. S. Nandhini Devi', facultyShort: 'SN', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23CST403R', name: 'Database Management Systems', shortName: 'DBMS', facultyName: 'Mr. L. Karuppusamy', facultyShort: 'LK', periodsPerWeek: 5),
      const SubjectFacultyInfo(code: '23ITP301R', name: 'Data Structures and Algorithms Laboratory', shortName: 'DSA LAB', facultyName: 'Mr. R. Sulaiman', facultyShort: 'RS', periodsPerWeek: 4, isLab: true),
      const SubjectFacultyInfo(code: '23CSP302R', name: 'Object Oriented Programming Laboratory', shortName: 'OOP LAB', facultyName: 'Ms. S. Muthulakshmi', facultyShort: 'SM', periodsPerWeek: 6, isLab: true),
      const SubjectFacultyInfo(code: '23CSP402R', name: 'Database Management Systems Laboratory', shortName: 'DBMS LAB', facultyName: 'Mr. L. Karuppusamy', facultyShort: 'LK', periodsPerWeek: 4, isLab: true),
      const SubjectFacultyInfo(code: 'COMM LAB', name: 'Communication Laboratory', shortName: 'COMM LAB', facultyName: 'Dr. R. Murugesan', facultyShort: 'RM', periodsPerWeek: 6, isLab: true),
    ],
    schedule: {
      'Monday': [
        _p(1, 'DSA', 'Data Structures & Algorithms', 'Mr. R. Sulaiman', 'RS'),
        _p(2, 'DM', 'Discrete Mathematics', 'Mr. S. Syed Fazalullah', 'SS'),
        _p(3, 'DBMS', 'Database Management Systems', 'Mr. L. Karuppusamy', 'LK'),
        _p(4, 'AI', 'Artificial Intelligence', 'Mr. A. Bharathidasan', 'AB'),
        _p(5, 'COMM LAB', 'Communication Lab', 'Dr. R. Murugesan', 'RM', isLab: true),
        _p(6, 'COMM LAB', 'Communication Lab', 'Dr. R. Murugesan', 'RM', isLab: true),
        _p(7, 'DSA', 'Data Structures & Algorithms', 'Mr. R. Sulaiman', 'RS'),
        _p(8, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
      ],
      'Tuesday': [
        _p(1, 'AI', 'Artificial Intelligence', 'Mr. A. Bharathidasan', 'AB'),
        _p(2, 'DBMS', 'Database Management Systems', 'Mr. L. Karuppusamy', 'LK'),
        _p(3, 'DM', 'Discrete Mathematics', 'Mr. S. Syed Fazalullah', 'SS'),
        _p(4, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(5, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(6, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(7, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(8, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
      ],
      'Wednesday': [
        _p(1, 'DM', 'Discrete Mathematics', 'Mr. S. Syed Fazalullah', 'SS'),
        _p(2, 'FDSA', 'Data Science & Analytics', 'Mr. R. Palraj', 'RP'),
        _p(3, 'DM', 'Discrete Mathematics', 'Mr. S. Syed Fazalullah', 'SS'),
        _p(4, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(5, 'DSA LAB', 'DSA Laboratory', 'Mr. R. Sulaiman', 'RS', isLab: true),
        _p(6, 'DSA LAB', 'DSA Laboratory', 'Mr. R. Sulaiman', 'RS', isLab: true),
        _p(7, 'DSA LAB', 'DSA Laboratory', 'Mr. R. Sulaiman', 'RS', isLab: true),
        _p(8, 'DSA LAB', 'DSA Laboratory', 'Mr. R. Sulaiman', 'RS', isLab: true),
      ],
      'Thursday': [
        _p(1, 'FDSA', 'Data Science & Analytics', 'Mr. R. Palraj', 'RP'),
        _p(2, 'DSA', 'Data Structures & Algorithms', 'Mr. R. Sulaiman', 'RS'),
        _p(3, 'AI', 'Artificial Intelligence', 'Mr. A. Bharathidasan', 'AB'),
        _p(4, 'FDSA', 'Data Science & Analytics', 'Mr. R. Palraj', 'RP'),
        _p(5, 'COMM LAB', 'Communication Lab', 'Dr. R. Murugesan', 'RM', isLab: true),
        _p(6, 'COMM LAB', 'Communication Lab', 'Dr. R. Murugesan', 'RM', isLab: true),
        _p(7, 'DBMS', 'Database Management Systems', 'Mr. L. Karuppusamy', 'LK'),
        _p(8, 'DSA', 'Data Structures & Algorithms', 'Mr. R. Sulaiman', 'RS'),
      ],
      'Friday': [
        _p(1, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(2, 'DBMS', 'Database Management Systems', 'Mr. L. Karuppusamy', 'LK'),
        _p(3, 'FDSA', 'Data Science & Analytics', 'Mr. R. Palraj', 'RP'),
        _p(4, 'DBMS', 'Database Management Systems', 'Mr. L. Karuppusamy', 'LK'),
        _p(5, 'DBMS LAB', 'DBMS Laboratory', 'Mr. L. Karuppusamy', 'LK', isLab: true),
        _p(6, 'DBMS LAB', 'DBMS Laboratory', 'Mr. L. Karuppusamy', 'LK', isLab: true),
        _p(7, 'DBMS LAB', 'DBMS Laboratory', 'Mr. L. Karuppusamy', 'LK', isLab: true),
        _p(8, 'DBMS LAB', 'DBMS Laboratory', 'Mr. L. Karuppusamy', 'LK', isLab: true),
      ],
      'Saturday': [
        _p(1, 'AI', 'Artificial Intelligence', 'Mr. A. Bharathidasan', 'AB'),
        _p(2, 'DSA', 'Data Structures & Algorithms', 'Mr. R. Sulaiman', 'RS'),
        _p(3, 'DM', 'Discrete Mathematics', 'Mr. S. Syed Fazalullah', 'SS'),
        _p(4, 'OOP', 'Object Oriented Programming', 'Mrs. S. Nandhini Devi', 'SN'),
        _p(5, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(6, 'OOP LAB', 'OOP Laboratory', 'Ms. S. Muthulakshmi', 'SM', isLab: true),
        _p(7, 'COMM LAB', 'Communication Lab', 'Dr. R. Murugesan', 'RM', isLab: true),
        _p(8, 'COMM LAB', 'Communication Lab', 'Dr. R. Murugesan', 'RM', isLab: true),
      ],
    },
  );

  static TimetableEntry _p(
    int periodNumber,
    String shortName,
    String name,
    String faculty,
    String facultyCode, {
    bool isLab = false,
  }) {
    return TimetableEntry(
      periodNumber: periodNumber,
      timeSlot: timeSlots[periodNumber - 1],
      subjectCode: shortName,
      subjectName: name,
      subjectShort: shortName,
      facultyName: faculty,
      facultyShort: facultyCode,
      isLab: isLab,
    );
  }
}
