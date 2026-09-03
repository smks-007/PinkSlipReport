import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/models/student_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/data/student_directory_data.dart';

class JarvisFAB extends StatelessWidget {
  const JarvisFAB({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    // Strict Security Restriction: Chatbot is exclusively available on HOD dashboard for HODs
    if (user != null && user.role != UserRole.hod) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      backgroundColor: const Color(0xFF1E1B2E),
      elevation: 8,
      shape: const CircleBorder(),
      onPressed: () => _showJarvisBottomSheet(context),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF67E8F9), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF67E8F9).withValues(alpha: 0.6),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: CircleAvatar(
            radius: 7,
            backgroundColor: Color(0xFF67E8F9),
          ),
        ),
      ),
    );
  }

  void _showJarvisBottomSheet(BuildContext context) {
    final user = AuthService().currentUser;
    if (user != null && user.role != UserRole.hod) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Access Denied: Jarvis AI Assistant is restricted exclusively to Head of Department (HOD) only.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _JarvisChatDrawer(),
    );
  }
}

class _JarvisChatDrawer extends StatefulWidget {
  const _JarvisChatDrawer();

  @override
  State<_JarvisChatDrawer> createState() => _JarvisChatDrawerState();
}

class _JarvisChatDrawerState extends State<_JarvisChatDrawer> {
  final List<Map<String, String>> _messages = [
    {
      'sender': 'jarvis',
      'text': '🤖 **Greetings Dr. HOD! I am Jarvis**, your AI Executive Department Co-pilot powered by **Gemini AI Grounding** & Real-Time Department Telemetry.\n\nI have complete indexed memory of all **622 students**, **10 Section Class Advisors** (including 4th Year Sec A: Mr. Muthuselvan & Sec B: Mrs. Nandhinidevi), timetables, leaves, and HOD approval queues.\n\nYou can ask me **any departmental question** (attendance, student lookup, faculty info, approvals) or **any general question** (circular drafts, syllabus advice, AI/DS concepts, email templates).\n\nHow may I assist your department administration today?'
    }
  ];
  final _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isThinking = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showApiKeyDialog() {
    final keyCtrl = TextEditingController(text: GeminiService().customApiKey ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 24),
            SizedBox(width: 10),
            Text('Gemini AI Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect your Google Gemini API Key to enable unlimited general AI intelligence and advanced drafting for the HOD.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyCtrl,
              decoration: InputDecoration(
                hintText: 'Enter AIzaSy... Gemini API Key',
                hintStyle: const TextStyle(fontSize: 12),
                labelText: 'Gemini API Key',
                prefixIcon: const Icon(Icons.key_rounded, size: 20, color: Color(0xFF6366F1)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '🔒 Grounded with real-time V.S.B. AI&DS department records.',
              style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          if (GeminiService().hasApiKey)
            TextButton(
              onPressed: () {
                GeminiService().clearApiKey();
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gemini API Key removed. Using offline built-in intelligence.')),
                );
              },
              child: const Text('Clear Key', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final key = keyCtrl.text.trim();
              if (key.isNotEmpty) {
                GeminiService().setApiKey(key);
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✨ Gemini AI Connected! You can now ask any question.'),
                    backgroundColor: Color(0xFF047857),
                  ),
                );
              }
            },
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': cleanQuery});
      _isThinking = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    String response = '';

    // Check if Gemini API is available and try querying
    if (GeminiService().hasApiKey) {
      try {
        final geminiResponse = await GeminiService().askGemini(cleanQuery);
        response = geminiResponse;
      } catch (e) {
        // If Gemini fails, fallback to smart offline department intelligence
        final errText = e.toString().replaceAll('Exception:', '').trim();
        response = _generateOfflineResponse(cleanQuery, errorNotice: '*(Note: Gemini live API error: $errText. Showing local intelligence)*\n\n');
      }
    } else {
      // Use smart built-in department intelligence engine
      await Future.delayed(const Duration(milliseconds: 300));
      response = _generateOfflineResponse(cleanQuery);
    }

    if (mounted) {
      setState(() {
        _isThinking = false;
        _messages.add({'sender': 'jarvis', 'text': response});
      });
      _scrollToBottom();
    }
  }

  String _generateOfflineResponse(String query, {String errorNotice = ''}) {
    final q = query.toLowerCase().trim();
    String response = '';

    // 1. Check for 8-digit roll numbers (e.g. 25243001..25243252, 24243001..24243306, 23243001..23243305)
    final rollRegex = RegExp(r'\b(2[345]243\d{3})\b');
    final rollMatch = rollRegex.firstMatch(q);

    if (rollMatch != null) {
      final rollNo = rollMatch.group(1)!;
      final student = StudentDirectoryData.byRollNumber[rollNo];
      if (student != null) {
        response = _formatStudentResponse(student);
      } else {
        response = '🔍 Roll Number **$rollNo** was not found in the AI & DS active directory.';
      }
    } else if (q.contains('4th year') || q.contains('fourth year') || q.contains('iv year') || q.contains('muthuselvan') || q.contains('nandhini') || q.contains('nandhinidevi') || q.contains('final year')) {
      response = '👨‍🏫 **4th Year (IV Year AI & DS - 2023 Batch) Class Advisors**:\n\n'
          '• **Section A**: **Mr. Muthuselvan** (`advisor.4a@vsb.ac.in`)\n'
          '  - Classroom: MB III A-301 | Total Students: 59\n'
          '  - Class Representatives: K.AJAY ABINESH (♂) & S.AARTHI (♀)\n\n'
          '• **Section B**: **Mrs. Nandhinidevi** (`advisor.4b@vsb.ac.in`)\n'
          '  - Classroom: MB III A-302 | Total Students: 65\n'
          '  - Class Representatives: P. MUKESH (♂) & S. HARINI (♀)\n\n'
          '🌟 Total 4th Year Strength: **124 Students** | Placement & Project Coordination Active.';
    } else if (q.contains('advisor') || q.contains('faculty') || q.contains('staff') || q.contains('incharge') || q.contains('teachers')) {
      response = '👨‍🏫 **Official Class Advisors Directory (Academic Year 2026-2027)**:\n\n'
          '🏛️ **IV Year (2023 Batch - Final Year)**:\n'
          '  • IV - A: **Mr. Muthuselvan** (`advisor.4a@vsb.ac.in`)\n'
          '  • IV - B: **Mrs. Nandhinidevi** (`advisor.4b@vsb.ac.in`)\n\n'
          '🏛️ **III Year (2024 Batch - V Semester)**:\n'
          '  • III - A: **Ms. C. Vishnupriya** (`advisor.3a@vsb.ac.in`)\n'
          '  • III - B: **Dr. R. Murugesan** (`advisor.3b@vsb.ac.in`)\n'
          '  • III - C: **Mrs. B. Bharathi** (`advisor.3c@vsb.ac.in`)\n'
          '  • III - D: **Mr. Velusamy** (`advisor.3d@vsb.ac.in`)\n\n'
          '🏛️ **II Year (2025 Batch - III Semester)**:\n'
          '  • II - A: **Dr. D. Anandhan** (`advisor.2a@vsb.ac.in`)\n'
          '  • II - B: **Dr. M. Rajendiran** (`advisor.2b@vsb.ac.in`)\n'
          '  • II - C: **Mr. A. Bharathidasan** (`advisor.2c@vsb.ac.in`)\n'
          '  • II - D: **Mr. R. Palraj** (`advisor.2d@vsb.ac.in`)\n\n'
          '🎓 **Head of the Department (HOD)**:\n'
          '  • Overall HOD (III & IV Year): **Dr. K. Manivannan (Ph.D.)**\n'
          '  • Junior Wing HOD (I & II Year): **Mrs. V. Kavitha**';
    } else if (q.contains('draft') || q.contains('circular') || q.contains('notice') || q.contains('letter') || q.contains('template')) {
      response = '📝 **Official Department Circular Draft**:\n\n'
          '**DEPARTMENT OF ARTIFICIAL INTELLIGENCE & DATA SCIENCE**\n'
          '**V.S.B. ENGINEERING COLLEGE, KARUR**\n\n'
          '**CIRCULAR REF: VSB/AIDS/2026/CIR-08**\n'
          '**Date**: 03 September 2026\n'
          '**To**: All Students & Class Advisors (II, III & IV Year AI&DS)\n\n'
          '**Subject: Strict Compliance on Minimum 75% Attendance & Biometric Timings**\n\n'
          'It is hereby informed that all students must maintain a mandatory minimum attendance of **75%** to be eligible for the upcoming End Semester University Examinations.\n\n'
          '1. **Morning Cut-off**: Gate biometric entry closes promptly at **8:45 AM**.\n'
          '2. **Medical & OD Leave Regularization**: Any absent student must submit parent-signed explanation letters or OD endorsement within 24 hours to their respective Class Advisor.\n'
          '3. **Review Attendance**: Attendance for lab courses, project presentations, and placement training is strictly compulsory.\n\n'
          '*(Signed)*\n'
          '**Head of Department (AI&DS)**\n'
          'Dr. K. Manivannan (Ph.D.) / Mrs. V. Kavitha';
    } else if (q.contains('storage') || q.contains('space') || q.contains('database') || q.contains('backup') || q.contains('memory')) {
      final metrics = MockDataService.getStorageMetrics();
      response = '💾 **PinkSlipReport Local & Department Storage Telemetry**:\n\n'
          '• **Allocated Storage Quota**: ${metrics['storageAllocatedMB']} MB\n'
          '• **Storage Used**: **${metrics['storageUsedMB']} MB** (31.4% capacity utilized)\n'
          '• **System Health**: 🟢 ${metrics['systemHealth']}\n'
          '• **Sync Telemetry**: ${metrics['syncStatus']}\n'
          '• **Last Synced**: ${metrics['lastSyncTime']}\n\n'
          '**Data Breakdown**:\n'
          '1. **622 Student Profiles**: 2.45 MB (622 full records)\n'
          '2. **Attendance & Biometric Punch Logs**: 5.80 MB (Multi-day logs)\n'
          '3. **OD & Medical PDF Attachments**: 18.60 MB (Document Cache)\n'
          '4. **ODD Semester Timetable Indices**: 1.15 MB (10 Sections)\n'
          '5. **HOD Jarvis AI Intelligence Engine**: 3.13 MB\n\n'
          '💡 You can export all records as JSON/CSV or sync backup from the Top-Right Storage Icon on your HOD dashboard.';
    } else if (q.contains('absent') || q.contains('uninformed') || q.contains('leaves today') || q.contains('attendance summary')) {
      response = '📊 **Today\'s Real-Time Department Attendance Status (03-09-2026)**:\n\n'
          '• **Total Department Strength**: **622 Students** (10 Sections)\n'
          '• **Total Present Today**: **589 Students** (94.7% Presence)\n'
          '• **Total Absentees / Leaves**: **33 Students** (5.3%)\n\n'
          '**Section-wise Absentee Breakdown**:\n'
          '• **II AIDS A**: 3 Absentees (Adithyan S on Sports OD)\n'
          '• **II AIDS B**: 4 Absentees (Lithesh Hari R parent slip, Janani Y on IIT OD)\n'
          '• **II AIDS C**: 3 Absentees (Muhil Raja A regularized)\n'
          '• **II AIDS D**: 4 Absentees\n'
          '• **III AIDS A**: 4 Absentees (Akash I on SIH Hackathon OD)\n'
          '• **III AIDS B**: 3 Absentees (Kabeesh L leave due)\n'
          '• **III AIDS C**: 3 Absentees\n'
          '• **III AIDS D**: 4 Absentees\n'
          '• **IV AIDS A**: 2 Absentees (Advisor: Mr. Muthuselvan)\n'
          '• **IV AIDS B**: 3 Absentees (S. Harini on Zoho Placement OD - Advisor: Mrs. Nandhinidevi)\n\n'
          '💡 Class advisors can manage attendance only for their class, while HOD has full department authority.';
    } else if (q.contains('pending') || q.contains('hod') || q.contains('approve') || q.contains('slip') || q.contains('queue')) {
      final pending = MockDataService.pendingHodApprovals;
      response = '🖋️ **HOD Real-Time Decision Queue**:\n\n'
          'There are **$pending Applications** forwarded by Class Advisors awaiting your digital signature:\n\n'
          '1. **Janani Y** (Roll: `25243068`, II AI&DS Sec B) — IIT Madras National AI Symposium On-Duty (OD) with Invitation Letter.\n'
          '2. **Adithyan S** (Roll: `25243002`, II AI&DS Sec A) — State Cricket Zonal Championship OD with Sports Board Letter.\n'
          '3. **S. Harini** (Roll: `23243034`, IV AI&DS Sec B) — Zoho Corporation On-Campus Recruitment Technical Interview OD.\n\n'
          '💡 You can approve or reject these immediately with one tap from the **Pending Approvals** card on your HOD dashboard.';
    } else if (q.contains('section') || q.contains('batch') || q.contains('strength') || q.contains('topology')) {
      response = '🏛️ **AI & DS Department Student Topology (10 Sections, 622 Students)**:\n\n'
          '• **IV AI&DS (2023 BATCH)**: 124 Students\n'
          '  - Sec A: 59 students | Advisor: **Mr. Muthuselvan**\n'
          '  - Sec B: 65 students | Advisor: **Mrs. Nandhinidevi**\n\n'
          '• **III AI&DS (2024 BATCH)**: 249 Students\n'
          '  - Sec A: 65 students | Advisor: **Ms. C. Vishnupriya**\n'
          '  - Sec B: 61 students | Advisor: **Dr. R. Murugesan**\n'
          '  - Sec C: 60 students | Advisor: **Mrs. B. Bharathi**\n'
          '  - Sec D: 63 students | Advisor: **Mr. Velusamy**\n\n'
          '• **II AI&DS (2025 BATCH)**: 249 Students\n'
          '  - Sec A: 63 students | Advisor: **Dr. D. Anandhan**\n'
          '  - Sec B: 63 students | Advisor: **Dr. M. Rajendiran**\n'
          '  - Sec C: 60 students | Advisor: **Mr. A. Bharathidasan**\n'
          '  - Sec D: 63 students | Advisor: **Mr. R. Palraj**\n\n'
          '**Total Active Department Strength**: 622 Students | 10 Class Advisors | 2 HODs.';
    } else {
      // Search student by name
      final nameCandidates = StudentDirectoryData.allStudents.where((s) {
        final sName = s.name.toLowerCase();
        final words = q.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ').split(' ').where((w) => w.length > 2);
        for (final w in words) {
          if (sName.contains(w)) return true;
        }
        return false;
      }).toList();

      if (nameCandidates.isNotEmpty) {
        if (nameCandidates.length == 1) {
          response = _formatStudentResponse(nameCandidates.first);
        } else if (nameCandidates.length <= 4) {
          final buffer = StringBuffer('📋 **Found ${nameCandidates.length} students matching "$query":**\n\n');
          for (final s in nameCandidates) {
            buffer.writeln('• **${s.name}** (`${s.rollNumber}`) — ${s.fullClassDetails}');
          }
          buffer.writeln('\nShowing detailed telemetry for **${nameCandidates.first.name}**:');
          buffer.writeln(_formatStudentResponse(nameCandidates.first));
          response = buffer.toString();
        } else {
          final buffer = StringBuffer('📋 Found **${nameCandidates.length} students** matching "$query":\n\n');
          for (final s in nameCandidates.take(6)) {
            buffer.writeln('• **${s.name}** (Roll: `${s.rollNumber}`) — ${s.classDisplay} (${s.batchYear})');
          }
          buffer.writeln('\n💡 *Please enter the specific roll number (e.g. `${nameCandidates.first.rollNumber}`) for full student telemetry.*');
          response = buffer.toString();
        }
      } else {
        response = '💡 I analyzed your request: "$query".\n\n'
            '**Department Assistant Quick Options**:\n'
            '• Search any student by **Roll Number** (e.g. `25243100`, `24243007`, `23243034`)\n'
            '• Ask about **Class Advisors** (e.g. "Who is 4th year class advisor?")\n'
            '• Check **Today\'s Attendance & Absentees** (e.g. "Show absentees today")\n'
            '• Review **Pending HOD Approvals**\n'
            '• Request an **Official Notice or Circular Draft**\n\n'
            '✨ *To ask ANY broad academic, AI/DS, technical, or general knowledge question, tap the **⚙️ Gemini Key** button at the top to connect Google Gemini AI.*';
      }
    }

    return '$errorNotice$response';
  }



  String _formatStudentResponse(StudentModel s) {
    // Find section advisor
    String advisorName = 'Department Class Advisor';
    for (final adv in AuthService.sectionAdvisors) {
      if (adv.year == s.year && adv.section == s.section) {
        advisorName = adv.name;
        break;
      }
    }

    // Check existing leave or OD records in MockDataService
    final studentLeaves = MockDataService.leaveRequests
        .where((l) => l.studentRollNumber == s.rollNumber)
        .toList();

    String leaveInfo = 'No active leave or OD penalties recorded.';
    if (studentLeaves.isNotEmpty) {
      final l = studentLeaves.first;
      final attachSuffix = l.hasAttachment ? ' • 📎 Document: ${l.attachmentFileName}' : '';
      leaveInfo = '${l.categoryDisplay}: ${l.reason} (${l.letterStatusDisplay})$attachSuffix';
    }

    return '🎓 **Student Academic & Attendance Profile**:\n\n'
        '• **Full Name**: ${s.name}\n'
        '• **Roll Number (E. Code)**: `${s.rollNumber}`\n'
        '• **Class & Section**: ${s.classDisplay}\n'
        '• **Batch**: ${s.batchYear}\n'
        '• **Department**: Artificial Intelligence & Data Science\n'
        '• **Gender**: ${s.gender}\n'
        '• **Class Advisor**: $advisorName\n'
        '• **Today\'s Biometric Status**: ${s.isPresentToday ? "🟢 Present (Gate Punch In: 08:32 AM)" : "🔴 Absent / Uninformed"}\n'
        '• **Total Leaves Taken**: ${s.totalLeavesTaken} days\n'
        '• **Pending Slips Due**: ${s.dueLetters}\n'
        '• **Recent Slip Record**: $leaveInfo';
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isStudent = user != null && user.role == UserRole.student;
    final isGeminiConnected = GeminiService().hasApiKey;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: isStudent
          ? _buildAccessDeniedView()
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2D2A55), Color(0xFF12102A)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF67E8F9), width: 2),
                        ),
                        child: const Center(
                          child: CircleAvatar(radius: 6, backgroundColor: Color(0xFF67E8F9)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Jarvis AI HOD Co-Pilot',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isGeminiConnected
                                      ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                      : Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isGeminiConnected ? const Color(0xFF34D399) : Colors.white30,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  isGeminiConnected ? '✨ Gemini AI' : '⚡ Local AI',
                                  style: TextStyle(
                                    color: isGeminiConnected ? const Color(0xFF6EE7B7) : Colors.white70,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text('Online • 622 Students • 10 Sections Grounded',
                              style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 10)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome, color: Color(0xFF67E8F9), size: 20),
                        tooltip: 'Configure Gemini API Key',
                        onPressed: _showApiKeyDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70, size: 20),
                        tooltip: 'Clear Chat',
                        onPressed: () {
                          setState(() {
                            _messages.clear();
                            _messages.add({
                              'sender': 'jarvis',
                              'text': '🧹 Chat history reset. How may I assist you, Dr. HOD?'
                            });
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Quick Topic Chips
                Container(
                  color: const Color(0xFFF5F3FF),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _chip('📊 Live Attendance', 'Show today absentees and attendance summary'),
                        _chip('👨‍🏫 4th Yr Advisors', 'Who are the 4th year class advisors?'),
                        _chip('🖋️ HOD Approvals', 'Check pending slips for HOD'),
                        _chip('📝 Draft Circular', 'Draft an official circular for students with <75% attendance'),
                        _chip('🔍 Student 25243100', 'Tell me about student 25243100'),
                        _chip('🔍 Student 23243034', 'Tell me about student 23243034'),
                        _chip('💾 Storage & Data', 'Show storage and database space'),
                        _chip('🤖 Ask Gemini AI', 'Suggest 5 cutting-edge project topics in Agentic AI for final year students'),
                      ],
                    ),
                  ),
                ),

                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      final isJarvis = msg['sender'] == 'jarvis';
                      return Align(
                        alignment: isJarvis ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.86,
                          ),
                          decoration: BoxDecoration(
                            color: isJarvis ? const Color(0xFFF8F7FC) : AppColors.primaryPurple,
                            borderRadius: BorderRadius.circular(16),
                            border: isJarvis ? Border.all(color: const Color(0xFFECEAF4)) : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text']!,
                                style: TextStyle(
                                  color: isJarvis ? const Color(0xFF1E1B2E) : Colors.white,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                              if (isJarvis) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: msg['text']!));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Copied response to clipboard'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.copy_rounded, size: 12, color: Color(0xFF94A3B8)),
                                          SizedBox(width: 4),
                                          Text('Copy', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                if (_isThinking)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPurple),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Jarvis & Gemini are analyzing department records...',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),

                // Input Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFECEAF4))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          decoration: InputDecoration(
                            hintText: isGeminiConnected
                                ? 'Ask any department or general AI question...'
                                : 'Search roll no (e.g. 25243100), advisor, or attendance...',
                            hintStyle: const TextStyle(fontSize: 12.5, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Color(0xFFECEAF4)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColors.primaryPurple),
                        onPressed: () => _sendMessage(_inputCtrl.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAccessDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 56, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Access Restricted',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            const Text(
              'Jarvis AI Assistant is strictly reserved for Head of the Department (HOD).\n\nClass Advisors and students do not have authorization to access central department intelligence.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Close Window'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String query) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryPurple)),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFEDE9FE)),
        onPressed: () => _sendMessage(query),
      ),
    );
  }
}
