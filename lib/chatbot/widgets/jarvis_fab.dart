import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // Strict Security Isolation: Chatbot is exclusively available on HOD dashboard for HODs
    if (user != null && user.role != UserRole.hod) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 8,
      shape: const CircleBorder(),
      onPressed: () => _showJarvisBottomSheet(context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
          ),
          border: Border.all(color: const Color(0xFF67E8F9), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.6),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 22,
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
          content: Text('🔒 Access Denied: Smart Pro AI Assistant is restricted exclusively to Head of Department (HOD) only.'),
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
      'text': '🤖 **Greetings Dr. HOD! I am Smart Pro AI Co-Pilot (Jarvis)**, your intelligent departmental executive assistant.\n\nI have complete trained memory of all **622 students** across all 10 sections (II, III & IV Year AI&DS), **10 Section Class Advisors**, the **2026 Academic Calendar (Sep-Dec)**, live attendance records, OD approvals, and <75% attendance defaulters.\n\nHow may I assist your department administration today?'
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
              backgroundColor: const Color(0xFF6366F1),
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
        final errText = e.toString().replaceAll('Exception:', '').trim();
        response = _generateOfflineResponse(cleanQuery, errorNotice: '*(Note: Gemini live API: $errText. Showing local intelligence engine)*\n\n');
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 250));
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
    } else if (q.contains('defaulter') || q.contains('<75%') || q.contains('less than 75') || q.contains('low attendance') || q.contains('75%')) {
      final defaulters = MockDataService.getAllDepartmentDefaulters();
      final buffer = StringBuffer('⚠️ **Students with Low Attendance (< 75% Cutoff)**:\n\n');
      buffer.writeln('Total **${defaulters.length} students** are currently falling below the 75% Anna University eligibility cutoff:\n');
      for (final d in defaulters) {
        final s = d['student'] as StudentModel;
        final pct = d['percentage'] as double;
        buffer.writeln('• **${s.name}** (`${s.rollNumber}`) — **${s.classDisplay}** : **${pct.toStringAsFixed(1)}%** (Due slips: ${d['dueSlips']})');
      }
      buffer.writeln('\n💡 *Section Class Advisors have been automatically notified to issue parental intimation notices.*');
      response = buffer.toString();
    } else if (q.contains('calendar') || q.contains('september') || q.contains('december') || q.contains('working days') || q.contains('semester')) {
      response = '📅 **2026 Academic Term Calendar (September - December 2026)**:\n\n'
          '• **September 2026**: 24 Instructional Days (Classes active & attendance logged daily)\n'
          '• **October 2026**: 25 Instructional Days (Internal Assessment Test I & Lab Reviews)\n'
          '• **November 2026**: 23 Instructional Days (Internal Assessment Test II & Mini Projects)\n'
          '• **December 2026**: 18 Instructional Days (Model Practical & University End Sem Exams)\n\n'
          '📌 **Key Rules**: Minimum **75%** attendance mandatory | Biometric Morning Cutoff **8:45 AM** | OD Slips submitted within 24h.';
    } else if (q.contains('4th year') || q.contains('fourth year') || q.contains('iv year') || q.contains('muthuselvan') || q.contains('nandhini') || q.contains('final year')) {
      response = '👨‍🏫 **4th Year (IV Year AI & DS - 2023 Batch) Class Advisors**:\n\n'
          '• **Section A**: **Mr. Muthuselvan** (`advisor.muthuselvan` / `advisor.4a@vsb.ac.in`)\n'
          '  - Total Students: 59 | Classroom: MB III A-301\n'
          '• **Section B**: **Mrs. Nandhinidevi** (`advisor.nandhinidevi` / `advisor.4b@vsb.ac.in`)\n'
          '  - Total Students: 65 | Classroom: MB III A-302\n\n'
          '🌟 Total 4th Year Strength: **124 Students** | Placement & Final Year Projects coordination active.';
    } else if (q.contains('2nd year') || q.contains('second year') || q.contains('ii year') || q.contains('anandhan') || q.contains('rajendiran') || q.contains('bharathidasan') || q.contains('palraj')) {
      response = '👨‍🏫 **2nd Year (II Year AI & DS - 2025 Batch) Class Advisors**:\n\n'
          '• **Section A**: **Dr. D. Anandhan** (`advisor.anandhan` / `advisor.2a@vsb.ac.in`) — 63 Students\n'
          '• **Section B**: **Dr. M. Rajendiran** (`advisor.rajendiran` / `advisor.2b@vsb.ac.in`) — 63 Students\n'
          '• **Section C**: **Mr. A. Bharathidasan** (`advisor.bharathidasan` / `advisor.2c@vsb.ac.in`) — 60 Students\n'
          '• **Section D**: **Mr. R. Palraj** (`advisor.palraj` / `advisor.2d@vsb.ac.in`) — 63 Students\n\n'
          '🌟 Total 2nd Year Strength: **249 Students** (2025 Batch).';
    } else if (q.contains('3rd year') || q.contains('third year') || q.contains('iii year') || q.contains('vishnupriya') || q.contains('murugesan') || q.contains('bharathi') || q.contains('velusamy')) {
      response = '👨‍🏫 **3rd Year (III Year AI & DS - 2024 Batch) Class Advisors**:\n\n'
          '• **Section A**: **Ms. C. Vishnupriya** (`advisor.vishnupriya` / `advisor.3a@vsb.ac.in`) — 65 Students\n'
          '• **Section B**: **Dr. R. Murugesan** (`advisor.murugesan` / `advisor.3b@vsb.ac.in`) — 61 Students\n'
          '• **Section C**: **Mrs. B. Bharathi** (`advisor.bharathi` / `advisor.3c@vsb.ac.in`) — 60 Students\n'
          '• **Section D**: **Mr. Velusamy** (`advisor.velusamy` / `advisor.3d@vsb.ac.in`) — 63 Students\n\n'
          '🌟 Total 3rd Year Strength: **249 Students** (2024 Batch).';
    } else if (q.contains('advisor') || q.contains('faculty') || q.contains('staff') || q.contains('teachers')) {
      response = '👨‍🏫 **All 10 Official Section Class Advisors (Academic Year 2026-2027)**:\n\n'
          '🏛️ **IV Year (2023 Batch - Final Year)**:\n'
          '  • IV - A: **Mr. Muthuselvan** (`advisor.muthuselvan`)\n'
          '  • IV - B: **Mrs. Nandhinidevi** (`advisor.nandhinidevi`)\n\n'
          '🏛️ **III Year (2024 Batch - V Semester)**:\n'
          '  • III - A: **Ms. C. Vishnupriya** (`advisor.vishnupriya`)\n'
          '  • III - B: **Dr. R. Murugesan** (`advisor.murugesan`)\n'
          '  • III - C: **Mrs. B. Bharathi** (`advisor.bharathi`)\n'
          '  • III - D: **Mr. Velusamy** (`advisor.velusamy`)\n\n'
          '🏛️ **II Year (2025 Batch - III Semester)**:\n'
          '  • II - A: **Dr. D. Anandhan** (`advisor.anandhan`)\n'
          '  • II - B: **Dr. M. Rajendiran** (`advisor.rajendiran`)\n'
          '  • II - C: **Mr. A. Bharathidasan** (`advisor.bharathidasan`)\n'
          '  • II - D: **Mr. R. Palraj** (`advisor.palraj`)\n\n'
          '🎓 **Head of Department (HOD)**:\n'
          '  • Overall HOD: **Dr. K. Manivannan (Ph.D.)**\n'
          '  • Junior Wing HOD: **Mrs. V. Kavitha**';
    } else if (q.contains('absent') || q.contains('uninformed') || q.contains('leaves today') || q.contains('attendance summary')) {
      response = '📊 **Today\'s Real-Time Department Attendance Status**:\n\n'
          '• **Total Department Strength**: **622 Students** (10 Sections)\n'
          '• **Total Present Today**: **589 Students** (94.7% Turnout)\n'
          '• **Total Absentees**: **33 Students** (5.3%)\n\n'
          '**Section-wise Absentee Breakdown**:\n'
          '• **II AIDS A**: 3 Absentees (Adithyan S on Sports OD)\n'
          '• **II AIDS B**: 4 Absentees (Lithesh Hari R parent slip, Janani Y on IIT OD)\n'
          '• **II AIDS C**: 3 Absentees\n'
          '• **II AIDS D**: 4 Absentees\n'
          '• **III AIDS A**: 4 Absentees (Akash I on SIH Hackathon OD)\n'
          '• **III AIDS B**: 3 Absentees\n'
          '• **III AIDS C**: 3 Absentees\n'
          '• **III AIDS D**: 4 Absentees\n'
          '• **IV AIDS A**: 2 Absentees (Advisor: Mr. Muthuselvan)\n'
          '• **IV AIDS B**: 3 Absentees (S. Harini on Zoho Placement OD - Advisor: Mrs. Nandhinidevi)';
    } else if (q.contains('pending') || q.contains('approve') || q.contains('signature') || q.contains('queue')) {
      final pending = MockDataService.pendingHodApprovals;
      response = '🖋️ **HOD Real-Time Decision Queue**:\n\n'
          'There are **$pending Applications** forwarded by Class Advisors awaiting your digital signature:\n\n'
          '1. **Janani Y** (Roll: `25243068`, II AI&DS Sec B) — IIT Madras National AI Symposium OD with Invitation Letter.\n'
          '2. **Adithyan S** (Roll: `25243002`, II AI&DS Sec A) — State Cricket Zonal Championship OD with Sports Board Letter.\n'
          '3. **Akash I** (Roll: `24243007`, III AI&DS Sec A) — Smart India Hackathon (SIH) Grand Finale OD.\n'
          '4. **S. Harini** (Roll: `23243034`, IV AI&DS Sec B) — Zoho Corporation Recruitment Interview OD.\n\n'
          '💡 You can approve or reject these directly from the **Needs Your Final Signature** card on your HOD dashboard.';
    } else if (q.contains('promotion') || q.contains('progress') || q.contains('next year') || q.contains('change class') || q.contains('advance year') || q.contains('upgrade year')) {
      final pending = MockDataService.pendingHodPromotions;
      response = '🎓 **Academic Year Progression & Promotion Protocol**:\n\n'
          '• **Semester Structure**: 1 Academic Year = 2 Semesters (~3 months each: Odd & Even Sems).\n'
          '• **Progression Trigger**: After the 2nd Semester finishes, a **7 to 10-day evaluation grace period** automatically initiates an official promotion request.\n'
          '• **Two-Tier Approval Flow**:\n'
          '  1. **Class Advisor Review**: Validates student credits, clearance & attendance (>=75%) -> Endorses and forwards to HOD.\n'
          '  2. **HOD Final Signature**: HOD approves the batch, upgrading all students to the next academic year in the database.\n'
          '• **Progression Stages**:\n'
          '  - **I Year ➔ II Year** (Sem 2 ➔ Sem 3)\n'
          '  - **II Year ➔ III Year** (Sem 4 ➔ Sem 5)\n'
          '  - **III Year ➔ IV Year** (Sem 6 ➔ Sem 7)\n'
          '  - **IV Year ➔ Graduated / Alumni Archive** (Sem 8 Graduation)\n\n'
          '📌 **Current Queue**: **$pending Batch Promotion Proposals** are currently awaiting HOD executive review on the dashboard.';
    } else if (q.contains('retention') || q.contains('alumni') || q.contains('purge') || q.contains('delete') || q.contains('2 year') || q.contains('two year') || q.contains('archive')) {
      final archives = MockDataService.alumniArchiveRecords;
      final activeCount = archives.where((a) => !a.isPurged).length;
      final purgedCount = archives.where((a) => a.isPurged).length;
      response = '🏛️ **Graduated / 4th Year Alumni Data Retention & Auto-Purge Policy**:\n\n'
          '• **Statutory Retention Rule**: When 4th Year students graduate, all academic records, attendance history, and bio-data are archived in the database for a **mandatory minimum of 2 Years (730 Days)** for university verifications and transcript requests.\n'
          '• **Automated Database Purge**: Once the 2-year retention window lapses, student data is **automatically deleted/purged** from active storage with an encrypted audit log.\n\n'
          '📊 **Current Vault Status**:\n'
          '• **Active Under 2-Yr Retention**: **$activeCount Graduates** (e.g., 2025 & 2026 Batches)\n'
          '• **Auto-Purged (> 2 Years)**: **$purgedCount Records** (2024 Batch pruned)\n\n'
          '💡 You can trigger a real-time compliance check via the **Alumni Data Retention & Auto-Purge Manager** on your HOD dashboard.';
    } else if (q.contains('draft') || q.contains('circular') || q.contains('notice')) {
      response = '📝 **Official Circular Draft for <75% Attendance Defaulters**:\n\n'
          '**DEPARTMENT OF ARTIFICIAL INTELLIGENCE & DATA SCIENCE**\n'
          '**V.S.B. ENGINEERING COLLEGE, KARUR**\n\n'
          '**CIRCULAR REF: VSB/AIDS/2026/ATT-09**\n'
          '**Date**: 07 September 2026\n'
          '**To**: All II, III & IV Year Students & Parents\n\n'
          '**Subject: Urgent Notice on Attendance Defaulters & Anna University Exam Condonation**\n\n'
          'Students having cumulative attendance below **75%** in the ongoing academic semester (September–December 2026) are hereby cautioned.\n\n'
          '1. **Parent Meeting**: Parents of defaulters must meet respective Section Class Advisors within 3 days.\n'
          '2. **Medical/OD Slips**: Genuine medical certificates or approved OD proofs must be submitted immediately.\n'
          '3. **Strict Compliance**: Students failing to meet the minimum threshold will be detained from appearing in University Practical & Theory Examinations.\n\n'
          '*(Signed)*\n'
          '**Head of Department (AI&DS)**\n'
          'Dr. K. Manivannan (Ph.D.) / Mrs. V. Kavitha';
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
          buffer.writeln('\nShowing profile for **${nameCandidates.first.name}**:');
          buffer.writeln(_formatStudentResponse(nameCandidates.first));
          response = buffer.toString();
        } else {
          final buffer = StringBuffer('📋 Found **${nameCandidates.length} students** matching "$query":\n\n');
          for (final s in nameCandidates.take(6)) {
            buffer.writeln('• **${s.name}** (Roll: `${s.rollNumber}`) — ${s.classDisplay} (${s.batchYear})');
          }
          buffer.writeln('\n💡 *Please specify the roll number (e.g. `${nameCandidates.first.rollNumber}`) for complete telemetry.*');
          response = buffer.toString();
        }
      } else {
        response = '💡 I analyzed your query: "$query".\n\n'
            '**Smart Pro AI Quick Actions for HOD**:\n'
            '• Search any student by **Roll Number** (e.g. `25243001`, `24243007`, `23243034`)\n'
            '• Check **Low Attendance Defaulters (< 75%)**\n'
            '• Check **2026 Academic Calendar (Sep-Dec)**\n'
            '• Inquire about **Class Advisors** (2nd, 3rd, 4th Year)\n'
            '• Review **Pending HOD Approvals**\n'
            '• Draft an **Official Circular or Notice**\n\n'
            '✨ *To ask ANY broad AI/DS, academic, or technical questions, click the **⚙️ Gemini Key** button at the top to connect Google Gemini AI.*';
      }
    }

    return '$errorNotice$response';
  }

  String _formatStudentResponse(StudentModel s) {
    String advisorName = 'Department Class Advisor';
    for (final adv in AuthService.sectionAdvisors) {
      if (adv.year == s.year && adv.section == s.section) {
        advisorName = adv.name;
        break;
      }
    }

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
        '• **Today\'s Status**: 🟢 Present (Punch: 08:32 AM)\n'
        '• **Total Leaves Taken**: ${s.totalLeavesTaken} days\n'
        '• **Pending Slips Due**: ${s.dueLetters}\n'
        '• **Recent Slip Record**: $leaveInfo';
  }

  @override
  Widget build(BuildContext context) {
    final isGeminiConnected = GeminiService().hasApiKey;

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
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
                    child: Icon(Icons.auto_awesome, color: Color(0xFF67E8F9), size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Smart Pro AI (Jarvis)',
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
                    const Text('HOD Dedicated Co-Pilot • 622 Students Grounded',
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
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _chip('⚠️ Defaulters (<75%)', 'Show students with attendance less than 75%'),
                  _chip('📅 2026 Calendar', 'Tell me about the Sep-Dec 2026 academic calendar'),
                  _chip('📊 Live Attendance', 'Show today absentees and attendance summary'),
                  _chip('👨‍🏫 4th Yr Advisors', 'Who are the 4th year class advisors?'),
                  _chip('👨‍🏫 2nd Yr Advisors', 'Who are the 2nd year class advisors?'),
                  _chip('🖋️ HOD Approvals', 'Check pending slips for HOD'),
                  _chip('📝 Draft Circular', 'Draft a warning circular for students with <75% attendance'),
                  _chip('🔍 Student 25243001', 'Tell me about student 25243001'),
                  _chip('🔍 Student 23243034', 'Tell me about student 23243034'),
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
                      color: isJarvis ? const Color(0xFFF8FAFC) : const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(16),
                      border: isJarvis ? Border.all(color: const Color(0xFFE2E8F0)) : null,
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
                            color: isJarvis ? const Color(0xFF0F172A) : Colors.white,
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
                                    const SnackBar(content: Text('Copied response to clipboard'), duration: Duration(seconds: 1)),
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
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1))),
                  SizedBox(width: 10),
                  Text('Smart Pro AI is searching department records...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: InputDecoration(
                      hintText: isGeminiConnected
                          ? 'Ask any department or AI question...'
                          : 'Search roll no (e.g. 25243001), <75% defaulters, or calendar...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF6366F1)),
                  onPressed: () => _sendMessage(_inputCtrl.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String query) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFC7D2FE)),
        onPressed: () => _sendMessage(query),
      ),
    );
  }
}
