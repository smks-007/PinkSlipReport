import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';
import 'mock_data_service.dart';

/// Manages authentication state and role-based access.
/// All authentication is handled exclusively through Supabase Auth.
/// No credentials are stored client-side.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  bool _isLoading = false;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  /// Session timeout duration (15 minutes of inactivity)
  static const Duration sessionTimeout = Duration(minutes: 15);
  DateTime? _lastActivity;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && !isSessionExpired;
  bool get isLoading => _isLoading;
  int get failedAttempts => _failedAttempts;
  bool get isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  /// Check if the current session has timed out
  bool get isSessionExpired {
    if (_lastActivity == null || _currentUser == null) return false;
    return DateTime.now().difference(_lastActivity!) > sessionTimeout;
  }

  /// Real cryptographic JWT Bearer Token from active Supabase session
  String? get jwtToken => SupabaseService().currentJwtToken;

  int get remainingLockoutSeconds {
    if (_lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Update activity timestamp (call on user interaction)
  void recordActivity() {
    _lastActivity = DateTime.now();
  }

  /// ─── User Directory (display metadata only — NO credentials) ───

  /// HOD accounts (metadata only for display — auth via Supabase)
  static const UserModel overallHod = UserModel(
    id: 'hod-001',
    name: 'DR. MANIVANNAN (Ph.D.)',
    email: 'manivannan.hod@vsb.ac.in',
    customUsername: 'hod.manivannan',
    role: UserRole.hod,
    department: 'AI&DS',
    college: 'V.S.B. Engineering College',
    hodScope: 'Overall & III/IV Year',
  );

  static const UserModel juniorHod = UserModel(
    id: 'hod-002',
    name: 'Mrs. Kavitha',
    email: 'kavitha.hod@vsb.ac.in',
    customUsername: 'hod.kavitha',
    role: UserRole.hod,
    department: 'AI&DS',
    college: 'V.S.B. Engineering College',
    hodScope: 'I & II Year',
  );

  /// 10 Section Class Advisors (metadata only — NO passwords)
  static const List<UserModel> sectionAdvisors = [
    UserModel(
      id: 'adv-2a',
      name: 'Dr. D. Anandhan',
      email: 'advisor.2a@vsb.ac.in',
      customUsername: 'advisor.anandhan',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'II AI&DS - Section A',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'A',
    ),
    UserModel(
      id: 'adv-2b',
      name: 'Dr. M. Rajendiran',
      email: 'advisor.2b@vsb.ac.in',
      customUsername: 'advisor.rajendiran',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'II AI&DS - Section B',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'B',
    ),
    UserModel(
      id: 'adv-2c',
      name: 'Mr. A. Bharathidasan',
      email: 'advisor.2c@vsb.ac.in',
      customUsername: 'advisor.bharathidasan',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'II AI&DS - Section C',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'C',
    ),
    UserModel(
      id: 'adv-2d',
      name: 'Mr. R. Palraj',
      email: 'advisor.2d@vsb.ac.in',
      customUsername: 'advisor.palraj',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'II AI&DS - Section D',
      batchYear: '2025 BATCH',
      year: 2,
      section: 'D',
    ),
    UserModel(
      id: 'adv-3a',
      name: 'Ms. C. Vishnupriya',
      email: 'advisor.3a@vsb.ac.in',
      customUsername: 'advisor.vishnupriya',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'III AI&DS - Section A',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'A',
    ),
    UserModel(
      id: 'adv-3b',
      name: 'Dr. R. Murugesan',
      email: 'advisor.3b@vsb.ac.in',
      customUsername: 'advisor.murugesan',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'III AI&DS - Section B',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'B',
    ),
    UserModel(
      id: 'adv-3c',
      name: 'Mrs. B. Bharathi',
      email: 'advisor.3c@vsb.ac.in',
      customUsername: 'advisor.bharathi',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'III AI&DS - Section C',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'C',
    ),
    UserModel(
      id: 'adv-3d',
      name: 'Mr. Velusamy',
      email: 'advisor.3d@vsb.ac.in',
      customUsername: 'advisor.velusamy',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'III AI&DS - Section D',
      batchYear: '2024 BATCH',
      year: 3,
      section: 'D',
    ),
    UserModel(
      id: 'adv-4a',
      name: 'Mr. Muthuselvan',
      email: 'advisor.4a@vsb.ac.in',
      customUsername: 'advisor.muthuselvan',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'IV AI&DS - Section A',
      batchYear: '2023 BATCH',
      year: 4,
      section: 'A',
    ),
    UserModel(
      id: 'adv-4b',
      name: 'Mrs. Nandhinidevi',
      email: 'advisor.4b@vsb.ac.in',
      customUsername: 'advisor.nandhinidevi',
      role: UserRole.advisor,
      department: 'AI&DS',
      classSection: 'IV AI&DS - Section B',
      batchYear: '2023 BATCH',
      year: 4,
      section: 'B',
    ),
  ];

  /// 20 Official Class Representatives (metadata only — NO passwords)
  static const List<UserModel> classRepresentatives = [
    // II AIDS A (2025 BATCH)
    UserModel(
      id: 'cr-2a-boy', name: 'ADITHYAN S', rollNumber: '25243002',
      email: 'cr.boy.2a@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Boy', department: 'AI&DS',
      classSection: 'II AI&DS - Section A', batchYear: '2025 BATCH', year: 2, section: 'A',
    ),
    UserModel(
      id: 'cr-2a-girl', name: 'ABINAYA G', rollNumber: '25243001',
      email: 'cr.girl.2a@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Girl', department: 'AI&DS',
      classSection: 'II AI&DS - Section A', batchYear: '2025 BATCH', year: 2, section: 'A',
    ),
    // II AIDS B (2025 BATCH)
    UserModel(
      id: 'cr-2b-boy', name: 'LITHESH HARI R', rollNumber: '25243100',
      email: 'cr.boy.2b@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Boy', department: 'AI&DS',
      classSection: 'II AI&DS - Section B', batchYear: '2025 BATCH', year: 2, section: 'B',
    ),
    UserModel(
      id: 'cr-2b-girl', name: 'JANANI Y', rollNumber: '25243068',
      email: 'cr.girl.2b@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Girl', department: 'AI&DS',
      classSection: 'II AI&DS - Section B', batchYear: '2025 BATCH', year: 2, section: 'B',
    ),
    // II AIDS C (2025 BATCH)
    UserModel(
      id: 'cr-2c-boy', name: 'MUHIL RAJA A', rollNumber: '25243129',
      email: 'cr.boy.2c@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Boy', department: 'AI&DS',
      classSection: 'II AI&DS - Section C', batchYear: '2025 BATCH', year: 2, section: 'C',
    ),
    UserModel(
      id: 'cr-2c-girl', name: 'NANDHINI R', rollNumber: '25243134',
      email: 'cr.girl.2c@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Girl', department: 'AI&DS',
      classSection: 'II AI&DS - Section C', batchYear: '2025 BATCH', year: 2, section: 'C',
    ),
    // II AIDS D (2025 BATCH)
    UserModel(
      id: 'cr-2d-boy', name: 'SAIPRASATH S', rollNumber: '25243190',
      email: 'cr.boy.2d@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Boy', department: 'AI&DS',
      classSection: 'II AI&DS - Section D', batchYear: '2025 BATCH', year: 2, section: 'D',
    ),
    UserModel(
      id: 'cr-2d-girl', name: 'SAHANA S', rollNumber: '25243189',
      email: 'cr.girl.2d@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Girl', department: 'AI&DS',
      classSection: 'II AI&DS - Section D', batchYear: '2025 BATCH', year: 2, section: 'D',
    ),
    // III AIDS A (2024 BATCH)
    UserModel(
      id: 'cr-3a-boy', name: 'AKASH I', rollNumber: '24243007',
      email: 'cr.boy.3a@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Boy', department: 'AI&DS',
      classSection: 'III AI&DS - Section A', batchYear: '2024 BATCH', year: 3, section: 'A',
    ),
    UserModel(
      id: 'cr-3a-girl', name: 'ABINAYA K', rollNumber: '24243001',
      email: 'cr.girl.3a@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Girl', department: 'AI&DS',
      classSection: 'III AI&DS - Section A', batchYear: '2024 BATCH', year: 3, section: 'A',
    ),
    // III AIDS B (2024 BATCH)
    UserModel(
      id: 'cr-3b-boy', name: 'KABEESH L', rollNumber: '24243064',
      email: 'cr.boy.3b@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Boy', department: 'AI&DS',
      classSection: 'III AI&DS - Section B', batchYear: '2024 BATCH', year: 3, section: 'B',
    ),
    UserModel(
      id: 'cr-3b-girl', name: 'JENITTA BLESSY S', rollNumber: '24243062',
      email: 'cr.girl.3b@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Girl', department: 'AI&DS',
      classSection: 'III AI&DS - Section B', batchYear: '2024 BATCH', year: 3, section: 'B',
    ),
    // III AIDS C (2024 BATCH)
    UserModel(
      id: 'cr-3c-boy', name: 'NIJAY S S', rollNumber: '24243131',
      email: 'cr.boy.3c@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Boy', department: 'AI&DS',
      classSection: 'III AI&DS - Section C', batchYear: '2024 BATCH', year: 3, section: 'C',
    ),
    UserModel(
      id: 'cr-3c-girl', name: 'NARTHINI N', rollNumber: '24243124',
      email: 'cr.girl.3c@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Girl', department: 'AI&DS',
      classSection: 'III AI&DS - Section C', batchYear: '2024 BATCH', year: 3, section: 'C',
    ),
    // III AIDS D (2024 BATCH)
    UserModel(
      id: 'cr-3d-boy', name: 'SARAN KUMAR A', rollNumber: '24243190',
      email: 'cr.boy.3d@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Boy', department: 'AI&DS',
      classSection: 'III AI&DS - Section D', batchYear: '2024 BATCH', year: 3, section: 'D',
    ),
    UserModel(
      id: 'cr-3d-girl', name: 'SANDHIYA G', rollNumber: '24243181',
      email: 'cr.girl.3d@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Girl', department: 'AI&DS',
      classSection: 'III AI&DS - Section D', batchYear: '2024 BATCH', year: 3, section: 'D',
    ),
    // IV AIDS A (2023 BATCH)
    UserModel(
      id: 'cr-4a-boy', name: 'K.AJAY ABINESH', rollNumber: '23243003',
      email: 'cr.boy.4a@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Boy', department: 'AI&DS',
      classSection: 'IV AI&DS - Section A', batchYear: '2023 BATCH', year: 4, section: 'A',
    ),
    UserModel(
      id: 'cr-4a-girl', name: 'S.AARTHI', rollNumber: '23243001',
      email: 'cr.girl.4a@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Girl', department: 'AI&DS',
      classSection: 'IV AI&DS - Section A', batchYear: '2023 BATCH', year: 4, section: 'A',
    ),
    // IV AIDS B (2023 BATCH)
    UserModel(
      id: 'cr-4b-boy', name: 'P. MUKESH', rollNumber: '23243063',
      email: 'cr.boy.4b@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Boy', department: 'AI&DS',
      classSection: 'IV AI&DS - Section B', batchYear: '2023 BATCH', year: 4, section: 'B',
    ),
    UserModel(
      id: 'cr-4b-girl', name: 'S. HARINI', rollNumber: '23243034',
      email: 'cr.girl.4b@vsb.ac.in', role: UserRole.student,
      isClassRepresentative: true, gender: 'Girl', department: 'AI&DS',
      classSection: 'IV AI&DS - Section B', batchYear: '2023 BATCH', year: 4, section: 'B',
    ),
  ];

  /// ─── Authentication Methods (Supabase-only) ───

  /// Sign in using Supabase Auth exclusively.
  /// Returns error message on failure, null on success.
  Future<String?> signIn(String identifier, String password) async {
    if (isLockedOut) {
      return 'Security lock active. Please wait ${remainingLockoutSeconds}s before retrying.';
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (!SupabaseService().isInitialized) {
        _isLoading = false;
        notifyListeners();
        return 'Unable to connect to authentication server. Please check your internet connection.';
      }

      final supabaseUser = await SupabaseService().signInWithSupabase(
        identifier: identifier,
        password: password,
      );

      if (supabaseUser != null) {
        _currentUser = supabaseUser;
        _failedAttempts = 0;
        _lockoutUntil = null;
        _lastActivity = DateTime.now();

        // Trigger real-time sync with Supabase Cloud using authenticated JWT
        try {
          await MockDataService.syncFromSupabase();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Post-login sync warning: $e');
          }
        }

        _isLoading = false;
        notifyListeners();
        return null; // Success
      } else {
        _handleFailedAttempt();
        return 'Invalid credentials. Please check your username and password.';
      }
    } catch (e) {
      _handleFailedAttempt();
      final msg = e.toString();
      if (msg.contains('Invalid login credentials')) {
        return 'Invalid email or password. Please try again.';
      } else if (msg.contains('Email not confirmed')) {
        return 'Your account has not been activated. Contact the department admin.';
      }
      return 'Authentication failed. Please check your connection and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _lockoutUntil = DateTime.now().add(const Duration(minutes: 5));
      if (kDebugMode) {
        debugPrint('🔒 Account locked after $_failedAttempts failed attempts.');
      }
    }
  }

  /// Sign out and clear all session state
  Future<void> logout() async {
    await SupabaseService().signOut();
    _currentUser = null;
    _lastActivity = null;
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
        return '/student-dashboard';
      case null:
        return '/sign-in';
    }
  }

  /// Check if the user should be forced to re-authenticate
  bool checkSessionValidity() {
    if (_currentUser == null) return false;
    if (isSessionExpired) {
      _currentUser = null;
      _lastActivity = null;
      notifyListeners();
      return false;
    }
    recordActivity();
    return true;
  }

  /// Test-only method to set the mock user context
  @visibleForTesting
  void setMockUser(UserModel? user) {
    _currentUser = user;
    _lastActivity = DateTime.now();
    notifyListeners();
  }

  /// Backward-compatible alias for unit and widget tests
  @visibleForTesting
  void loginDirectly(UserModel user) {
    setMockUser(user);
  }
}
