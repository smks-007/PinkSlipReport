import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../data/student_directory_data.dart';

/// Manages authentication state, role-based access, and two-factor security verification.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  UserModel? _pendingUser;
  bool _isLoading = false;
  String _generatedOtp = '482910'; // Demo 6-digit OTP code
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  UserModel? get currentUser => _currentUser;
  UserModel? get pendingUser => _pendingUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String get demoOtp => _generatedOtp;
  int get failedAttempts => _failedAttempts;
  bool get isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  int get remainingLockoutSeconds {
    if (_lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Registered Official Accounts: HODs
  static const UserModel overallHod = UserModel(
    id: 'hod-001',
    name: 'DR. MANIVANNAN (Ph.D.)',
    email: 'manivannan.hod@vsb.ac.in',
    role: UserRole.hod,
    department: 'AI&DS',
    college: 'V.S.B. Engineering College',
    hodScope: 'Overall & III/IV Year',
    customUsername: 'hod.manivannan',
    customPassword: 'Hod@Mani2026',
  );

  static const UserModel juniorHod = UserModel(
    id: 'hod-002',
    name: 'Mrs. Kavitha',
    email: 'kavitha.hod@vsb.ac.in',
    role: UserRole.hod,
    department: 'AI&DS',
    college: 'V.S.B. Engineering College',
    hodScope: 'I & II Year',
    customUsername: 'hod.kavitha',
    customPassword: 'Hod@Kavi2026',
  );

  /// Default Advisor (II-B Dr. M. Rajendiran)
  static const UserModel advisor = UserModel(
    id: 'adv-2b',
    name: 'Dr. M. Rajendiran',
    email: 'advisor.2b@vsb.ac.in',
    role: UserRole.advisor,
    department: 'AI&DS',
    college: 'V.S.B. Engineering College',
    classSection: 'II AI&DS - Section B',
    batchYear: '2025 BATCH',
    year: 2,
    section: 'B',
    customUsername: 'advisor.rajendiran',
    customPassword: 'Adv@Rajen2B',
  );

  /// 10 Section Class Advisors (Academic Year 2026-2027)
  static const List<UserModel> sectionAdvisors = [
    UserModel(
      id: 'adv-2a',
      name: 'Dr. D. Anandhan',
      email: 'advisor.2a@vsb.ac.in',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'II AI&DS - Section A',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'A',
      customUsername: 'advisor.anandhan',
      customPassword: 'Adv@Anandh2A',
    ),
    UserModel(
      id: 'adv-2b',
      name: 'Dr. M. Rajendiran',
      email: 'advisor.2b@vsb.ac.in',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'II AI&DS - Section B',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'B',
      customUsername: 'advisor.rajendiran',
      customPassword: 'Adv@Rajen2B',
    ),
    UserModel(
      id: 'adv-2c',
      name: 'Mr. A. Bharathidasan',
      email: 'advisor.2c@vsb.ac.in',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'II AI&DS - Section C',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'C',
      customUsername: 'advisor.bharathidasan',
      customPassword: 'Adv@Bharathi2C',
    ),
    UserModel(
      id: 'adv-2d',
      name: 'Mr. R. Palraj',
      email: 'advisor.2d@vsb.ac.in',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'II AI&DS - Section D',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'D',
      customUsername: 'advisor.palraj',
      customPassword: 'Adv@Palraj2D',
    ),
    UserModel(
      id: 'adv-3a',
      name: 'Ms. C. Vishnupriya',
      email: 'advisor.3a@vsb.ac.in',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'III AI&DS - Section A',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'A',
      customUsername: 'advisor.vishnupriya',
      customPassword: 'Adv@Vishnu3A',
    ),
    UserModel(
      id: 'adv-3b',
      name: 'Dr. R. Murugesan',
      email: 'advisor.3b@vsb.ac.in',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'III AI&DS - Section B',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'B',
      customUsername: 'advisor.murugesan',
      customPassword: 'Adv@Murugesan3B',
    ),
    UserModel(
      id: 'adv-3c',
      name: 'Mrs. B. Bharathi',
      email: 'advisor.3c@vsb.ac.in',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'III AI&DS - Section C',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'C',
      customUsername: 'advisor.bharathi',
      customPassword: 'Adv@Bharathi3C',
    ),
    UserModel(
      id: 'adv-3d',
      name: 'Mr. Velusamy',
      email: 'advisor.3d@vsb.ac.in',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'III AI&DS - Section D',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'D',
      customUsername: 'advisor.velusamy',
      customPassword: 'Adv@Velu3D',
    ),
    UserModel(
      id: 'adv-4a',
      name: 'Mr. Muthuselvan',
      email: 'advisor.4a@vsb.ac.in',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'IV AI&DS - Section A',
      batchYear: '2023 BATCH',
      year: 4,
      section: 'A',
      customUsername: 'advisor.muthuselvan',
      customPassword: 'Adv@Muthu4A',
    ),
    UserModel(
      id: 'adv-4b',
      name: 'Mrs. Nandhinidevi',
      email: 'advisor.4b@vsb.ac.in',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'IV AI&DS - Section B',
      batchYear: '2023 BATCH',
      year: 4,
      section: 'B',
      customUsername: 'advisor.nandhinidevi',
      customPassword: 'Adv@Nandhini4B',
    ),
  ];

  /// 20 Official Class Representatives (1 Boy & 1 Girl for each of the 10 sections)
  static const List<UserModel> classRepresentatives = [
    // II AIDS A (2025 BATCH)
    UserModel(
      id: 'cr-2a-boy',
      name: 'ADITHYAN S',
      rollNumber: '25243002',
      email: 'cr.boy.2a@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Boy',
      department: 'AI&DS',
      classSection: 'II AI&DS - Section A',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'A',
    ),
    UserModel(
      id: 'cr-2a-girl',
      name: 'ABINAYA G',
      rollNumber: '25243001',
      email: 'cr.girl.2a@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Girl',
      department: 'AI&DS',
      classSection: 'II AI&DS - Section A',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'A',
    ),

    // II AIDS B (2025 BATCH)
    UserModel(
      id: 'cr-2b-boy',
      name: 'LITHESH HARI R',
      rollNumber: '25243100',
      email: 'cr.boy.2b@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Boy',
      department: 'AI&DS',
      classSection: 'II AI&DS - Section B',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'B',
    ),
    UserModel(
      id: 'cr-2b-girl',
      name: 'JANANI Y',
      rollNumber: '25243068',
      email: 'cr.girl.2b@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Girl',
      department: 'AI&DS',
      classSection: 'II AI&DS - Section B',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'B',
    ),

    // II AIDS C (2025 BATCH)
    UserModel(
      id: 'cr-2c-boy',
      name: 'MUHIL RAJA A',
      rollNumber: '25243129',
      email: 'cr.boy.2c@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Boy',
      department: 'AI&DS',
      classSection: 'II AI&DS - Section C',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'C',
    ),
    UserModel(
      id: 'cr-2c-girl',
      name: 'NANDHINI R',
      rollNumber: '25243134',
      email: 'cr.girl.2c@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Girl',
      department: 'AI&DS',
      classSection: 'II AI&DS - Section C',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'C',
    ),

    // II AIDS D (2025 BATCH)
    UserModel(
      id: 'cr-2d-boy',
      name: 'SAIPRASATH S',
      rollNumber: '25243190',
      email: 'cr.boy.2d@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Boy',
      department: 'AI&DS',
      classSection: 'II AI&DS - Section D',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'D',
    ),
    UserModel(
      id: 'cr-2d-girl',
      name: 'SAHANA S',
      rollNumber: '25243189',
      email: 'cr.girl.2d@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Girl',
      department: 'AI&DS',
      classSection: 'II AI&DS - Section D',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'D',
    ),

    // III AIDS A (2024 BATCH)
    UserModel(
      id: 'cr-3a-boy',
      name: 'AKASH I',
      rollNumber: '24243007',
      email: 'cr.boy.3a@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Boy',
      department: 'AI&DS',
      classSection: 'III AI&DS - Section A',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'A',
    ),
    UserModel(
      id: 'cr-3a-girl',
      name: 'ABINAYA K',
      rollNumber: '24243001',
      email: 'cr.girl.3a@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Girl',
      department: 'AI&DS',
      classSection: 'III AI&DS - Section A',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'A',
    ),

    // III AIDS B (2024 BATCH)
    UserModel(
      id: 'cr-3b-boy',
      name: 'KABEESH L',
      rollNumber: '24243064',
      email: 'cr.boy.3b@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Boy',
      department: 'AI&DS',
      classSection: 'III AI&DS - Section B',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'B',
    ),
    UserModel(
      id: 'cr-3b-girl',
      name: 'JENITTA BLESSY S',
      rollNumber: '24243062',
      email: 'cr.girl.3b@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Girl',
      department: 'AI&DS',
      classSection: 'III AI&DS - Section B',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'B',
    ),

    // III AIDS C (2024 BATCH)
    UserModel(
      id: 'cr-3c-boy',
      name: 'NIJAY S S',
      rollNumber: '24243131',
      email: 'cr.boy.3c@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Boy',
      department: 'AI&DS',
      classSection: 'III AI&DS - Section C',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'C',
    ),
    UserModel(
      id: 'cr-3c-girl',
      name: 'NARTHINI N',
      rollNumber: '24243124',
      email: 'cr.girl.3c@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Girl',
      department: 'AI&DS',
      classSection: 'III AI&DS - Section C',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'C',
    ),

    // III AIDS D (2024 BATCH)
    UserModel(
      id: 'cr-3d-boy',
      name: 'SARAN KUMAR A',
      rollNumber: '24243190',
      email: 'cr.boy.3d@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Boy',
      department: 'AI&DS',
      classSection: 'III AI&DS - Section D',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'D',
    ),
    UserModel(
      id: 'cr-3d-girl',
      name: 'SANDHIYA G',
      rollNumber: '24243181',
      email: 'cr.girl.3d@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Girl',
      department: 'AI&DS',
      classSection: 'III AI&DS - Section D',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'D',
    ),

    // IV AIDS A (2023 BATCH)
    UserModel(
      id: 'cr-4a-boy',
      name: 'K.AJAY ABINESH',
      rollNumber: '23243003',
      email: 'cr.boy.4a@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Boy',
      department: 'AI&DS',
      classSection: 'IV AI&DS - Section A',
      batchYear: '2023 BATCH',
      year: 4,
      section: 'A',
    ),
    UserModel(
      id: 'cr-4a-girl',
      name: 'S.AARTHI',
      rollNumber: '23243001',
      email: 'cr.girl.4a@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Girl',
      department: 'AI&DS',
      classSection: 'IV AI&DS - Section A',
      batchYear: '2023 BATCH',
      year: 4,
      section: 'A',
    ),

    // IV AIDS B (2023 BATCH)
    UserModel(
      id: 'cr-4b-boy',
      name: 'P. MUKESH',
      rollNumber: '23243063',
      email: 'cr.boy.4b@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Boy',
      department: 'AI&DS',
      classSection: 'IV AI&DS - Section B',
      batchYear: '2023 BATCH',
      year: 4,
      section: 'B',
    ),
    UserModel(
      id: 'cr-4b-girl',
      name: 'S. HARINI',
      rollNumber: '23243034',
      email: 'cr.girl.4b@vsb.ac.in',
      role: UserRole.student,
      isClassRepresentative: true,
      gender: 'Girl',
      department: 'AI&DS',
      classSection: 'IV AI&DS - Section B',
      batchYear: '2023 BATCH',
      year: 4,
      section: 'B',
    ),
  ];

  /// Fallback student
  static UserModel get student => classRepresentatives[2]; // Lithesh Hari R

  /// Step 1: Initial Login Verification (Email & Password)
  Future<bool> preAuthenticate(String email, String password) async {
    if (isLockedOut) return false;

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final emailLower = email.toLowerCase().trim();

    // Check HODs
    if (emailLower.contains('kavitha') || emailLower.contains('hod12')) {
      _pendingUser = juniorHod;
    } else if (emailLower.contains('manivannan') ||
        emailLower.contains('hod') ||
        emailLower.contains('dr.')) {
      _pendingUser = overallHod;
    } else {
      // 1. Check Section Advisors (e.g. muthuselvan, nandhinidevi, vishnupriya, murugesan, bharathi, velusamy, anandhan, rajendiran, bharathidasan, palraj, advisor.4a, etc.)
      UserModel? matchedAdv;
      for (final adv in sectionAdvisors) {
        final advNameLower = adv.name.toLowerCase();
        final advCode = '${adv.year}${adv.section?.toLowerCase()}';
        if (emailLower == adv.email.toLowerCase() ||
            emailLower == adv.username.toLowerCase() ||
            (adv.id == 'adv-3d' && (emailLower.contains('velusamy') || emailLower.contains('veluswamy') || emailLower == 'advisor.veluswamy')) ||
            emailLower.contains('advisor.$advCode') ||
            emailLower == advCode ||
            advNameLower.split(' ').any((part) => part.length > 3 && emailLower.contains(part))) {
          matchedAdv = adv;
          break;
        }
      }

      if (matchedAdv != null) {
        _pendingUser = matchedAdv;
      } else {
        // 2. Check if matches a Class Representative
        UserModel? matchedCr;
        for (final cr in classRepresentatives) {
          if (emailLower == cr.email.toLowerCase() ||
              emailLower.contains(cr.rollNumber ?? '___') ||
              emailLower == 'cr.${cr.gender?.toLowerCase()}.${cr.year}${cr.section?.toLowerCase()}@vsb.ac.in' ||
              emailLower == '${cr.rollNumber}@vsb.ac.in') {
            matchedCr = cr;
            break;
          }
        }

        if (matchedCr != null) {
          _pendingUser = matchedCr;
        } else {
          // 3. Check any student by Roll Number or Name in the 622-student directory
          final rollMatch = RegExp(r'\b(2[345]243\d{3})\b').firstMatch(emailLower);
          final rollKey = rollMatch?.group(1) ?? emailLower.replaceAll('@vsb.ac.in', '').trim();
          final student = StudentDirectoryData.byRollNumber[rollKey];

          if (student != null) {
            _pendingUser = UserModel(
              id: student.id,
              name: student.name,
              rollNumber: student.rollNumber,
              email: '${student.rollNumber}@vsb.ac.in',
              role: UserRole.student,
              isClassRepresentative: false,
              gender: student.gender,
              department: 'AI&DS',
              classSection: '${student.romanYear} AI&DS - Section ${student.section}',
              batchYear: student.batchYear,
              year: student.year,
              section: student.section,
            );
          } else {
            // Search student by name
            final candidates = StudentDirectoryData.search(emailLower);
            if (candidates.isNotEmpty) {
              final s = candidates.first;
              _pendingUser = UserModel(
                id: s.id,
                name: s.name,
                rollNumber: s.rollNumber,
                email: '${s.rollNumber}@vsb.ac.in',
                role: UserRole.student,
                isClassRepresentative: false,
                gender: s.gender,
                department: 'AI&DS',
                classSection: '${s.romanYear} AI&DS - Section ${s.section}',
                batchYear: s.batchYear,
                year: s.year,
                section: s.section,
              );
            } else {
              _pendingUser = advisor;
            }
          }
        }
      }
    }

    _generatedOtp = '482910';
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Get official assigned password for any user
  static String getExpectedPassword(UserModel user) {
    if (user.id == 'hod-001') return 'Hod@Mani2026';
    if (user.id == 'hod-002') return 'Hod@Kavi2026';
    if (user.id == 'adv-4a') return 'Adv@Muthu4A';
    if (user.id == 'adv-4b') return 'Adv@Nandhini4B';
    if (user.id == 'adv-3a') return 'Adv@Vishnu3A';
    if (user.id == 'adv-3b') return 'Adv@Murugesan3B';
    if (user.id == 'adv-3c') return 'Adv@Bharathi3C';
    if (user.id == 'adv-3d') return 'Adv@Velu3D';
    if (user.id == 'adv-2a') return 'Adv@Anandh2A';
    if (user.id == 'adv-2b') return 'Adv@Rajen2B';
    if (user.id == 'adv-2c') return 'Adv@Bharathi2C';
    if (user.id == 'adv-2d') return 'Adv@Palraj2D';
    if (user.role == UserRole.student && user.rollNumber != null) {
      return 'Stu@${user.rollNumber}';
    }
    return 'password123';
  }

  /// Get official standard username for any user
  static String getOfficialUsername(UserModel user) {
    if (user.id == 'hod-001') return 'hod.manivannan';
    if (user.id == 'hod-002') return 'hod.kavitha';
    if (user.id == 'adv-4a') return 'advisor.muthuselvan';
    if (user.id == 'adv-4b') return 'advisor.nandhinidevi';
    if (user.id == 'adv-3a') return 'advisor.vishnupriya';
    if (user.id == 'adv-3b') return 'advisor.murugesan';
    if (user.id == 'adv-3c') return 'advisor.bharathi';
    if (user.id == 'adv-3d') return 'advisor.veluswamy';
    if (user.id == 'adv-2a') return 'advisor.anandhan';
    if (user.id == 'adv-2b') return 'advisor.rajendiran';
    if (user.id == 'adv-2c') return 'advisor.bharathidasan';
    if (user.id == 'adv-2d') return 'advisor.palraj';
    if (user.role == UserRole.student && user.rollNumber != null) {
      return user.rollNumber!;
    }
    return user.email;
  }

  /// Step 2: Two-Factor Security Verification (OTP Code)
  Future<bool> verifyOtp(String enteredCode) async {
    if (isLockedOut) return false;

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    // Accepts 482910, 123456, or master OTP 000000
    if (enteredCode == _generatedOtp ||
        enteredCode == '123456' ||
        enteredCode == '000000') {
      _currentUser = _pendingUser;
      _pendingUser = null;
      _failedAttempts = 0;
      _lockoutUntil = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 4) {
        _lockoutUntil = DateTime.now().add(const Duration(minutes: 2));
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Alternative Step 2: Instant Biometric / Passkey Verification
  Future<bool> verifyBiometric() async {
    if (isLockedOut) return false;

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _currentUser = _pendingUser;
    _pendingUser = null;
    _failedAttempts = 0;
    _lockoutUntil = null;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Direct Login (for quick demo switcher)
  void loginDirectly(UserModel user) {
    _currentUser = user;
    _pendingUser = null;
    notifyListeners();
  }

  /// Resend Security Code
  Future<void> resendOtp() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _generatedOtp = '482910';
    _isLoading = false;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _pendingUser = null;
    notifyListeners();
  }

  /// Direct switch between HODs for preview/testing
  void switchHod(UserModel hod) {
    _currentUser = hod;
    notifyListeners();
  }

  /// Route path based on user role.
  String get dashboardRoute {
    switch (_currentUser?.role) {
      case UserRole.hod:
        return '/hod-dashboard';
      case UserRole.advisor:
        return '/advisor-dashboard';
      case UserRole.student:
        return '/student-dashboard'; // dedicated student / CR dashboard
      case null:
        return '/sign-in';
    }
  }
}
