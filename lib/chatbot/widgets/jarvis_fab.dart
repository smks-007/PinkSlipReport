import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/user_model.dart';
import '../../core/models/student_model.dart';
import '../../core/models/leave_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/ai_agent_service.dart';

class JarvisFAB extends StatelessWidget {
  const JarvisFAB({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    // Strict Security Isolation: Chatbot & AI-Agent is available on HOD dashboard
    if (user != null && user.role != UserRole.hod) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 8,
      onPressed: () => _showJarvisBottomSheet(context),
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
          ),
          border: Border.all(color: const Color(0xFF67E8F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
      label: Row(
        children: const [
          Text(
            'AI-Agent Co-Pilot',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: 6),
          Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 16),
        ],
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

class _JarvisChatDrawerState extends State<_JarvisChatDrawer> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final List<Map<String, String>> _messages = [
    {
      'sender': 'jarvis',
      'text': '🤖 **Greetings Dr. HOD! I am Smart Pro AI Co-Pilot & Autonomous Agent**.\n\nI have complete trained memory of all **627 students** across all 10 sections (II, III & IV Year AI&DS), **10 Section Class Advisors**, the **2026 Academic Calendar (Sep-Dec)**, live attendance records, OD approvals, and <75% attendance defaulters.\n\n💡 *Tip: Give any student name or roll number (e.g. `25243001`, `25243100`, `24243007`, `23243034`) or switch to **Autonomous AI-Agent Mode** to execute administrative actions!*'
    }
  ];
  final _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isThinking = false;

  // AI-Agent Execution States
  bool _isAgentExecuting = false;
  AgentExecutionResult? _latestAgentResult;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

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
      await Future.delayed(const Duration(milliseconds: 200));
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

  void _runAgentGoal(String goal) async {
    setState(() {
      _isAgentExecuting = true;
      _latestAgentResult = null;
    });

    try {
      final result = await AiAgentService().executeAutonomousGoal(
        goal,
        hodName: 'Dr. K. Manivannan (Ph.D.)',
      );
      if (mounted) {
        setState(() {
          _isAgentExecuting = false;
          _latestAgentResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAgentExecuting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Agent Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _triggerAgentFromChat(String goal) {
    _tabCtrl.animateTo(1);
    _runAgentGoal(goal);
  }

  String _generateOfflineResponse(String query, {String errorNotice = ''}) {
    final q = query.toLowerCase().trim();
    String response = '';

    // 1. Check for 8-digit roll numbers (e.g. 25243001..25243252, 24243001..24243306, 23243001..23243305)
    final rollRegex = RegExp(r'\b(2[345]243\d{3})\b');
    final rollMatch = rollRegex.firstMatch(q);

    if (rollMatch != null) {
      final rollNo = rollMatch.group(1)!;
      final profile = AiAgentService().getStudentDeepProfile(rollNo);
      if (profile != null) {
        response = _formatProfileResponse(profile);
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
          '  - Total Students: 60 | Classroom: MB III A-301\n'
          '• **Section B**: **Mrs. Nandhinidevi** (`advisor.nandhinidevi` / `advisor.4b@vsb.ac.in`)\n'
          '  - Total Students: 65 | Classroom: MB III A-302\n\n'
          '🌟 Total 4th Year Strength: **125 Students** | Placement & Final Year Projects coordination active.';
    } else if (q.contains('2nd year') || q.contains('second year') || q.contains('ii year') || q.contains('anandhan') || q.contains('rajendiran') || q.contains('bharathidasan') || q.contains('palraj')) {
      response = '👨‍🏫 **2nd Year (II Year AI & DS - 2025 Batch) Class Advisors**:\n\n'
          '• **Section A**: **Dr. D. Anandhan** (`advisor.anandhan` / `advisor.2a@vsb.ac.in`) — 63 Students\n'
          '• **Section B**: **Dr. M. Rajendiran** (`advisor.rajendiran` / `advisor.2b@vsb.ac.in`) — 63 Students\n'
          '• **Section C**: **Mr. A. Bharathidasan** (`advisor.bharathidasan` / `advisor.2c@vsb.ac.in`) — 60 Students\n'
          '• **Section D**: **Mr. R. Palraj** (`advisor.palraj` / `advisor.2d@vsb.ac.in`) — 66 Students\n\n'
          '🌟 Total 2nd Year Strength: **252 Students** (2025 Batch).';
    } else if (q.contains('3rd year') || q.contains('third year') || q.contains('iii year') || q.contains('vishnupriya') || q.contains('murugesan') || q.contains('bharathi') || q.contains('velusamy')) {
      response = '👨‍🏫 **3rd Year (III Year AI & DS - 2024 Batch) Class Advisors**:\n\n'
          '• **Section A**: **Ms. C. Vishnupriya** (`advisor.vishnupriya` / `advisor.3a@vsb.ac.in`) — 65 Students\n'
          '• **Section B**: **Dr. R. Murugesan** (`advisor.murugesan` / `advisor.3b@vsb.ac.in`) — 61 Students\n'
          '• **Section C**: **Mrs. B. Bharathi** (`advisor.bharathi` / `advisor.3c@vsb.ac.in`) — 61 Students\n'
          '• **Section D**: **Mr. Velusamy** (`advisor.velusamy` / `advisor.3d@vsb.ac.in`) — 63 Students\n\n'
          '🌟 Total 3rd Year Strength: **250 Students** (2024 Batch).';
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
      final totalStrength = MockDataService.totalStrength;
      final pres = MockDataService.presentToday;
      final abs = MockDataService.absentToday;
      final pct = MockDataService.attendancePercentage;

      response = '📊 **Today\'s Real-Time Department Attendance Status**:\n\n'
          '• **Total Department Strength**: **$totalStrength Students** (10 Sections)\n'
          '• **Total Present Today**: **$pres Students** (${pct.toStringAsFixed(1)}% Turnout)\n'
          '• **Total Absentees**: **$abs Students**\n\n'
          '**Section-wise Absentee Breakdown**:\n'
          '• **II AIDS A**: 6 Absentees (AKHIL M, ARSHAD S, BHARATH M, DHARSAN S, DHARUN K, DHIVAKAR S)\n'
          '• **II AIDS B**: 3 Absentees (LAKSHAYAA S, LITHESH HARI R, MUGESHDHARAN M)\n'
          '• **II AIDS C**: 60 Absentees (Full section logged absent)\n'
          '• **II AIDS D**: 6 Absentees (SANTHOSH RAJ B, SHANMUGA SUNDARAM B, SRI HARISHKUMAR T, TAMILARASAN M, THAMARAIKKANNAN S, VIJAY M)\n'
          '• **III AIDS A**: 1 Absentee (SANTHOSH A)\n'
          '• **III AIDS B**: 6 Absentees (KAVIN SHARVESH R, KAVIYA D, KAVYA SHREE TV, LALITHA M, LOGESH S, MAHALAKSHMI K)\n'
          '• **III AIDS C**: 1 Absentee (SAKTHI BALAN M)\n'
          '• **III AIDS D**: 2 Absentees (SAKTHI B, VELAVAN A)\n'
          '• **IV AIDS A**: 7 Absentees (S.AARTHI, S.ELAMATHI, V.GOKUL ANAND, S.GOKUL KRISHNA, M.GOKUL, S.HARI KRISHNA, V.S HARINI)\n'
          '• **IV AIDS B**: 2 Absentees (P. ROOBALAKSHMI, K. THARANI KUMAR)';
    } else if (q.contains('pending') || q.contains('approve') || q.contains('signature') || q.contains('queue')) {
      final pending = MockDataService.pendingHodApprovals;
      response = '🖋️ **HOD Real-Time Decision Queue**:\n\n'
          'There are **$pending Applications** forwarded by Class Advisors awaiting your digital signature:\n\n'
          '1. **Janani Y** (Roll: `25243068`, II AI&DS Sec B) — IIT Madras National AI Symposium OD with Invitation Letter.\n'
          '2. **Adithyan S** (Roll: `25243002`, II AI&DS Sec A) — State Cricket Zonal Championship OD with Sports Board Letter.\n'
          '3. **Akash I** (Roll: `24243007`, III AI&DS Sec A) — Smart India Hackathon (SIH) Grand Finale OD.\n'
          '4. **S. Harini** (Roll: `23243034`, IV AI&DS Sec B) — Zoho Corporation Recruitment Interview OD.\n\n'
          '💡 You can approve or reject these directly or switch to **Autonomous AI-Agent Mode** to execute auto-approvals.';
    } else if (q.contains('pink slip') || q.contains('gate pass') || q.contains('pinkslip')) {
      response = '🎫 **Pink Slip & Gate Pass Protocol**:\n\n'
          '• Pink slips are officially generated for student leaves, hospital condonations, and on-duty (OD) campus exits.\n'
          '• Supported Categories: Medical Leave, Parent Verified Leave, Technical OD, Sports OD, Placement OD, University Exam Duty.\n'
          '• **Instant Action**: You can generate or approve Pink Slips instantly from the **HOD Pink Slip Central** or via the **AI-Agent tab**!';
    } else {
      // Search student by partial name or register number
      final candidate = AiAgentService().findStudent(query);
      if (candidate != null) {
        final profile = AiAgentService().getStudentDeepProfile(candidate.rollNumber);
        if (profile != null) {
          response = _formatProfileResponse(profile);
        } else {
          response = 'Found **${candidate.name}** (`${candidate.rollNumber}`), ${candidate.classDisplay}.';
        }
      } else {
        response = '💡 I analyzed your query: "$query".\n\n'
            '**Smart Pro AI Quick Actions for HOD**:\n'
            '• Search any student by **Roll Number / Register Number / Name** (e.g. `25243001`, `ADITHYAN S`, `25243100`, `24243007`, `23243034`)\n'
            '• Check **Low Attendance Defaulters (< 75%)**\n'
            '• Check **2026 Academic Calendar (Sep-Dec)**\n'
            '• Inquire about **Class Advisors** (2nd, 3rd, 4th Year)\n'
            '• Review **Today\'s Absentees & Turnout**\n'
            '• Switch to **AI-Agent Mode** above to run autonomous workflows!';
      }
    }

    return '$errorNotice$response';
  }

  String _formatProfileResponse(Map<String, dynamic> p) {
    final s = p['student'] as StudentModel;
    final advisorName = p['advisorName'] as String;
    final isPresent = p['isPresentToday'] as bool;
    final isOnDuty = p['isOnDutyToday'] as bool;
    final punchIn = p['biometricPunchIn'] as String;
    final punchOut = p['biometricPunchOut'] as String;
    final odReason = p['onDutyReason'] as String?;
    final cumulativePct = p['cumulativePercentage'] as double;
    final isDefaulter = p['isDefaulter'] as bool;
    final dueSlips = p['duePinkSlips'] as int;
    final leaves = p['leaves'] as List<LeaveModel>;

    String statusBadge;
    if (isPresent) {
      statusBadge = '🟢 **Present** (Biometric Punch: $punchIn – $punchOut)';
    } else if (isOnDuty) {
      statusBadge = '🔵 **On-Duty (OD)** • Event: ${odReason ?? "Authorized Official Duty"}';
    } else {
      statusBadge = '🔴 **Absent Today** • *Advisor intimation notice active*';
    }

    String leavesSummary = 'No active leave penalties or unpaid slips.';
    if (leaves.isNotEmpty) {
      final l = leaves.first;
      final doc = l.hasAttachment ? ' (📎 ${l.attachmentFileName})' : '';
      leavesSummary = '${l.categoryDisplay}: ${l.reason} • [${l.letterStatusDisplay}]$doc';
    }

    return '🎓 **Complete Student Profile & Telemetry**:\n\n'
        '• **Full Name**: **${s.name}**\n'
        '• **Roll Number**: `${s.rollNumber}`\n'
        '• **Class & Section**: **${s.classDisplay}** (${s.batchYear})\n'
        '• **Department**: Artificial Intelligence & Data Science\n'
        '• **Class Advisor**: **$advisorName**\n'
        '• **Gender**: ${s.gender}\n\n'
        '📊 **Live Attendance Telemetry**:\n'
        '• **Today\'s Status**: $statusBadge\n'
        '• **Cumulative Attendance**: **${cumulativePct.toStringAsFixed(1)}%** ${isDefaulter ? "⚠️ *(< 75% Defaulter Warning)*" : "✅ *(Eligible)*"}\n'
        '• **Total Leaves Taken**: ${s.totalLeavesTaken} Days\n'
        '• **Pending Pink Slips**: $dueSlips\n'
        '• **Latest Slip Details**: $leavesSummary';
  }

  void _showIssuePinkSlipModal() {
    final rollCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    LeaveCategory selectedCategory = LeaveCategory.leave;
    DateTime selectedDate = DateTime(2026, 9, 7);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.confirmation_number_outlined, color: Color(0xFF6366F1), size: 24),
              SizedBox(width: 8),
              Text('Issue Official Pink Slip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Student Roll Number:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: rollCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. 25243001, 24243007, 23243034',
                    hintStyle: const TextStyle(fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<LeaveCategory>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: LeaveCategory.leave, child: Text('Medical / Casual Leave')),
                    DropdownMenuItem(value: LeaveCategory.onDuty, child: Text('On-Duty (OD) / Symposium / Sports')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => selectedCategory = v);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Reason / Purpose:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter reason for gate pass / leave concession...',
                    hintStyle: const TextStyle(fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final roll = rollCtrl.text.trim();
                final reason = reasonCtrl.text.trim();
                if (roll.isEmpty || reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  final slip = AiAgentService().issuePinkSlip(
                    rollNumber: roll,
                    reason: reason,
                    date: selectedDate,
                    issuedBy: 'Dr. K. Manivannan (HOD)',
                    category: selectedCategory,
                  );
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎫 Pink Slip Generated for ${slip.studentName} (${slip.studentRollNumber})!'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Generate Pink Slip'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGeminiConnected = GeminiService().hasApiKey;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Smart Pro AI Intelligence',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                      const Text('HOD Executive Co-Pilot & Autonomous Agent • 627 Students Grounded',
                          style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 10)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome, color: Color(0xFF67E8F9), size: 20),
                  tooltip: 'Configure Gemini API Key',
                  onPressed: _showApiKeyDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Dual Mode Tab Switcher
          Container(
            color: const Color(0xFF0F172A),
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: const Color(0xFF67E8F9),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              tabs: const [
                Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 16), text: 'Jarvis Chatbot'),
                Tab(icon: Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFFBBF24)), text: '⚡ Autonomous AI-Agent'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // TAB 1: Chatbot
                _buildChatbotTab(isGeminiConnected),

                // TAB 2: Autonomous AI Agent
                _buildAiAgentTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatbotTab(bool isGeminiConnected) {
    return Column(
      children: [
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
                _chip('📊 Live Attendance', 'Show today absentees and attendance summary'),
                _chip('🔍 Student 25243001', 'Tell me about student 25243001'),
                _chip('🔍 Student 25243100', 'Tell me about student 25243100'),
                _chip('🔍 Student 24243007', 'Tell me about student 24243007'),
                _chip('🔍 Student 23243034', 'Tell me about student 23243034'),
                _chip('📅 2026 Calendar', 'Tell me about the Sep-Dec 2026 academic calendar'),
                _chip('👨‍🏫 4th Yr Advisors', 'Who are the 4th year class advisors?'),
                _chip('🖋️ HOD Approvals', 'Check pending slips for HOD'),
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
                        if (msg['text']!.contains('Decision Queue') || msg['text']!.contains('awaiting your digital signature')) ...[
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFFBBF24)),
                            label: const Text('⚡ Execute Auto-Approvals via AI-Agent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _triggerAgentFromChat('Scan and auto-approve all verified OD requests with supporting letters'),
                          ),
                        ] else if (msg['text']!.contains('Students with Low Attendance') || msg['text']!.contains('Defaulters')) ...[
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFFBBF24)),
                            label: const Text('⚡ Synthesize Defaulter Notices via AI-Agent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _triggerAgentFromChat('Scan all 10 sections for <75% attendance defaulters and synthesize parental intimation warning notices'),
                          ),
                        ] else if (msg['text']!.contains('Real-Time Department Attendance Status')) ...[
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFFBBF24)),
                            label: const Text('⚡ Generate Full Executive Brief via AI-Agent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _triggerAgentFromChat('Generate daily department executive brief across 627 students and 10 sections'),
                          ),
                        ] else if (msg['text']!.contains('Pink Slip & Gate Pass Protocol')) ...[
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                            label: const Text('🎫 Issue Instant Official Pink Slip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: _showIssuePinkSlipModal,
                          ),
                        ],
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
                        : 'Search roll no (e.g. 25243001), name, or <75% defaulters...',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
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
    );
  }

  Widget _buildAiAgentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agent Mission Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.smart_toy_outlined, color: Color(0xFF67E8F9), size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Autonomous AI-Agent Engine',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'Multi-Step Reasoning & Action Execution for HOD',
                            style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Delegate complex administrative tasks directly to the Smart Pro AI Agent. The agent autonomously audits documents, cross-verifies Anna University attendance quotas, executes batch approvals, and issues official Pink Slips.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            '⚡ Autonomous One-Tap Actions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          // Preset Action Grid
          Row(
            children: [
              Expanded(
                child: _agentActionBtn(
                  title: 'Auto-Approve ODs',
                  subtitle: 'Verify proofs & digital sign',
                  icon: Icons.verified_user_rounded,
                  color: const Color(0xFF059669),
                  onTap: () => _runAgentGoal('Scan and auto-approve all verified OD requests with supporting letters'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _agentActionBtn(
                  title: 'Defaulter Circular',
                  subtitle: 'Scan <75% & draft notices',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFD97706),
                  onTap: () => _runAgentGoal('Scan all 10 sections for <75% attendance defaulters and synthesize parental intimation warning notices'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _agentActionBtn(
                  title: 'Retention Purge',
                  subtitle: '2-Year alumni data audit',
                  icon: Icons.auto_delete_outlined,
                  color: const Color(0xFFDC2626),
                  onTap: () => _runAgentGoal('Run 2-year statutory alumni retention compliance audit and purge expired student records'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _agentActionBtn(
                  title: 'Executive Brief',
                  subtitle: '627-student telemetry',
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF2563EB),
                  onTap: () => _runAgentGoal('Generate daily department executive brief across 627 students and 10 sections'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _showIssuePinkSlipModal,
            icon: const Icon(Icons.confirmation_number_outlined, size: 16),
            label: const Text('Issue Instant Official Pink Slip / Gate Pass', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),

          // Custom Goal Input
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Give Custom Administrative Goal to AI Agent:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. "Audit 3rd year section B attendance and pink slips"...',
                          hintStyle: const TextStyle(fontSize: 11.5, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        ),
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) {
                            _runAgentGoal(v.trim());
                            _inputCtrl.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () {
                        if (_inputCtrl.text.trim().isNotEmpty) {
                          _runAgentGoal(_inputCtrl.text.trim());
                          _inputCtrl.clear();
                        }
                      },
                      child: const Text('Execute', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Execution Progress / Result
          if (_isAgentExecuting) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                children: const [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4F46E5))),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI Agent is executing multi-step reasoning cycles & action protocols across the department...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF312E81), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_latestAgentResult != null) ...[
            _buildAgentResultCard(_latestAgentResult!),
          ],
        ],
      ),
    );
  }

  Widget _agentActionBtn({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentResultCard(AgentExecutionResult res) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('AI-Agent Execution Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
              ),
              Text(
                '${res.steps.length} Steps Executed',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Steps list
          ...res.steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                        child: Text('Step ${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(step.actionName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF4F46E5))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('🧠 Thought: ${step.thought}', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                  const SizedBox(height: 2),
                  Text('👁️ Observation: ${step.observation}', style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }),

          const Divider(height: 20),
          Text(res.executiveSummary, style: const TextStyle(fontSize: 12.5, height: 1.45, color: Color(0xFF0F172A))),
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
