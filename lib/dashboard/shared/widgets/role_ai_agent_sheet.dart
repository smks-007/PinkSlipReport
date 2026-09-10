import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/ai_agent_service.dart';
import '../../../core/services/auth_service.dart';

/// Modal bottom sheet providing the Autonomous AI-Agent Co-Pilot for
/// Students and Class Advisors, with role-specific one-tap actions and custom goal execution.
class RoleAiAgentSheet extends StatefulWidget {
  final UserModel user;

  const RoleAiAgentSheet({super.key, required this.user});

  static void show(BuildContext context, {UserModel? user}) {
    final effectiveUser = user ?? AuthService().currentUser ?? AuthService.classRepresentatives.first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoleAiAgentSheet(user: effectiveUser),
    );
  }

  @override
  State<RoleAiAgentSheet> createState() => _RoleAiAgentSheetState();
}

class _RoleAiAgentSheetState extends State<RoleAiAgentSheet> {
  final TextEditingController _goalCtrl = TextEditingController();
  bool _isExecuting = false;
  AgentExecutionResult? _latestResult;

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  void _runGoal(String goal) async {
    final clean = goal.trim();
    if (clean.isEmpty) return;

    setState(() {
      _isExecuting = true;
      _latestResult = null;
    });

    try {
      final res = await AiAgentService().executeAutonomousGoal(
        clean,
        user: widget.user,
      );
      if (mounted) {
        setState(() {
          _isExecuting = false;
          _latestResult = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Agent Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.user.role == UserRole.student;
    final roleTitle = isStudent ? 'Student AI-Agent Co-Pilot' : 'Advisor AI-Agent Co-Pilot';
    final roleSubtitle = isStudent
        ? '${widget.user.name} • ${widget.user.classSection ?? "AI&DS"}'
        : '${widget.user.name} • ${widget.user.classSection ?? "Section Advisor"}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isStudent
                    ? [const Color(0xFF1E1B4B), const Color(0xFF312E81), const Color(0xFF4338CA)]
                    : [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    border: Border.all(color: const Color(0xFF67E8F9), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            roleTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF34D399), width: 0.8),
                            ),
                            child: const Text(
                              '⚡ Autonomous',
                              style: TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        roleSubtitle,
                        style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Agent Role Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isStudent ? const Color(0xFFEEF2FF) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isStudent ? const Color(0xFFC7D2FE) : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isStudent ? Icons.psychology_outlined : Icons.verified_user_outlined,
                          color: isStudent ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isStudent
                                ? 'Your personalized AI-Agent monitors your 75% statutory attendance quota, forecasts safety margins, auto-drafts compliant leave/OD applications, and checks due slips.'
                                : 'Your section AI-Agent automatically verifies submitted leave/OD proofs, performs batch forwardings to HOD, scans section defaulters (<75%), and synthesizes turnout telemetry.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isStudent ? const Color(0xFF312E81) : const Color(0xFF065F46),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    '⚡ One-Tap Agent Workflows',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),

                  // Preset Actions Grid
                  if (isStudent) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _actionCard(
                            title: '75% Attendance Forecast',
                            subtitle: 'Calculate safe margin & class requirements',
                            icon: Icons.analytics_outlined,
                            color: const Color(0xFF2563EB),
                            onTap: () => _runGoal('Forecast my attendance and calculate how many classes needed for 75% and 80% safety margin'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionCard(
                            title: 'Auto-Draft OD Application',
                            subtitle: 'Prepare hackathon / symposium OD with proof',
                            icon: Icons.note_add_outlined,
                            color: const Color(0xFF059669),
                            onTap: () => _runGoal('Draft and submit an On-Duty OD application for SIH Grand Finale Hackathon with digital proof'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _actionCard(
                            title: 'Medical Leave Application',
                            subtitle: 'Draft medical leave with prescription pass',
                            icon: Icons.medical_services_outlined,
                            color: const Color(0xFFD97706),
                            onTap: () => _runGoal('Draft medical leave application with doctor prescription certificate'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionCard(
                            title: 'Academic Dossier & Slips',
                            subtitle: 'Audit due pink slips & class schedule',
                            icon: Icons.fact_check_outlined,
                            color: const Color(0xFF7C3AED),
                            onTap: () => _runGoal('Audit my pending due pink slips, biometric status, and today timetable'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _actionCard(
                            title: 'Batch Forward ODs to HOD',
                            subtitle: 'Audit section leaves & forward to HOD queue',
                            icon: Icons.send_and_archive_rounded,
                            color: const Color(0xFF059669),
                            onTap: () => _runGoal('Scan submitted leave and OD requests in my section and batch forward them to HOD with endorsements'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionCard(
                            title: 'Section Defaulter Audit',
                            subtitle: 'Scan <75% and synthesize parent warnings',
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFD97706),
                            onTap: () => _runGoal('Scan my section for low attendance defaulters less than 75% and draft parental intimation notices'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _actionCard(
                            title: 'Section Daily Turnout Brief',
                            subtitle: 'Real-time turnout, absentees & OD telemetry',
                            icon: Icons.bar_chart_rounded,
                            color: const Color(0xFF2563EB),
                            onTap: () => _runGoal('Generate real-time section attendance brief and turnout breakdown for today'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionCard(
                            title: 'Issue Section Pink Slip',
                            subtitle: 'Instant gate pass for section student',
                            icon: Icons.confirmation_number_outlined,
                            color: const Color(0xFF7C3AED),
                            onTap: () => _showPinkSlipDialog(context),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Custom Goal Field
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Give Custom Goal to AI-Agent:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _goalCtrl,
                                decoration: InputDecoration(
                                  hintText: isStudent
                                      ? 'e.g. "Forecast attendance if I miss 2 days"...'
                                      : 'e.g. "Audit section attendance and forward ODs"...',
                                  hintStyle: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                ),
                                onSubmitted: (v) {
                                  if (v.trim().isNotEmpty) {
                                    _runGoal(v.trim());
                                    _goalCtrl.clear();
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
                                if (_goalCtrl.text.trim().isNotEmpty) {
                                  _runGoal(_goalCtrl.text.trim());
                                  _goalCtrl.clear();
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

                  // Execution Progress or Result
                  if (_isExecuting) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4F46E5)),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'AI Agent is executing multi-step reasoning cycles & action protocols...',
                              style: TextStyle(fontSize: 12, color: Color(0xFF312E81), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_latestResult != null) ...[
                    _buildResultCard(_latestResult!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(AgentExecutionResult res) {
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
                child: Text('AI-Agent Execution Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
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

  void _showPinkSlipDialog(BuildContext context) {
    final rollCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Issue Advisor Pink Slip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rollCtrl,
              decoration: const InputDecoration(
                labelText: 'Student Roll Number',
                hintText: 'e.g. 25243001',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason for Exit / Leave',
                hintText: 'e.g. Hospital Checkup / On-Duty',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final roll = rollCtrl.text.trim();
              final reason = reasonCtrl.text.trim();
              if (roll.isNotEmpty && reason.isNotEmpty) {
                try {
                  final slip = AiAgentService().issuePinkSlip(
                    rollNumber: roll,
                    reason: reason,
                    date: DateTime(2026, 9, 7),
                    issuedBy: widget.user.name,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pink Slip issued for ${slip.studentName}!'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Issue'),
          ),
        ],
      ),
    );
  }
}
