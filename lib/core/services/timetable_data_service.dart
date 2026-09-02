import '../models/timetable_model.dart';

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

  static SectionTimetable getSectionTimetable(String section) {
    return _sections[section.toUpperCase()] ?? _sectionA;
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
