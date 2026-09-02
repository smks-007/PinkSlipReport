import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class JarvisFAB extends StatelessWidget {
  const JarvisFAB({super.key});

  @override
  Widget build(BuildContext context) {
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
      'text': '🤖 **Good day! I am Jarvis**, your AI Attendance & Instruction Co-pilot for the AI & DS Department (14 sections).\n\nAsk me anything about daily absentees, uninformed leave rules, HOD approval queues, 75% condonation formula, or specific department instructions.'
    }
  ];
  final _inputCtrl = TextEditingController();

  void _sendMessage(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _messages.add({'sender': 'user', 'text': query});
    });
    _inputCtrl.clear();

    Future.delayed(const Duration(milliseconds: 400), () {
      final q = query.toLowerCase();
      String response = '';

      if (q.contains('instruction') || q.contains('notice') || q.contains('circular')) {
        response = '📢 **Latest Department Instructions**:\n\n'
            '• **Overall Dept**: Biometric cut-off is 8:45 AM. Minimum 75% attendance mandatory for exam eligibility.\n'
            '• **3rd Year**: Mini-Project Phase-1 presentation attendance is compulsory (No OD permitted on Fridays).\n'
            '• **4th Year**: Campus placement drive participants must submit approved On-Duty slips within 24 hours.\n'
            '• **2nd Year Sec B**: Lithesh Hari R must submit guardian explanation letter by 25 Aug.';
      } else if (q.contains('uninformed') || q.contains('absent')) {
        response = '📊 **Daily Absentee Analysis for Sec B**:\n\n'
            '• **Lithesh Hari R** (25243100) — 🔴 Uninformed (Due: 25 Aug)\n'
            '• **Manikandan M** (25243113) — 🟡 Informed / Medical Approved\n'
            '• **Kavya S** (25243072) — 🔴 Uninformed (Due: 29 Aug)\n\n'
            '💡 Rule: Uninformed leaves must be regularized within 3 working days.';
      } else if (q.contains('pending') || q.contains('hod') || q.contains('approve')) {
        response = '🖋️ **HOD Approval Queue**:\n\n'
            'There are **2 Pink Slips** awaiting final HOD approval:\n'
            '1. **Lithesh Hari R** (II-B) — Fees clearance reason\n'
            '2. **Deepika S** (II-A) — Viral fever medical leave';
      } else if (q.contains('section') || q.contains('year') || q.contains('strength')) {
        response = '🏛️ **AI & DS Department Topology (14 Sections)**:\n\n'
            '• 1st Year: A, B, C, D (238 students)\n'
            '• 2nd Year: A, B, C, D (247 students)\n'
            '• 3rd Year: A, B, C, D (235 students)\n'
            '• 4th Year: A, B (112 students)\n'
            '**Total Strength**: 832 Students | 14 Class Advisors + 1 HOD.';
      } else {
        response = '💡 I have recorded your query. I am constantly monitoring real-time biometric turnstiles, face detection gate cameras, and all 14 section registers.';
      }

      setState(() {
        _messages.add({'sender': 'jarvis', 'text': response});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
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
                    const Text('Jarvis AI',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins')),
                    Row(
                      children: const [
                        CircleAvatar(radius: 3, backgroundColor: Color(0xFF34D399)),
                        SizedBox(width: 4),
                        Text('Online • AI&DS Intelligence Engine',
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

          // Topic Chips
          Container(
            color: const Color(0xFFF5F3FF),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('🔴 Uninformed Leaves', 'Show uninformed leaves in Sec B'),
                  _chip('📢 Instructions', 'Show department instructions'),
                  _chip('🖋️ HOD Slips', 'Check pending slips for HOD'),
                  _chip('🏛️ 14 Sections', 'What are the 14 sections in AI&DS?'),
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
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
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
                      hintText: 'Ask Jarvis anything...',
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
