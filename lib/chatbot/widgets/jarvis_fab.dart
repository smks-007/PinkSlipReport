import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/models/student_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/data/student_directory_data.dart';

class JarvisFAB extends StatelessWidget {
  const JarvisFAB({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    // Security Restriction: Chatbot CANNOT be accessed by students or class representatives
    if (user != null && user.role == UserRole.student) {
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
    if (user != null && user.role == UserRole.student) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Access Denied: Jarvis AI Assistant is restricted to Faculty, Advisors, and HOD only.'),
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
      'text': '🤖 **Greetings! I am Jarvis**, your AI Attendance & Intelligence Co-pilot for the AI & DS Department.\n\nI have memory of all **622 students** across all 10 sections (II, III & IV Year 2025/2024/2023 Batches).\n\nAsk me about any student by **Roll Number** (e.g., 25243100, 24243007) or **Name** (e.g., Lithesh, Abinaya, Yuvanrajan), section strengths, leaves, ODs, or HOD queues.'
    }
  ];
  final _inputCtrl = TextEditingController();

  void _sendMessage(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _messages.add({'sender': 'user', 'text': query});
    });
    _inputCtrl.clear();

    Future.delayed(const Duration(milliseconds: 350), () {
      final q = query.toLowerCase().trim();
      String response = '';

      // 1. Check for 8-digit roll numbers (e.g. 25243100, 24243001, 23243034)
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
      } else {
        // 2. Search for student by name
        final nameCandidates = StudentDirectoryData.allStudents.where((s) {
          final sName = s.name.toLowerCase();
          // Match words in query
          final words = q.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ').split(' ').where((w) => w.length > 2);
          for (final w in words) {
            if (sName.contains(w)) return true;
          }
          return false;
        }).toList();

        if (nameCandidates.isNotEmpty && !_isGeneralQuery(q)) {
          if (nameCandidates.length == 1) {
            response = _formatStudentResponse(nameCandidates.first);
          } else if (nameCandidates.length <= 4) {
            final buffer = StringBuffer('📋 **Multiple students found matching your query:**\n\n');
            for (final s in nameCandidates) {
              buffer.writeln('• **${s.name}** (${s.rollNumber}) — ${s.fullClassDetails}');
            }
            buffer.writeln('\nShowing details for **${nameCandidates.first.name}**:');
            buffer.writeln(_formatStudentResponse(nameCandidates.first));
            response = buffer.toString();
          } else {
            final buffer = StringBuffer('📋 Found **${nameCandidates.length} students** matching "$query":\n\n');
            for (final s in nameCandidates.take(6)) {
              buffer.writeln('• **${s.name}** (Roll: ${s.rollNumber}) — ${s.classDisplay} (${s.batchYear})');
            }
            buffer.writeln('\n💡 *Please specify the roll number (e.g. ${nameCandidates.first.rollNumber}) to get full telemetry.*');
            response = buffer.toString();
          }
        } else if (q.contains('instruction') || q.contains('notice') || q.contains('circular')) {
          response = '📢 **Latest Department Instructions**:\n\n'
              '• **Overall Dept**: Biometric cut-off is 8:45 AM. Minimum 75% attendance mandatory for exam eligibility.\n'
              '• **3rd Year**: Mini-Project Phase-1 presentation attendance is compulsory (No OD permitted on Fridays).\n'
              '• **4th Year**: Campus placement drive participants must submit approved On-Duty slips within 24 hours.\n'
              '• **2nd Year Sec B**: Lithesh Hari R & Janani Y must submit regularized letters by 25 Aug.';
        } else if (q.contains('uninformed') || q.contains('absent')) {
          response = '📊 **Daily Absentee Analysis for AI&DS Department**:\n\n'
              '• **II AI&DS B**: Lithesh Hari R (25243100) — 🔴 Uninformed (Due: 25 Aug)\n'
              '• **II AI&DS B**: Manikandan M (25243113) — 🟢 Medical Leave Approved\n'
              '• **III AI&DS B**: Kabeesh L (24243064) — 🔴 Uninformed Leave\n'
              '• **II AI&DS C**: Muhil Raja A (25243129) — 🟢 Approved Leave\n\n'
              '💡 Rule: Uninformed leaves must be regularized within 3 working days with parent/guardian endorsement.';
        } else if (q.contains('pending') || q.contains('hod') || q.contains('approve')) {
          final pending = MockDataService.pendingHodApprovals;
          response = '🖋️ **HOD Approval Queue**:\n\n'
              'There are **$pending Pink Slips / On-Duty applications** awaiting final HOD decision:\n'
              '1. **Janani Y** (II AI&DS Sec B) — IIT Madras Symposium On-Duty (OD)\n'
              '2. **Adithyan S** (II AI&DS Sec A) — State Cricket Zonal OD\n'
              '3. **S. Harini** (IV AI&DS Sec B) — Zoho Campus Drive OD\n\n'
              'All documents contain attached verification letters ready for digital sign-off.';
        } else if (q.contains('section') || q.contains('batch') || q.contains('strength') || q.contains('topology')) {
          response = '🏛️ **AI & DS Department Student Topology (10 Sections, 622 Students)**:\n\n'
              '• **II AI&DS (2025 BATCH)**:\n'
              '  - Sec A: 63 students (CRs: Adithyan S ♂ & Abinaya G ♀)\n'
              '  - Sec B: 63 students (CRs: Lithesh Hari R ♂ & Janani Y ♀)\n'
              '  - Sec C: 60 students (CRs: Muhil Raja A ♂ & Nandhini R ♀)\n'
              '  - Sec D: 63 students (CRs: Saiprasath S ♂ & Sahana S ♀)\n\n'
              '• **III AI&DS (2024 BATCH)**:\n'
              '  - Sec A: 65 students (CRs: Akash I ♂ & Abinaya K ♀)\n'
              '  - Sec B: 61 students (CRs: Kabeesh L ♂ & Jenitta Blessy S ♀)\n'
              '  - Sec C: 60 students (CRs: Nijay S S ♂ & Narthini N ♀)\n'
              '  - Sec D: 63 students (CRs: Saran Kumar A ♂ & Sandhiya G ♀)\n\n'
              '• **IV AI&DS (2023 BATCH)**:\n'
              '  - Sec A: 59 students (CRs: K.Ajay Abinesh ♂ & S.Aarthi ♀)\n'
              '  - Sec B: 65 students (CRs: P. Mukesh ♂ & S. Harini ♀)\n\n'
              '**Total Active Strength**: 622 Students | 10 Class Advisors | 2 HODs.';
        } else {
          response = '💡 I have recorded your query about "$query".\n\n'
              'You can search any of the 622 students by typing their **Roll Number** (e.g. `25243100`, `24243007`, `23243034`) or **Student Name** (e.g. `Adithyan`, `Janani`, `S. Harini`), or asking about section strengths and approval queues.';
        }
      }

      if (mounted) {
        setState(() {
          _messages.add({'sender': 'jarvis', 'text': response});
        });
      }
    });
  }

  bool _isGeneralQuery(String q) {
    return q.contains('instruction') ||
        q.contains('absent') ||
        q.contains('pending') ||
        q.contains('hod') ||
        q.contains('section') ||
        q.contains('strength');
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          const Text('Jarvis AI Intelligence',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins')),
                          Row(
                            children: const [
                              CircleAvatar(radius: 3, backgroundColor: Color(0xFF34D399)),
                              SizedBox(width: 4),
                              Text('Online • 622 Students • 10 Sections Indexed',
                                  style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
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
                    child: Row(
                      children: [
                        _chip('🔍 Student: 25243100', 'Tell me about student 25243100'),
                        _chip('🔍 Student: 24243007', 'Tell me about Akash I 24243007'),
                        _chip('🔍 Student: S. Harini', 'Who is S. Harini 23243034?'),
                        _chip('🏛️ 10 Sections', 'Show 10 sections and strengths in AI&DS'),
                        _chip('🖋️ HOD Pending', 'Check pending slips for HOD'),
                        _chip('📢 Circulars', 'Show department instructions'),
                      ],
                    ),
                  ),
                ),

                // Messages
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
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
                            maxWidth: MediaQuery.of(context).size.width * 0.84,
                          ),
                          decoration: BoxDecoration(
                            color: isJarvis ? const Color(0xFFF8F7FC) : AppColors.primaryPurple,
                            borderRadius: BorderRadius.circular(16),
                            border: isJarvis ? Border.all(color: const Color(0xFFECEAF4)) : null,
                          ),
                          child: Text(
                            msg['text']!,
                            style: TextStyle(
                              color: isJarvis ? const Color(0xFF1E1B2E) : Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
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
                            hintText: 'Enter student roll no (e.g. 25243100) or name...',
                            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Color(0xFFECEAF4)),
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
              'Jarvis AI Assistant is strictly reserved for Class Advisors, Faculty, and Head of the Department.\n\nStudents and Class Representatives do not have authorization to access department intelligence telemetry.',
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
