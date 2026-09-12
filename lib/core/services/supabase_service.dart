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
      return 'hod.kavitha@vsb.ac.in';
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
            debugPrint('🔄 Retrying Supabase Auth with alternate alias: $altEmail');
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
    if (rawRole == 'HOD' || email.contains('hod') || email.contains('manivannan')) {
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
        : (metadata['full_name'] as String? ?? metadata['name'] as String? ?? email.split('@').first);

    return UserModel(
      id: user.id,
      name: resolvedName,
      email: user.email ?? email,
      role: userRole,
      department: dbProfile?['department'] as String? ?? metadata['department'] as String? ?? 'AI&DS',
      college: metadata['college'] as String? ?? 'V.S.B. Engineering College',
      classSection: metadata['class_section'] as String?,
      batchYear: metadata['batch_year'] as String?,
      rollNumber: metadata['roll_number'] as String?,
      year: metadata['year'] as int?,
      section: metadata['section'] as String?,
    );
  }

  /// Fetch user profile directly from Supabase public.users table
  Future<Map<String, dynamic>?> fetchUserProfile(String email, {String? authId}) async {
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
      final prefix = cleanEmail.split('@').first.replaceAll(RegExp(r'[^a-z0-9]'), '');
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
      final res = await client!
          .from('students')
          .select('student_id, roll_number, register_number, section_id, student_name, leaves_taken_ytd, users!inner(full_name, email, phone_number, is_active)')
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

  // ──────────────────── ATTENDANCE WITH STUDENT DETAILS ────────────────────

  /// Fetch attendance for a specific date joined with student details (roll, section, name)
  Future<List<Map<String, dynamic>>> fetchAttendanceWithStudents(DateTime date) async {
    if (!_isInitialized || client == null) return [];
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final res = await client!
          .from('daily_attendance')
          .select('attendance_id, student_id, attendance_date, is_present, leave_type, punch_method, in_time, out_time, students!inner(roll_number, section_id, student_name)')
          .eq('attendance_date', dateStr);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchAttendanceWithStudents error: $e');
      }
      return [];
    }
  }

  /// Fetch attendance across a date range joined with student details
  Future<List<Map<String, dynamic>>> fetchAttendanceDateRange(DateTime start, DateTime end) async {
    if (!_isInitialized || client == null) return [];
    try {
      final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
      final res = await client!
          .from('daily_attendance')
          .select('attendance_id, student_id, attendance_date, is_present, leave_type, punch_method, in_time, out_time, students!inner(roll_number, section_id, student_name)')
          .gte('attendance_date', startStr)
          .lte('attendance_date', endStr)
          .order('attendance_date');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase fetchAttendanceDateRange error: $e');
      }
      return [];
    }
  }

  /// Fetch all attendance records for a student across all dates (for defaulter calculation)
  Future<List<Map<String, dynamic>>> fetchAllAttendanceForStudent(int studentId) async {
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

  /// Fetch leave slips joined with student names and roll numbers
  Future<List<Map<String, dynamic>>> fetchLeaveSlipsWithStudents() async {
    if (!_isInitialized || client == null) return [];
    try {
      final res = await client!
          .from('leave_slips')
          .select('slip_id, student_id, reason, from_date, to_date, status, is_informed, letter_document_url, advisor_remarks, hod_remarks, created_at, students!inner(roll_number, section_id, student_name)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
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
    required String reason,
    required DateTime date,
    required bool isOnDuty,
    String? letterUrl,
    String status = 'SUBMITTED',
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // 1. Insert leave slip
      await client!.from('leave_slips').insert({
        'student_id': studentId,
        'reason': reason,
        'from_date': dateStr,
        'to_date': dateStr,
        'is_informed': true,
        'letter_document_url': letterUrl,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Auto-mark absent in daily_attendance (pink slip logic)
      if (!isOnDuty) {
        await client!.from('daily_attendance').upsert({
          'student_id': studentId,
          'attendance_date': dateStr,
          'is_present': false,
          'leave_type': 'ABSENT',
          'punch_method': 'PINK_SLIP_AUTO',
          'marked_by': 1,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'student_id,attendance_date');
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

      await client!.from('promotions').update(data).eq('promotion_id', promotionId);
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
      await client!.from('alumni_archive').update({
        'is_purged': true,
        'purged_at': DateTime.now().toIso8601String(),
      }).eq('archive_id', archiveId);
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
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
        debugPrint('✅ [Supabase DB Log] Broadcast message logged to database: "$title" - "$message"');
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
}
