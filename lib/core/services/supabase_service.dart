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

  SupabaseClient? get client =>
      _isInitialized ? Supabase.instance.client : null;

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
          debugPrint('Not configured with valid credentials.');
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
        debugPrint('Connected successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Initialization failed: $e');
      }
      _isInitialized = false;
    }
  }

  /// Resolve any identifier (roll number, username, or email) to official email
  String resolveEmail(String input) {
    final clean = input.trim().toLowerCase();

    // 1. If already valid email, return immediately
    if (clean.contains('@')) return clean;

    // 2. Student Roll Number pattern (digits)
    if (RegExp(r'^\d{6,12}$').hasMatch(clean)) {
      return '$clean@student.smartcampus.edu';
    }

    // 3. Known HOD username handles
    if (clean == 'hod' || clean.startsWith('hod.manivannan') || clean == 'manivannan') {
      return 'manivannan.hod@vsb.ac.in';
    }
    if (clean == 'juniorhod' || clean.startsWith('hod.kavitha') || clean == 'kavitha' || clean == 'hod12') {
      return 'hod.kavitha@vsb.ac.in';
    }

    // 4. Default domain resolution for staff & advisor handles
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

    AuthResponse? authResponse;
    try {
      authResponse = await client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // If sign-in failed, check for known email variations (e.g. hod.kavitha vs kavitha.hod)
      String? altEmail;
      if (email == 'hod.kavitha@vsb.ac.in') {
        altEmail = 'kavitha.hod@vsb.ac.in';
      } else if (email == 'kavitha.hod@vsb.ac.in') {
        altEmail = 'hod.kavitha@vsb.ac.in';
      } else if (email == 'manivannan.hod@vsb.ac.in') {
        altEmail = 'hod.manivannan@vsb.ac.in';
      } else if (email == 'hod.manivannan@vsb.ac.in') {
        altEmail = 'manivannan.hod@vsb.ac.in';
      }

      if (altEmail != null) {
        try {
          if (kDebugMode) {
            debugPrint(
              '🔄 Retrying Supabase Auth with alternate alias: $altEmail',
            );
          }
          authResponse = await client!.auth.signInWithPassword(
            email: altEmail,
            password: password,
          );
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final user = authResponse.user;
    if (user == null) return null;

    if (kDebugMode) {
      debugPrint('🎉 Supabase Auth successful for: ${user.email}');
    }

    // Extract profile metadata
    final metadata = user.userMetadata ?? {};
    final rawRole = (metadata['role'] as String?)?.toUpperCase() ?? '';

    UserRole userRole;
    if (rawRole == 'HOD' ||
        email.contains('hod') ||
        email.contains('manivannan')) {
      userRole = UserRole.hod;
    } else if (rawRole == 'ADVISOR' || email.contains('advisor')) {
      userRole = UserRole.advisor;
    } else {
      userRole = UserRole.student;
    }

    // Fetch official profile from public.users table
    Map<String, dynamic>? dbProfile;
    try {
      dbProfile = await fetchUserProfile(user.email ?? email, authId: user.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Warning fetching dbProfile during sign in: $e');
      }
    }

    final dbFullName = dbProfile?['full_name'] as String?;
    final resolvedName = (dbFullName != null && dbFullName.trim().isNotEmpty)
        ? dbFullName.trim()
        : (metadata['full_name'] as String? ??
              metadata['name'] as String? ??
              email.split('@').first);

    int? resolvedYear = metadata['year'] as int?;
    String? resolvedSection = metadata['section'] as String?;
    final String? classSec = metadata['class_section'] as String?;

    // Parse year and section from class_section string (e.g. 'II AI&DS - Section A')
    if ((resolvedYear == null || resolvedSection == null) && classSec != null) {
      final upper = classSec.toUpperCase();
      if (upper.contains('IV') ||
          upper.contains(' 4 ') ||
          upper.contains('4TH')) {
        resolvedYear ??= 4;
      } else if (upper.contains('III') ||
          upper.contains(' 3 ') ||
          upper.contains('3RD')) {
        resolvedYear ??= 3;
      } else if (upper.contains('II') ||
          upper.contains(' 2 ') ||
          upper.contains('2ND')) {
        resolvedYear ??= 2;
      } else if (upper.contains('I') ||
          upper.contains(' 1 ') ||
          upper.contains('1ST')) {
        resolvedYear ??= 1;
      }

      final secMatch = RegExp(
        r'SECTION\s+([A-D])',
        caseSensitive: false,
      ).firstMatch(classSec);
      if (secMatch != null) {
        resolvedSection ??= secMatch.group(1)?.toUpperCase();
      } else {
        final singleLetter = RegExp(r'\b([A-D])\b').firstMatch(classSec);
        if (singleLetter != null) {
          resolvedSection ??= singleLetter.group(1);
        }
      }
    }

    // Secondary fallback: parse from email (e.g. advisor.2a@vsb.ac.in, cr.boy.2b@vsb.ac.in)
    final cleanEmail = (user.email ?? email).toLowerCase();
    final roleMatch = RegExp(r'(?:advisor|cr\.[a-z]+)\.([1-4])([a-d])')
        .firstMatch(cleanEmail);
    if (roleMatch != null) {
      resolvedYear ??= int.tryParse(roleMatch.group(1)!);
      resolvedSection ??= roleMatch.group(2)?.toUpperCase();
    }

    return UserModel(
      id: user.id,
      name: resolvedName,
      email: user.email ?? email,
      role: userRole,
      department:
          dbProfile?['department'] as String? ??
          metadata['department'] as String? ??
          'AI&DS',
      college: metadata['college'] as String? ?? 'V.S.B. Engineering College',
      classSection: metadata['class_section'] as String?,
      batchYear: metadata['batch_year'] as String?,
      rollNumber: metadata['roll_number'] as String?,
      year: resolvedYear,
      section: resolvedSection,
    );
  }

  /// Fetch user profile directly from Supabase public.users table
  Future<Map<String, dynamic>?> fetchUserProfile(
    String email, {
    String? authId,
  }) async {
    if (!_isInitialized || client == null) return null;
    try {
      // 1. Try by auth_id if provided
      if (authId != null && authId.isNotEmpty) {
        final byAuth = await client!
            .from('users')
            .select()
            .eq('auth_id', authId)
            .maybeSingle();
        if (byAuth != null) return Map<String, dynamic>.from(byAuth);
      }

      final cleanEmail = email.trim().toLowerCase();

      // 2. Try by email directly
      final byEmail = await client!
          .from('users')
          .select()
          .eq('email', cleanEmail)
          .maybeSingle();
      if (byEmail != null) return Map<String, dynamic>.from(byEmail);

      // 3. Try known aliases (e.g. hod.kavitha vs kavitha.hod)
      String? alt;
      if (cleanEmail == 'hod.kavitha@vsb.ac.in') {
        alt = 'kavitha.hod@vsb.ac.in';
      } else if (cleanEmail == 'kavitha.hod@vsb.ac.in') {
        alt = 'hod.kavitha@vsb.ac.in';
      } else if (cleanEmail == 'hod.manivannan@vsb.ac.in') {
        alt = 'manivannan.hod@vsb.ac.in';
      } else if (cleanEmail == 'manivannan.hod@vsb.ac.in') {
        alt = 'hod.manivannan@vsb.ac.in';
      }

      if (alt != null) {
        final byAlt = await client!
            .from('users')
            .select()
            .eq('email', alt)
            .maybeSingle();
        if (byAlt != null) return Map<String, dynamic>.from(byAlt);
      }

      // 4. Fallback search by username pattern
      final prefix = cleanEmail
          .split('@')
          .first
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (prefix.isNotEmpty) {
        final byLike = await client!
            .from('users')
            .select()
            .ilike('email', '%$prefix%')
            .limit(1);
        if (byLike.isNotEmpty) {
          return Map<String, dynamic>.from(byLike.first);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchUserProfile error: $e');
      }
    }
    return null;
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
      try {
        final res = await client!
            .from('students')
            .select(
              'student_id, roll_number, register_number, section_id, student_name, leaves_taken_ytd, users(full_name, email, phone_number, is_active)',
            )
            .order('roll_number');
        return List<Map<String, dynamic>>.from(res);
      } catch (_) {
        // Resilient fallback query directly querying students without foreign key join
        final fallback = await client!
            .from('students')
            .select(
              'student_id, roll_number, register_number, section_id, student_name, leaves_taken_ytd',
            )
            .order('roll_number');
        return List<Map<String, dynamic>>.from(fallback);
      }
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
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

  /// Resolve Supabase integer student_id from either integer id or rollNumber
  Future<int> resolveStudentDbId({int? studentId, String? rollNumber}) async {
    if (!_isInitialized || client == null) return studentId ?? 1001;

    // 1. Prioritize looking up by unique roll_number in students table
    final qRoll = rollNumber?.trim();
    if (qRoll != null && qRoll.isNotEmpty) {
      try {
        final res = await client!
            .from('students')
            .select('student_id')
            .eq('roll_number', qRoll)
            .maybeSingle();
        if (res != null && res['student_id'] != null) {
          final id = res['student_id'] as int;
          if (kDebugMode) {
            debugPrint('🔍 Resolved real student_id $id for roll number $qRoll');
          }
          return id;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ student_id lookup by rollNumber failed: $e');
        }
      }
    }

    // 2. If studentId was already resolved from DB and exists in students table
    if (studentId != null && studentId > 0) {
      try {
        final exists = await client!
            .from('students')
            .select('student_id')
            .eq('student_id', studentId)
            .maybeSingle();
        if (exists != null) return studentId;
      } catch (_) {}
    }

    // 3. Fallback: try to fetch first student from students table if any exist
    try {
      final firstStudent = await client!
          .from('students')
          .select('student_id')
          .limit(1)
          .maybeSingle();
      if (firstStudent != null && firstStudent['student_id'] != null) {
        return firstStudent['student_id'] as int;
      }
    } catch (_) {}

    return studentId != null && studentId > 0 ? studentId : 1001;
  }

  /// Resolve integer user_id of the current authenticated user from public.users table
  Future<int> getCurrentDbUserId() async {
    if (!_isInitialized || client == null) return 1;
    try {
      final authId = client!.auth.currentUser?.id;
      final email = client!.auth.currentUser?.email;

      if (authId != null && authId.isNotEmpty) {
        final res = await client!
            .from('users')
            .select('user_id')
            .eq('auth_id', authId)
            .maybeSingle();
        if (res != null && res['user_id'] != null) {
          return res['user_id'] as int;
        }
      }

      if (email != null && email.isNotEmpty) {
        final res = await client!
            .from('users')
            .select('user_id')
            .eq('email', email.trim().toLowerCase())
            .maybeSingle();
        if (res != null && res['user_id'] != null) {
          return res['user_id'] as int;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to resolve current db user_id: $e');
      }
    }
    return 1;
  }

  /// Submit new Pink Slip to Supabase
  Future<bool> submitLeaveSlip({
    required int studentId,
    String? rollNumber,
    required String reason,
    required DateTime fromDate,
    required DateTime toDate,
    required bool isOnDuty,
    String? letterUrl,
    String status = 'SUBMITTED',
    String? advisorRemarks,
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      final realStudentId = await resolveStudentDbId(
        studentId: studentId,
        rollNumber: rollNumber,
      );

      // Map application status to PostgreSQL slip_status enum
      String dbStatus = status.toUpperCase();
      if (dbStatus == 'FORWARDED') {
        dbStatus = 'PENDING_HOD';
      } else if (dbStatus != 'APPROVED' && dbStatus != 'REJECTED' && dbStatus != 'PENDING_HOD') {
        dbStatus = 'SUBMITTED';
      }

      await client!.from('leave_slips').insert({
        'student_id': realStudentId,
        'reason': reason,
        'from_date': fromDate.toIso8601String().split('T').first,
        'to_date': toDate.toIso8601String().split('T').first,
        'is_informed': true,
        'letter_document_url': letterUrl,
        'status': dbStatus,
        'advisor_remarks': advisorRemarks,
        'created_at': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        debugPrint('✅ Supabase: Pink Slip persisted for student $realStudentId with status $dbStatus');
      }
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
      String dbStatus = status.toUpperCase();
      if (dbStatus == 'FORWARDED') {
        dbStatus = 'PENDING_HOD';
      }

      final updateData = <String, dynamic>{'status': dbStatus};
      if (dbStatus == 'APPROVED' || dbStatus == 'REJECTED') {
        if (remarks != null) updateData['hod_remarks'] = remarks;
      } else {
        if (remarks != null) updateData['advisor_remarks'] = remarks;
      }
      await client!
          .from('leave_slips')
          .update(updateData)
          .eq('slip_id', slipId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase updateLeaveSlipStatus error: $e');
      }
      return false;
    }
  }

  // ──────────────────── ATTENDANCE WITH STUDENT DETAILS ────────────────────

  /// Fetch attendance for a specific date joined with student details (roll, section, name)
  Future<List<Map<String, dynamic>>> fetchAttendanceWithStudents(
    DateTime date,
  ) async {
    if (!_isInitialized || client == null) return [];
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      try {
        final res = await client!
            .from('daily_attendance')
            .select(
              'attendance_id, student_id, attendance_date, is_present, leave_type, punch_method, in_time, out_time, students(roll_number, section_id, student_name)',
            )
            .eq('attendance_date', dateStr);
        return List<Map<String, dynamic>>.from(res);
      } catch (_) {
        final fallback = await client!
            .from('daily_attendance')
            .select(
              'attendance_id, student_id, attendance_date, is_present, leave_type, punch_method, in_time, out_time',
            )
            .eq('attendance_date', dateStr);
        return List<Map<String, dynamic>>.from(fallback);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchAttendanceWithStudents error: $e');
      }
      return [];
    }
  }

  /// Fetch attendance across a date range joined with student details
  Future<List<Map<String, dynamic>>> fetchAttendanceDateRange(
    DateTime start,
    DateTime end,
  ) async {
    if (!_isInitialized || client == null) return [];
    try {
      final startStr =
          '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final endStr =
          '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
      try {
        final res = await client!
            .from('daily_attendance')
            .select(
              'attendance_id, student_id, attendance_date, is_present, leave_type, punch_method, in_time, out_time, students(roll_number, section_id, student_name)',
            )
            .gte('attendance_date', startStr)
            .lte('attendance_date', endStr)
            .order('attendance_date');
        return List<Map<String, dynamic>>.from(res);
      } catch (_) {
        final fallback = await client!
            .from('daily_attendance')
            .select(
              'attendance_id, student_id, attendance_date, is_present, leave_type, punch_method, in_time, out_time',
            )
            .gte('attendance_date', startStr)
            .lte('attendance_date', endStr)
            .order('attendance_date');
        return List<Map<String, dynamic>>.from(fallback);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchAttendanceDateRange error: $e');
      }
      return [];
    }
  }

  /// Fetch all attendance records for a student across all dates (for defaulter calculation)
  Future<List<Map<String, dynamic>>> fetchAllAttendanceForStudent(
    int studentId,
  ) async {
    if (!_isInitialized || client == null) return [];
    try {
      final res = await client!
          .from('daily_attendance')
          .select('attendance_date, is_present, leave_type')
          .eq('student_id', studentId)
          .order('attendance_date');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchAllAttendanceForStudent error: $e');
      }
      return [];
    }
  }

  /// Fetch all attendance records across all dates (bulk — for defaulter analysis)
  Future<List<Map<String, dynamic>>> fetchAllAttendance() async {
    if (!_isInitialized || client == null) return [];
    try {
      final res = await client!
          .from('daily_attendance')
          .select('student_id, attendance_date, is_present, leave_type')
          .order('attendance_date');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchAllAttendance error: $e');
      }
      return [];
    }
  }

  // ──────────────────── LEAVE SLIPS WITH STUDENT DETAILS ────────────────────

  /// Fetch leave slips joined with student names and roll numbers (with robust PGRST205 fallback)
  Future<List<Map<String, dynamic>>> fetchLeaveSlipsWithStudents() async {
    if (!_isInitialized || client == null) return [];
    try {
      try {
        final res = await client!
            .from('leave_slips')
            .select(
              'slip_id, student_id, reason, from_date, to_date, status, is_informed, letter_document_url, advisor_remarks, hod_remarks, created_at, students(roll_number, section_id, student_name)',
            )
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(res);
      } catch (innerErr) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ Relational fetchLeaveSlipsWithStudents failed ($innerErr). Using direct fallback...',
          );
        }
        // Direct fallback query without relational join in case PostgREST schema cache relationship is unindexed
        final fallback = await client!
            .from('leave_slips')
            .select(
              'slip_id, student_id, reason, from_date, to_date, status, is_informed, letter_document_url, advisor_remarks, hod_remarks, created_at',
            )
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(fallback);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchLeaveSlipsWithStudents error: $e');
      }
      return [];
    }
  }

  /// Submit a leave slip AND mark the student absent in daily_attendance (pink slip auto-absent)
  Future<bool> submitLeaveSlipAndMarkAbsent({
    required int studentId,
    String? rollNumber,
    required String reason,
    required DateTime date,
    required bool isOnDuty,
    String? letterUrl,
    String status = 'SUBMITTED',
    String? advisorRemarks,
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      final realStudentId = await resolveStudentDbId(
        studentId: studentId,
        rollNumber: rollNumber,
      );
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Map application status to PostgreSQL slip_status enum
      String dbStatus = status.toUpperCase();
      if (dbStatus == 'FORWARDED') {
        dbStatus = 'PENDING_HOD';
      } else if (dbStatus != 'APPROVED' && dbStatus != 'REJECTED' && dbStatus != 'PENDING_HOD') {
        dbStatus = 'SUBMITTED';
      }

      // 1. Insert leave slip
      await client!.from('leave_slips').insert({
        'student_id': realStudentId,
        'reason': reason,
        'from_date': dateStr,
        'to_date': dateStr,
        'is_informed': true,
        'letter_document_url': letterUrl,
        'status': dbStatus,
        'advisor_remarks': advisorRemarks,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Auto-mark absent in daily_attendance (pink slip logic)
      if (!isOnDuty) {
        final markedByUserId = await getCurrentDbUserId();
        await client!.from('daily_attendance').upsert({
          'student_id': realStudentId,
          'attendance_date': dateStr,
          'is_present': false,
          'leave_type': 'ABSENT',
          'punch_method': 'PINK_SLIP_AUTO',
          'marked_by': markedByUserId,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'student_id,attendance_date');
      }

      if (kDebugMode) {
        debugPrint('✅ Supabase: Pink Slip & attendance auto-marked for student $realStudentId (status: $dbStatus)');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase submitLeaveSlipAndMarkAbsent error: $e');
      }
      return false;
    }
  }

  // ──────────────────── PROMOTIONS ────────────────────

  /// Fetch all promotion requests from Supabase
  Future<List<Map<String, dynamic>>> fetchPromotions() async {
    if (!_isInitialized || client == null) return [];
    try {
      final res = await client!
          .from('promotions')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchPromotions error: $e');
      }
      return [];
    }
  }

  /// Update promotion status in Supabase
  Future<bool> updatePromotionStatus({
    required int promotionId,
    required String status,
    String? advisorRemarks,
    String? hodName,
    String? hodRemarks,
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      final data = <String, dynamic>{'status': status};
      if (advisorRemarks != null) data['advisor_remarks'] = advisorRemarks;
      if (hodName != null) data['hod_name'] = hodName;
      if (hodRemarks != null) data['hod_remarks'] = hodRemarks;
      if (status == 'FORWARDED_TO_HOD') {
        data['date_forwarded_by_advisor'] = DateTime.now().toIso8601String();
      } else if (status == 'APPROVED_BY_HOD' || status == 'REJECTED') {
        data['date_approved_by_hod'] = DateTime.now().toIso8601String();
      }

      await client!
          .from('promotions')
          .update(data)
          .eq('promotion_id', promotionId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase updatePromotionStatus error: $e');
      }
      return false;
    }
  }

  // ──────────────────── ALUMNI ARCHIVE ────────────────────

  /// Fetch all alumni archive records from Supabase
  Future<List<Map<String, dynamic>>> fetchAlumniArchive() async {
    if (!_isInitialized || client == null) return [];
    try {
      final res = await client!
          .from('alumni_archive')
          .select()
          .order('graduation_date', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchAlumniArchive error: $e');
      }
      return [];
    }
  }

  /// Purge alumni record from Supabase after 2-year retention window
  Future<bool> purgeAlumniRecord(int archiveId) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!
          .from('alumni_archive')
          .update({
            'is_purged': true,
            'purged_at': DateTime.now().toIso8601String(),
          })
          .eq('archive_id', archiveId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase purgeAlumniRecord error: $e');
      }
      return false;
    }
  }

  // ──────────────────── ACADEMIC CALENDAR ────────────────────

  /// Fetch all academic calendar events from Supabase
  Future<List<Map<String, dynamic>>> fetchAcademicCalendar() async {
    if (!_isInitialized || client == null) return [];
    try {
      final res = await client!
          .from('academic_calendar')
          .select()
          .order('event_date');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchAcademicCalendar error: $e');
      }
      return [];
    }
  }

  /// Add a new holiday/event to the academic calendar
  Future<bool> addCalendarEvent({
    required DateTime date,
    required String eventType,
    required String eventName,
    required bool isWorkingDay,
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await client!.from('academic_calendar').upsert({
        'event_date': dateStr,
        'event_type': eventType,
        'event_name': eventName,
        'is_working_day': isWorkingDay,
      }, onConflict: 'event_date');
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase addCalendarEvent error: $e');
      }
      return false;
    }
  }

  // ──────────────────── BROADCAST NOTICES ────────────────────

  /// Fetch all broadcast notices from Supabase
  Future<List<Map<String, dynamic>>> fetchBroadcastNotices() async {
    if (!_isInitialized || client == null) return [];
    try {
      final res = await client!
          .from('broadcast_notices')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchBroadcastNotices error: $e');
      }
      return [];
    }
  }

  /// Submit a new department broadcast notice to Supabase
  Future<bool> submitBroadcastNotice({
    required String title,
    required String message,
    required String targetAudience,
    required String priority,
    String templateType = 'Others',
    String senderName = 'HOD Dr. K. Manivannan',
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('broadcast_notices').insert({
        'title': title,
        'message': message,
        'target_audience': targetAudience,
        'priority': priority,
        'template_type': templateType,
        'sender_name': senderName,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        debugPrint(
          '✅ [Supabase DB Log] Broadcast message logged to database: "$title" - "$message"',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase submitBroadcastNotice error: $e');
      }
      return false;
    }
  }

  /// Mark a broadcast notice as read
  Future<bool> markBroadcastNoticeRead(int noticeId) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!
          .from('broadcast_notices')
          .update({'is_read': true})
          .eq('notice_id', noticeId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase markBroadcastNoticeRead error: $e');
      }
      return false;
    }
  }

  // ──────────────────── STORAGE & TIMETABLES ────────────────────

  /// Upload a real document/image/PDF to Supabase Storage bucket 'leave_attachments'
  Future<String?> uploadLeaveDocument(
    Uint8List fileBytes,
    String fileName, {
    String? folder,
  }) async {
    if (!_isInitialized || client == null) return null;
    try {
      final sanitizedName = fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final targetFolder = folder ?? 'leaves';
      final path =
          '$targetFolder/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

      await client!.storage
          .from('leave_attachments')
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = client!.storage
          .from('leave_attachments')
          .getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase uploadLeaveDocument error: $e');
      }
      return null;
    }
  }

  /// Fetch all active Class Advisors and Faculty from Supabase
  Future<List<Map<String, dynamic>>> fetchFacultyAdvisors() async {
    if (!_isInitialized || client == null) return [];
    try {
      final staffList = await client!
          .from('staff_advisors')
          .select('*, users(user_id, full_name, email, role, department)');
      if (staffList.isNotEmpty) {
        return List<Map<String, dynamic>>.from(staffList);
      }
    } catch (_) {}

    try {
      final facultyList = await client!
          .from('faculty')
          .select('*, users(user_id, full_name, email, role, department)')
          .order('section_id', ascending: true);
      if (facultyList.isNotEmpty) {
        return List<Map<String, dynamic>>.from(facultyList);
      }
    } catch (_) {}

    try {
      final userFaculty = await client!
          .from('users')
          .select()
          .filter('role', 'in', '("FACULTY","ADVISOR")');
      return List<Map<String, dynamic>>.from(userFaculty);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchFacultyAdvisors error: $e');
      }
      return [];
    }
  }

  /// Fetch timetable for a specific section from Supabase
  Future<List<Map<String, dynamic>>> fetchTimetable(String sectionId) async {
    if (!_isInitialized || client == null) return [];
    try {
      final res = await client!
          .from('timetables')
          .select()
          .eq('section_id', sectionId)
          .order('period_number', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchTimetable error: $e');
      }
      return [];
    }
  }

  /// Save or update a timetable entry in Supabase
  Future<bool> saveTimetableEntry({
    required String sectionId,
    required String dayOfWeek,
    required int periodNumber,
    required String timeSlot,
    required String subjectCode,
    required String subjectName,
    required String shortName,
    required String facultyName,
    required String facultyShort,
    String roomNumber = 'MB III A-201',
    bool isLab = false,
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('timetables').upsert({
        'section_id': sectionId,
        'day_of_week': dayOfWeek,
        'period_number': periodNumber,
        'time_slot': timeSlot,
        'subject_code': subjectCode,
        'subject_name': subjectName,
        'short_name': shortName,
        'faculty_name': facultyName,
        'faculty_short': facultyShort,
        'room_number': roomNumber,
        'is_lab': isLab,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'section_id,day_of_week,period_number');
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase saveTimetableEntry error: $e');
      }
      return false;
    }
  }
}
