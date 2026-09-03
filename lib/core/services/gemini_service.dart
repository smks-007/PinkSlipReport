import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/mock_data_service.dart';

/// Service to interact with Google Gemini AI API for HOD intelligence and general assistance.
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // In-memory API key for runtime configuration
  String? _customApiKey;

  String? get customApiKey => _customApiKey;
  bool get hasApiKey => _customApiKey != null && _customApiKey!.trim().isNotEmpty;

  void setApiKey(String key) {
    _customApiKey = key.trim();
  }

  void clearApiKey() {
    _customApiKey = null;
  }

  /// Compile comprehensive, real-time departmental intelligence for Gemini context grounding.
  String buildDepartmentContext() {
    final metrics = MockDataService.getStorageMetrics();
    final leaves = MockDataService.leaveRequests;
    final pendingCount = MockDataService.pendingHodApprovals;

    final advisorList = AuthService.sectionAdvisors.map((a) {
      return '• ${a.classSection} (Year ${a.year}, Sec ${a.section}): ${a.name} (Email: ${a.email}, Username: @${a.username})';
    }).join('\n');

    final crList = AuthService.classRepresentatives.map((c) {
      return '• ${c.classSection} ${c.gender} CR: ${c.name} (Roll: ${c.rollNumber}, Email: ${c.email})';
    }).join('\n');

    final pendingList = leaves
        .where((l) => l.letterStatus.name == 'forwarded' || l.letterStatus.name == 'submitted')
        .map((l) => '• ${l.studentName} (${l.studentRollNumber}, ${l.year}-${l.section}): ${l.categoryDisplay} - ${l.reason} [Status: ${l.letterStatusDisplay}]')
        .join('\n');

    return '''
=== INSTITUTION & DEPARTMENT GROUNDING DATA ===
Institution: V.S.B. Engineering College, Karur
Department: Department of Artificial Intelligence & Data Science (AI & DS)
Academic Year: 2026-2027

Department Leadership:
- Overall Head of Department (III & IV Year): Dr. K. Manivannan (Ph.D.) - hod.manivannan@vsb.ac.in
- Junior Wing Head of Department (I & II Year): Mrs. V. Kavitha - kavitha.hod@vsb.ac.in

Student & Section Topology:
- Total Department Strength: 622 Students across 10 Active Sections
- IV Year (2023 Batch): 124 Students (Sec A: 59, Sec B: 65)
- III Year (2024 Batch): 249 Students (Sec A: 65, Sec B: 61, Sec C: 60, Sec D: 63)
- II Year (2025 Batch): 249 Students (Sec A: 63, Sec B: 63, Sec C: 60, Sec D: 63)

Class Advisors Directory:
$advisorList

Class Representatives (CRs):
$crList

Live Attendance Status (Today: 03-09-2026):
- Total Present: 589 Students (${MockDataService.attendancePercentage.toStringAsFixed(1)}% Turnout)
- Total Absentees: 33 Students
- Section Absentees: II-A: 3, II-B: 4, II-C: 3, II-D: 4, III-A: 4, III-B: 3, III-C: 3, III-D: 4, IV-A: 2, IV-B: 3

HOD Approvals Queue ($pendingCount Pending Actions):
$pendingList

Department Policies & Rules:
1. Attendance Cutoff: Minimum 75% overall attendance required for Anna University / College End Semester Exam eligibility.
2. Biometric Morning Cutoff: 8:45 AM.
3. On-Duty (OD) Rules: Endorsed OD slips for symposiums, sports, SIH hackathons, and placement drives must be submitted within 24 hours.
4. Class Advisor Scope: Each Class Advisor has strict access only to their assigned class. Only the HOD can view and edit records across all classes and years.
5. System Storage: ${metrics['storageUsedMB']} MB used of ${metrics['storageAllocatedMB']} MB quota.
==============================================
''';
  }

  /// Query Google Gemini API with department grounding context.
  Future<String> askGemini(String userQuery) async {
    final apiKey = _customApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    final systemInstruction = '''
You are Jarvis, the powerful AI Executive Assistant & Academic Co-Pilot for the Head of Department (HOD) at the Department of Artificial Intelligence and Data Science, V.S.B. Engineering College.

You have access to the complete department grounding data provided below. When responding to the HOD:
1. For department queries (attendance, students, advisors, CRs, leaves, ODs, timetables, circulars): Provide accurate, direct, highly professional answers using the grounding data. You can search any student by roll number (e.g. 25243100, 24243007, 23243034) or name.
2. For administrative, management, and drafting tasks: Draft polished official notices, circulars, parent letters, faculty meeting agendas, or policy recommendations tailored to college standards.
3. For technical, academic, AI/Data Science, curriculum, research, coding, or any general questions: Provide expert, clear, high-level answers worthy of assisting a doctorate-level Department Head and engineering educator.
4. Maintain a respectful, concise, executive tone ("Greetings Dr. HOD", clear bullet points, bold highlights). Format with clean Markdown.

${buildDepartmentContext()}
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final requestBody = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': '$systemInstruction\n\nHOD Query: $userQuery'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      }
    });

    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 15);
      final request = await httpClient.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      request.write(requestBody);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.isNotEmpty) {
              return text.trim();
            }
          }
        }
        return '🤖 Gemini responded, but no text content was generated.';
      } else {
        final errorData = jsonDecode(responseBody);
        final errorMsg = errorData['error']?['message'] ?? 'Status code ${response.statusCode}';
        throw Exception('Gemini API Error: $errorMsg');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gemini API Exception: $e');
      }
      rethrow;
    }
  }
}
