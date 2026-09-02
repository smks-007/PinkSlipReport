import 'package:flutter/material.dart';
import '../models/user_model.dart';

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

  /// Registered Official Accounts
  static const UserModel overallHod = UserModel(
    id: 'hod-001',
    name: 'Dr. Manivannan',
    email: 'manivannan.hod@vsb.ac.in',
    role: UserRole.hod,
    department: 'AI&DS',
    college: 'V.S.B. Engineering College',
    hodScope: 'Overall & III/IV Year',
  );

  static const UserModel juniorHod = UserModel(
    id: 'hod-002',
    name: 'Mrs. Kavitha',
    email: 'kavitha.hod@vsb.ac.in',
    role: UserRole.hod,
    department: 'AI&DS',
    college: 'V.S.B. Engineering College',
    hodScope: 'I & II Year',
  );

  static const UserModel advisor = UserModel(
    id: 'adv-001',
    name: 'Mrs. S. Muthulakshmi',
    email: 'muthulakshmi.aids@vsb.ac.in',
    role: UserRole.advisor,
    department: 'AI&DS',
    college: 'V.S.B. Engineering College',
    classSection: 'II AI&DS - Section B',
  );

  static const UserModel student = UserModel(
    id: 'stu-001',
    name: 'Lithesh Hari R',
    email: '25243100@vsb.ac.in',
    role: UserRole.student,
    department: 'AI&DS',
    college: 'V.S.B. Engineering College',
    classSection: 'II AI&DS - Section B',
  );

  /// Step 1: Initial Login Verification (Email & Password)
  Future<bool> preAuthenticate(String email, String password) async {
    if (isLockedOut) return false;

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    final emailLower = email.toLowerCase().trim();

    if (emailLower.contains('kavitha') || emailLower.contains('hod12')) {
      _pendingUser = juniorHod;
    } else if (emailLower.contains('manivannan') ||
        emailLower.contains('hod') ||
        emailLower.contains('dr')) {
      _pendingUser = overallHod;
    } else if (emailLower.contains('student') || emailLower.contains('25243')) {
      _pendingUser = student;
    } else {
      _pendingUser = advisor;
    }

    _generatedOtp = '482910';
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Step 2: Two-Factor Security Verification (OTP Code)
  Future<bool> verifyOtp(String enteredCode) async {
    if (isLockedOut) return false;

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

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

    await Future.delayed(const Duration(milliseconds: 1000));

    _currentUser = _pendingUser;
    _pendingUser = null;
    _failedAttempts = 0;
    _lockoutUntil = null;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Resend Security Code
  Future<void> resendOtp() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
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
        return '/advisor-dashboard'; // fallback to advisor/student view
      case null:
        return '/sign-in';
    }
  }
}
