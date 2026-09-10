import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';
import '../models/user_model.dart';

/// Central Supabase Integration Service for PinkSlipReport
/// Handles Supabase Client initialization, JWT Auth, and PostgreSQL Database Sync.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  /// Current Supabase Auth Session
  Session? get currentSession => client?.auth.currentSession;
  
  /// Real signed JWT Bearer token issued by Supabase
  String? get currentJwtToken => currentSession?.accessToken;

  /// Initialize Supabase Flutter SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      if (!SupabaseConfig.isConfigured) {
        if (kDebugMode) {
          debugPrint('⚠️ Supabase not configured with valid credentials.');
        }
        return;
      }

      await Supabase.initialize(
        url: SupabaseConfig.projectUrl,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('✅ Supabase connected successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase initialization failed: $e');
      }
      _isInitialized = false;
    }
  }

  /// Resolve any identifier (roll number, username, or email) to official email
  String resolveEmail(String input) {
    final clean = input.trim().toLowerCase();

    // 1. HOD mapping (handles 'manivannan', 'manivanan' typo, 'hod.manivannan', 'hod.manivanan@vsb.ac.in', etc.)
    if (clean.contains('manivan') || clean == 'hod' || clean.startsWith('hod.mani')) {
      return 'manivannan.hod@vsb.ac.in';
    }
    if (clean.contains('kavitha') || clean == 'hod12' || clean.startsWith('hod.kavi')) {
      return 'kavitha.hod@vsb.ac.in';
    }

    // 2. Section Advisor mapping (handles both username handles and section abbreviations)
    const advisorEmailMap = {
      'advisor.anandhan': 'advisor.2a@vsb.ac.in',
      'advisor.2a': 'advisor.2a@vsb.ac.in',
      'advisor.rajendiran': 'advisor.2b@vsb.ac.in',
      'advisor.2b': 'advisor.2b@vsb.ac.in',
      'advisor.bharathidasan': 'advisor.2c@vsb.ac.in',
      'advisor.2c': 'advisor.2c@vsb.ac.in',
      'advisor.palraj': 'advisor.2d@vsb.ac.in',
      'advisor.2d': 'advisor.2d@vsb.ac.in',
      'advisor.vishnupriya': 'advisor.3a@vsb.ac.in',
      'advisor.3a': 'advisor.3a@vsb.ac.in',
      'advisor.murugesan': 'advisor.3b@vsb.ac.in',
      'advisor.3b': 'advisor.3b@vsb.ac.in',
      'advisor.bharathi': 'advisor.3c@vsb.ac.in',
      'advisor.3c': 'advisor.3c@vsb.ac.in',
      'advisor.velusamy': 'advisor.3d@vsb.ac.in',
      'advisor.3d': 'advisor.3d@vsb.ac.in',
      'advisor.muthuselvan': 'advisor.4a@vsb.ac.in',
      'advisor.4a': 'advisor.4a@vsb.ac.in',
      'advisor.nandhinidevi': 'advisor.4b@vsb.ac.in',
      'advisor.4b': 'advisor.4b@vsb.ac.in',
    };

    final prefix = clean.split('@').first;
    if (advisorEmailMap.containsKey(clean)) {
      return advisorEmailMap[clean]!;
    }
    if (advisorEmailMap.containsKey(prefix)) {
      return advisorEmailMap[prefix]!;
    }

    // 3. If already valid email
    if (clean.contains('@')) return clean;

    // 4. Student Roll Number match (e.g. 25243100)
    final rollMatch = RegExp(r'\b(2[345]243\d{3})\b').firstMatch(clean);
    if (rollMatch != null) {
      return '${rollMatch.group(1)}@student.smartcampus.edu';
    }

    return '$clean@vsb.ac.in';
  }

  /// Authenticate against Supabase Cloud Auth
  Future<UserModel?> signInWithSupabase({
    required String identifier,
    required String password,
  }) async {
    if (!_isInitialized || client == null) return null;

    final email = resolveEmail(identifier);
    if (kDebugMode) {
      debugPrint('🔐 Attempting Supabase Auth for: $email');
    }

    final authResponse = await client!.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) return null;

    if (kDebugMode) {
      debugPrint('🎉 Supabase Auth successful for: ${user.email}');
    }

    // Extract profile metadata
    final metadata = user.userMetadata ?? {};
    final rawRole = (metadata['role'] as String?)?.toUpperCase() ?? '';

    UserRole userRole;
    if (rawRole == 'HOD' || email.contains('hod') || email.contains('manivannan')) {
      userRole = UserRole.hod;
    } else if (rawRole == 'ADVISOR' || email.contains('advisor')) {
      userRole = UserRole.advisor;
    } else {
      userRole = UserRole.student;
    }

    return UserModel(
      id: user.id,
      name: metadata['full_name'] as String? ?? metadata['name'] as String? ?? email.split('@').first,
      email: user.email ?? email,
      role: userRole,
      department: metadata['department'] as String? ?? 'AI&DS',
      college: metadata['college'] as String? ?? 'V.S.B. Engineering College',
      classSection: metadata['class_section'] as String?,
      batchYear: metadata['batch_year'] as String?,
      rollNumber: metadata['roll_number'] as String?,
      year: metadata['year'] as int?,
      section: metadata['section'] as String?,
    );
  }

  /// Send password reset email via Supabase Auth
  Future<void> resetPassword(String email) async {
    if (!_isInitialized || client == null) {
      throw Exception('Supabase is not initialized.');
    }
    await client!.auth.resetPasswordForEmail(email);
  }

  /// Sign Out of Supabase
  Future<void> signOut() async {
    try {
      if (_isInitialized && client != null) {
        await client!.auth.signOut();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase sign out error: $e');
      }
    }
  }

  // ──────────────────── SUPABASE DATABASE SYNC ────────────────────

  /// Fetch all active students from Supabase database (tables: students & users)
  Future<List<Map<String, dynamic>>> fetchStudents() async {
    if (!_isInitialized || client == null) return [];
    try {
      final res = await client!
          .from('students')
          .select('student_id, roll_number, register_number, section_id, guardian_name, guardian_contact, leaves_taken_ytd, users!inner(full_name, email, phone_number, is_active)')
          .order('roll_number');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchStudents error: $e');
      }
      return [];
    }
  }

  /// Fetch all departmental sections from Supabase
  Future<List<Map<String, dynamic>>> fetchSections() async {
    if (!_isInitialized || client == null) return [];
    try {
      final res = await client!.from('sections').select().order('section_id');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchSections error: $e');
      }
      return [];
    }
  }

  /// Query live daily attendance from Supabase table 'daily_attendance'
  Future<List<Map<String, dynamic>>> fetchLiveAttendance(DateTime date) async {
    if (!_isInitialized || client == null) return [];
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final res = await client!
          .from('daily_attendance')
          .select()
          .eq('attendance_date', dateStr);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchLiveAttendance error: $e');
      }
      return [];
    }
  }

  /// Record Attendance in Supabase (with audit trail via marked_by)
  Future<bool> recordAttendance({
    required int studentId,
    required DateTime date,
    required bool isPresent,
    int markedByUserId = 1,
    String? leaveType,
    String punchMethod = 'MANUAL_OVERRIDE',
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await client!.from('daily_attendance').upsert({
        'student_id': studentId,
        'attendance_date': dateStr,
        'is_present': isPresent,
        'leave_type': leaveType,
        'punch_method': punchMethod,
        'marked_by': markedByUserId,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'student_id,attendance_date');
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase recordAttendance error: $e');
      }
      return false;
    }
  }

  /// Query live leave slips from Supabase table 'leave_slips'
  Future<List<Map<String, dynamic>>> fetchLeaveSlips() async {
    if (!_isInitialized || client == null) return [];
    try {
      final res = await client!
          .from('leave_slips')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchLeaveSlips error: $e');
      }
      return [];
    }
  }

  /// Submit new Pink Slip to Supabase
  Future<bool> submitLeaveSlip({
    required int studentId,
    required String reason,
    required DateTime fromDate,
    required DateTime toDate,
    required bool isOnDuty,
    String? letterUrl,
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('leave_slips').insert({
        'student_id': studentId,
        'reason': reason,
        'from_date': fromDate.toIso8601String().split('T').first,
        'to_date': toDate.toIso8601String().split('T').first,
        'is_informed': true,
        'letter_document_url': letterUrl,
        'status': 'SUBMITTED',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase submitLeaveSlip error: $e');
      }
      return false;
    }
  }

  /// Update Leave Slip Status in Supabase
  Future<bool> updateLeaveSlipStatus({
    required int slipId,
    required String status,
    String? remarks,
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('leave_slips').update({
        'status': status,
        'advisor_remarks': remarks,
      }).eq('slip_id', slipId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase updateLeaveSlipStatus error: $e');
      }
      return false;
    }
  }
}
