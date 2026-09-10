import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/leave_model.dart';
import '../../../core/models/promotion_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../core/data/student_directory_data.dart';
import '../../../core/widgets/smart_pro_logo.dart';
import '../../shared/widgets/create_pink_slip_dialog.dart';
import '../../shared/widgets/storage_management_dialog.dart';
import '../../shared/widgets/letter_attachment_viewer_dialog.dart';
import '../../shared/widgets/promotion_dossier_viewer_dialog.dart';
import '../../shared/widgets/attendance_report_viewer_dialog.dart';

/// Advisor Dashboard — Dedicated Section Portals for all 10 Section Class Advisors.
/// Supports section isolation, full student roster, leave/OD forwarding to HOD, and <75% low attendance alerts.
class AdvisorDashboardScreen extends StatefulWidget {
  const AdvisorDashboardScreen({super.key});

  @override
  State<AdvisorDashboardScreen> createState() => _AdvisorDashboardScreenState();
}

class _AdvisorDashboardScreenState extends State<AdvisorDashboardScreen> {
  late UserModel _currentAdvisor;
  String _studentSearchQuery = '';
  String _pinkSlipSectionFilter = 'My Class'; // 'My Class', 'All 10 Sections', 'II Year', 'III Year', 'IV Year'
  String _pinkSlipStatusFilter = 'All'; // 'All', 'Pending Review', 'Forwarded to HOD', 'Approved', 'Rejected'
  String _pinkSlipSearchQuery = '';
  final TextEditingController _pinkSlipSearchCtrl = TextEditingController();

  @override
  void dispose() {
    _pinkSlipSearchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final loggedIn = AuthService().currentUser;
    if (loggedIn != null && loggedIn.role == UserRole.advisor) {
      _currentAdvisor = loggedIn;
    } else {
      _currentAdvisor = AuthService.sectionAdvisors.firstWhere(
        (a) => a.id == 'adv-2a', // Default to II-A Dr. Anandhan
        orElse: () => AuthService.sectionAdvisors.first,
      );
    }
  }

  void _openCreatePinkSlipDialog({StudentModel? student}) async {
    final result = await showDialog<LeaveModel>(
      context: context,
      builder: (ctx) => CreatePinkSlipDialog(
        initialStudent: student,
        initialDate: DateTime.now(),
      ),
    );
    if (result != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = _currentAdvisor.year ?? 2;
    final section = _currentAdvisor.section ?? 'A';
    final students = StudentDirectoryData.bySection['$year-$section'] ?? [];
    final filteredStudents = students.where((s) {
      if (_studentSearchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_studentSearchQuery.toLowerCase()) ||
          s.rollNumber.contains(_studentSearchQuery);
    }).toList();

    final defaulters = MockDataService.getDefaultersBySection(year, section);
    final pendingPromotions = MockDataService.getPendingPromotionsForAdvisor(year, section);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_issue_pink_slip',
        onPressed: () => _openCreatePinkSlipDialog(),
        icon: const Icon(Icons.note_add_rounded, size: 18),
        label: const Text('Issue Pink Slip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: MockDataService.changeNotifier,
          builder: (context, _, child) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(),
                  _buildAdvisorScopeBanner(),
                  const SizedBox(height: 12),
                  _buildWelcomeCard(),
                  const SizedBox(height: 20),

                  // Academic Year-End Promotion Review Card (7-10 Day Grace Window)
                  if (pendingPromotions.isNotEmpty) ...[
                    _buildAdvisorPromotionCard(pendingPromotions.first, year, section),
                    const SizedBox(height: 20),
                  ],

                  // Low Attendance (<75%) Alert Banner
                  if (defaulters.isNotEmpty) ...[
                    _buildDefaulterAlertCard(defaulters),
                    const SizedBox(height: 20),
                  ],

                  _buildSectionTitle("Today's Section Attendance Overview"),
                  const SizedBox(height: 12),
                  _buildStatsGrid(year, section),
                  const SizedBox(height: 20),

                  _buildSectionTitle('Quick Actions'),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Full Class Student Roster
                  _buildStudentRosterSection(filteredStudents, students.length, year, section),
                  const SizedBox(height: 24),

                  _buildRecentPinkSlipsHeader(),
                  const SizedBox(height: 12),
                  _buildRecentPinkSlips(year, section),
                  const SizedBox(height: 60),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const SmartProLogo(size: 32, showText: false),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'SMART',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'PRO',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const Text(
                'Dept of AI & DS • Class Advisor Portal',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.dns_rounded, size: 22, color: Color(0xFF0284C7)),
            tooltip: 'Storage Telemetry & Data Center',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const StorageManagementDialog(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22, color: Color(0xFFEF4444)),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444)))),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                await AuthService().logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/sign-in');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisorScopeBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_person_rounded, size: 18, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Class Advisor Scope: Assigned exclusively to ${_currentAdvisor.classSection} • Cross-section edits restricted to HOD',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF312E81),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF312E81).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '👨‍🏫 Class Advisor Portal',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_currentAdvisor.classSection} (${_currentAdvisor.batchYear ?? "2025 BATCH"})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Welcome back, Class Advisor',
              style: TextStyle(fontSize: 12.5, color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _currentAdvisor.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '@${_currentAdvisor.username}',
                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_currentAdvisor.email} • ${_currentAdvisor.college}',
              style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisorPromotionCard(PromotionRequest promotion, int year, String section) {
    final isGrad = promotion.isGraduation;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
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
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                  ),
                  child: const Icon(Icons.school_rounded, color: Color(0xFF38BDF8), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SEM 2 COMPLETED',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${promotion.graceTransitionDays}-Day Grace Period Elapsed',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isGrad ? 'Graduation & Alumni Archival Ready' : 'Year-End Class Promotion Ready',
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Eligible Promotion', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          promotion.promotionTitle,
                          style: const TextStyle(color: Color(0xFF7DD3FC), fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Students', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        '${promotion.totalStudents} Students',
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF7DD3FC)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.folder_open_rounded, size: 15),
                    label: const Text('Inspect Dossier & Proofs', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: () => PromotionDossierViewerDialog.show(
                      context,
                      promotion: promotion,
                      onAdvisorForward: () => _showAdvisorPromotionDialog(promotion),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.verified_user_outlined, size: 15),
                    label: const Text('Endorse to HOD', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: () => _showAdvisorPromotionDialog(promotion),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvisorPromotionDialog(PromotionRequest promotion) {
    final remarksCtrl = TextEditingController(text: promotion.advisorRemarks ?? 'All students cleared academic credits & attendance criteria. Verified for promotion.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.school_rounded, color: Color(0xFF0284C7)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Endorse Academic Promotion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target: ${promotion.promotionTitle}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0369A1)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completed: Semester ${promotion.semesterCompleted} (Academic Term End)',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF0C4A6E)),
                      ),
                      Text(
                        'Evaluation Window: ${promotion.graceTransitionDays} days elapsed post 2nd Sem',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF0C4A6E)),
                      ),
                      Text(
                        'Total Batch Strength: ${promotion.totalStudents} Active Students',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF0C4A6E)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Advisor Clearance Checklist:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                _buildChecklistRow('✅ Semester 1 & 2 Credits verified'),
                _buildChecklistRow('✅ Attendance cutoff minimums validated'),
                _buildChecklistRow('✅ Lab/Practical examination clearance recorded'),
                if (promotion.isGraduation)
                  _buildChecklistRow('✅ 2-Year Alumni Data Retention Policy acknowledged'),
                const SizedBox(height: 14),
                const Text(
                  'Advisor Endorsement Remarks to HOD:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: remarksCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Enter endorsement notes for HOD...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Forward to HOD', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              MockDataService.advisorForwardPromotion(
                promotion.id,
                advisorName: _currentAdvisor.name,
                remarks: remarksCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Successfully forwarded ${promotion.promotionTitle} promotion to HOD for final approval.'),
                  backgroundColor: const Color(0xFF059669),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
    );
  }

  Widget _buildDefaulterAlertCard(List<Map<String, dynamic>> defaulters) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ Low Attendance Alert (< 75% Cutoff)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${defaulters.length} Students',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The following students are currently below 75% exam cutoff. Please intimate parents and collect pending leave/medical letters:',
              style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
            ),
            const SizedBox(height: 8),
            ...defaulters.map((d) {
              final student = d['student'] as StudentModel;
              final pct = d['percentage'] as double;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${student.name} (${student.rollNumber})',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => AttendanceReportViewerDialog.show(
                  context,
                  year: _currentAdvisor.year ?? 2,
                  section: _currentAdvisor.section ?? 'A',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF991B1B),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.mark_email_read_rounded, size: 14),
                label: const Text('View Parent Intimation Letters & Defaulter Register', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: AppStyles.headingMedium.copyWith(fontSize: 15, color: const Color(0xFF0F172A))),
    );
  }

  Widget _buildStatsGrid(int year, String section) {
    final strength = MockDataService.getSectionStrength(year, section);
    final present = MockDataService.getSectionPresent(year, section);
    final absent = MockDataService.getSectionAbsent(year, section);
    final od = MockDataService.getSectionOnDuty(year, section);
    final percentage = MockDataService.getSectionAttendancePercentage(year, section);
    final pending = MockDataService.getLeavesForSection(year, section).where((l) => l.letterStatus == LetterStatus.submitted).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Section Attendance',
                  value: '${percentage.toStringAsFixed(1)}%',
                  subtitle: '$present/$strength Present ($od OD)',
                  icon: Icons.pie_chart_outline_rounded,
                  iconColor: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Absentees',
                  value: '$absent',
                  subtitle: 'Students Today',
                  icon: Icons.person_off_outlined,
                  iconColor: AppColors.absentRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'On-Duty (OD)',
                  value: '$od',
                  subtitle: 'Symposium / Sports',
                  icon: Icons.badge_rounded,
                  iconColor: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Pending Slips',
                  value: '$pending',
                  subtitle: 'Needs Forwarding',
                  icon: Icons.hourglass_bottom_rounded,
                  iconColor: AppColors.pendingOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [

          // Primary Pink Slip Forwarder Action Banner
          InkWell(
            onTap: () => _showForwardAbsenteePinkSlipModal(),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF831843), Color(0xFFBE185D), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFBE185D).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '🎫 Forward Absentee / Issue Pink Slip',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Scan Hospital Proof • Review Previous Leaves • Endorse to HOD',
                          style: TextStyle(color: Color(0xFFFCE7F3), fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.fact_check_outlined,
                  label: 'Attendance',
                  color: const Color(0xFF6366F1),
                  onTap: () => Navigator.pushNamed(context, '/attendance'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Pink Slip',
                  color: const Color(0xFFEC4899),
                  onTap: () => _showForwardAbsenteePinkSlipModal(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.calendar_month_outlined,
                  label: 'Timetable',
                  color: const Color(0xFF0284C7),
                  onTap: () => Navigator.pushNamed(context, '/timetable'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.dns_outlined,
                  label: 'Storage',
                  color: const Color(0xFF059669),
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => const StorageManagementDialog(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRosterSection(
    List<StudentModel> filteredStudents,
    int totalCount,
    int year,
    String section,
  ) {
    final presentCount = MockDataService.getSectionPresent(year, section);
    final absentCount = MockDataService.getSectionAbsent(year, section);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class Roster (Yr $year-$section)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '$totalCount Enrolled • $presentCount Present • $absentCount Absent Today',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Text(
                  '${filteredStudents.length} Shown',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _studentSearchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search student name or roll number...',
                hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                suffixIcon: _studentSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 14),
                        onPressed: () => setState(() => _studentSearchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          if (filteredStudents.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'No students found matching search.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredStudents.length > 10 ? 10 : filteredStudents.length,
              itemBuilder: (context, index) {
                final st = filteredStudents[index];
                final isAbsent = MockDataService.isStudentAbsent(st.rollNumber);
                final isPresent = MockDataService.isStudentPresent(st.rollNumber);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAbsent ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isAbsent
                            ? const Color(0xFFFEE2E2)
                            : isPresent
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFEFF6FF),
                        child: Text(
                          st.name.isNotEmpty ? st.name[0] : 'S',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isAbsent
                                ? const Color(0xFFDC2626)
                                : isPresent
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              st.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Roll: ${st.rollNumber} • Yr ${st.year}-${st.section} • ${st.totalLeavesTaken} Leaves Taken',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAbsent
                              ? const Color(0xFFFEE2E2)
                              : isPresent
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAbsent
                              ? '🔴 Absent'
                              : isPresent
                                  ? '🟢 Present'
                                  : '🔵 On-Duty',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isAbsent
                                ? const Color(0xFFDC2626)
                                : isPresent
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Issue / Forward Pink Slip',
                        icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFFEC4899), size: 18),
                        onPressed: () => _showForwardAbsenteePinkSlipModal(st),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (filteredStudents.length > 10)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${filteredStudents.length - 10} more students in section (use search to find specific student)',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────── Forward Absentee & Scan Proof Modal ────────────────────

  void _showForwardAbsenteePinkSlipModal([StudentModel? preselectedStudent]) {
    final year = _currentAdvisor.year ?? 2;
    final section = _currentAdvisor.section ?? 'A';
    final sectionStudents = StudentDirectoryData.bySection['$year-$section'] ?? [];
    
    // Find section absentees
    final absentStudents = sectionStudents.where((s) => MockDataService.todaysAbsentRollNumbers.contains(s.rollNumber)).toList();
    final availableStudents = absentStudents.isNotEmpty ? absentStudents : sectionStudents;

    StudentModel currentStudent = preselectedStudent ?? (availableStudents.isNotEmpty ? availableStudents.first : sectionStudents.first);
    
    String leaveCategory = 'Medical Leave';
    String leaveInformedType = 'Informed Leave';
    DateTime selectedDate = DateTime(2026, 9, 7);
    final reasonCtrl = TextEditingController(text: 'Severe viral fever & OPD medical checkup');
    final remarksCtrl = TextEditingController(text: 'Verified hospital OPD certificate and confirmed with parent. Forwarded to HOD for approval.');
    
    // Proof attachment state
    String? attachedFileName = 'hospital_medical_certificate.pdf';
    String? attachedFileType = 'Medical Certificate (GH/Apollo)';
    String? attachedFileSize = '1.8 MB';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isAbsentToday = MockDataService.isStudentAbsent(currentStudent.rollNumber);
          final previousLeaves = currentStudent.totalLeavesTaken;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFEC4899), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Forward Absentee Pink Slip to HOD',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Student Picker
                  const Text('Select Absent Student', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: currentStudent.rollNumber,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: sectionStudents.map((st) {
                      final isAbs = MockDataService.todaysAbsentRollNumbers.contains(st.rollNumber);
                      return DropdownMenuItem<String>(
                        value: st.rollNumber,
                        child: Text(
                          '${st.name} (${st.rollNumber}) ${isAbs ? "🔴 [ABSENT TODAY]" : "🟢 [Present]"}',
                          style: TextStyle(fontSize: 11.5, fontWeight: isAbs ? FontWeight.bold : FontWeight.normal),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final st = StudentDirectoryData.byRollNumber[val];
                        if (st != null) {
                          setModalState(() => currentStudent = st);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Student Telemetry Badges Box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Today Status', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(
                              isAbsentToday ? '🔴 Absent Today' : '🟢 Present Today',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isAbsentToday ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                        Container(height: 20, width: 1, color: const Color(0xFFCBD5E1)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Previous Leaves', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(
                              '$previousLeaves Days Taken',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        Container(height: 20, width: 1, color: const Color(0xFFCBD5E1)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Class Roster', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(
                              'Yr ${currentStudent.year}-${currentStudent.section}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Leave Category & Intimation Type Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              initialValue: leaveCategory,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Medical Leave', child: Text('🏥 Medical Leave', style: TextStyle(fontSize: 11.5))),
                                DropdownMenuItem(value: 'On-Duty OD', child: Text('🏆 On-Duty (OD)', style: TextStyle(fontSize: 11.5))),
                                DropdownMenuItem(value: 'Campus Pink Slip', child: Text('🎫 Campus Pink Slip', style: TextStyle(fontSize: 11.5))),
                                DropdownMenuItem(value: 'Casual Leave', child: Text('📝 Casual Leave', style: TextStyle(fontSize: 11.5))),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => leaveCategory = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Intimation Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              initialValue: leaveInformedType,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Informed Leave', child: Text('✅ Informed (Parent Call)', style: TextStyle(fontSize: 11.5))),
                                DropdownMenuItem(value: 'Uninformed Absence', child: Text('⚠️ Uninformed (Proof)', style: TextStyle(fontSize: 11.5))),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => leaveInformedType = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Reason & Suggestion Chips
                  const Text('Absence Reason / Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: reasonCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Hospitalization & viral fever, Smart India Hackathon final round...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _suggestionChip('🏥 Hospital & Fever', reasonCtrl, setModalState),
                        _suggestionChip('🏆 SIH Hackathon', reasonCtrl, setModalState),
                        _suggestionChip('🦷 Dental Clinic', reasonCtrl, setModalState),
                        _suggestionChip('🏏 Zonal Sports', reasonCtrl, setModalState),
                        _suggestionChip('👨‍👩‍👦 Family Function', reasonCtrl, setModalState),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Document Proof Capture / Scanning Section ──
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.document_scanner_rounded, size: 18, color: Color(0xFF16A34A)),
                            const SizedBox(width: 8),
                            const Text(
                              'Proof Document (Hospital / OD Certificate)',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (attachedFileName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attachedFileName!,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        '$attachedFileType • $attachedFileSize',
                                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('✓ Attached', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showProofPicker(
                                    onSelect: (name, type, size) {
                                      setModalState(() {
                                        attachedFileName = name;
                                        attachedFileType = type;
                                        attachedFileSize = size;
                                      });
                                    },
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF166534),
                                  side: const BorderSide(color: Color(0xFF86EFAC)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.camera_alt_outlined, size: 14),
                                label: const Text('Capture / Scan Proof', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showProofPicker(
                                    onSelect: (name, type, size) {
                                      setModalState(() {
                                        attachedFileName = name;
                                        attachedFileType = type;
                                        attachedFileSize = size;
                                      });
                                    },
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0284C7),
                                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.attach_file_rounded, size: 14),
                                label: const Text('Attach Document', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Advisor Recommendation Remarks
                  const Text('Advisor Endorsement Remarks for HOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: remarksCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Verified hospital slip and parent confirmation. Recommended for HOD approval.',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Submit Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final isOd = leaveCategory.contains('OD') || leaveCategory.contains('On-Duty');
                        final isInformed = leaveInformedType.contains('Informed');

                        final newLeave = LeaveModel(
                          id: 'ps_${DateTime.now().millisecondsSinceEpoch}',
                          studentId: currentStudent.id,
                          studentName: currentStudent.name,
                          studentRollNumber: currentStudent.rollNumber,
                          category: isOd ? LeaveCategory.onDuty : LeaveCategory.leave,
                          leaveType: isInformed ? LeaveType.informed : LeaveType.uninformed,
                          reason: '${leaveCategory.toUpperCase()}: ${reasonCtrl.text.trim()}',
                          leaveDate: selectedDate,
                          letterSubmitted: attachedFileName != null,
                          letterStatus: LetterStatus.forwarded,
                          attachmentFileName: attachedFileName,
                          attachmentFileType: attachedFileType,
                          attachmentFileSize: attachedFileSize,
                          dateSubmittedToAdvisor: DateTime.now(),
                          dateReceivedByHod: DateTime.now(),
                          advisorId: _currentAdvisor.id,
                          advisorRemarks: remarksCtrl.text.trim(),
                          year: currentStudent.year,
                          section: currentStudent.section,
                          batchYear: currentStudent.batchYear,
                          totalLeavesTaken: previousLeaves + 1,
                        );

                        setState(() {
                          MockDataService.submitLeaveRequest(newLeave);
                        });

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 Pink Slip & Proof for ${currentStudent.name} successfully forwarded to HOD!'),
                            backgroundColor: const Color(0xFF047857),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Forward Pink Slip & Proof to HOD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _suggestionChip(String label, TextEditingController ctrl, StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.zero,
        onPressed: () {
          setModalState(() {
            ctrl.text = label.replaceAll(RegExp(r'[^\w\s]'), '').trim();
          });
        },
      ),
    );
  }

  void _showProofPicker({required Function(String, String, String) onSelect}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Capture / Attach Document Proof', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_hospital_rounded, color: Colors.red),
              title: const Text('Apollo / GH Hospital Discharge Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('medical_discharge_apollo_hospital.pdf (1.8 MB)', style: TextStyle(fontSize: 10.5)),
              onTap: () {
                onSelect('medical_discharge_apollo_hospital.pdf', 'Hospital Discharge Summary', '1.8 MB');
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.medical_services_rounded, color: Colors.green),
              title: const Text('Government Hospital Fitness Certificate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('gh_medical_fitness_certificate.pdf (1.2 MB)', style: TextStyle(fontSize: 10.5)),
              onTap: () {
                onSelect('gh_medical_fitness_certificate.pdf', 'Medical Fitness Certificate (GH)', '1.2 MB');
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
              title: const Text('Smart India Hackathon Shortlist Letter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('sih_hackathon_finalist_invitation.pdf (2.4 MB)', style: TextStyle(fontSize: 10.5)),
              onTap: () {
                onSelect('sih_hackathon_finalist_invitation.pdf', 'SIH Finalist Invitation', '2.4 MB');
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.sports_cricket_rounded, color: Colors.blue),
              title: const Text('Anna University Zonal Sports OD Letter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('zonal_sports_board_od_letter.pdf (1.5 MB)', style: TextStyle(fontSize: 10.5)),
              onTap: () {
                onSelect('zonal_sports_board_od_letter.pdf', 'Sports Board OD Proof', '1.5 MB');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────── Pink Slip Viewer for All Years and Sections ────────────────────

  Widget _buildRecentPinkSlipsHeader() {
    final leaves = MockDataService.leaveRequests;
    final pendingCount = leaves.where((l) => l.letterStatus == LetterStatus.submitted).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pink Slip & OD Management',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Review all 10 sections • Inspect proofs • Accept or Reject',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showForwardAbsenteePinkSlipModal(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 15),
                    label: const Text('Forward Slip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/leave-management'),
                    child: Text('View All', style: AppStyles.linkText.copyWith(color: AppColors.primaryPurple, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Section Selector Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSectionFilterChip('My Class', 'My Class (Yr ${_currentAdvisor.year ?? 2}-${_currentAdvisor.section ?? "A"})'),
                const SizedBox(width: 8),
                _buildSectionFilterChip('All 10 Sections', 'All 10 Sections (627)'),
                const SizedBox(width: 8),
                _buildSectionFilterChip('II Year', 'II Year (A-D)'),
                const SizedBox(width: 8),
                _buildSectionFilterChip('III Year', 'III Year (A-D)'),
                const SizedBox(width: 8),
                _buildSectionFilterChip('IV Year', 'IV Year (A-B)'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip('All', leaves.length),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Pending Review', pendingCount),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Forwarded to HOD', leaves.where((l) => l.letterStatus == LetterStatus.forwarded).length),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Approved by HOD', leaves.where((l) => l.letterStatus == LetterStatus.approved).length),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Rejected', leaves.where((l) => l.letterStatus == LetterStatus.rejected).length),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search Bar
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _pinkSlipSearchCtrl,
              onChanged: (val) => setState(() => _pinkSlipSearchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search student name, roll number, or reason...',
                hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                suffixIcon: _pinkSlipSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () {
                          _pinkSlipSearchCtrl.clear();
                          setState(() => _pinkSlipSearchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionFilterChip(String key, String label) {
    final isSelected = _pinkSlipSectionFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _pinkSlipSectionFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, int count) {
    final isSelected = _pinkSlipStatusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _pinkSlipStatusFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPinkSlips(int year, String section) {
    var slips = MockDataService.leaveRequests;

    // Filter by Section Scope
    if (_pinkSlipSectionFilter == 'My Class') {
      slips = slips.where((l) => l.year == year && l.section == section).toList();
    } else if (_pinkSlipSectionFilter == 'II Year') {
      slips = slips.where((l) => l.year == 2).toList();
    } else if (_pinkSlipSectionFilter == 'III Year') {
      slips = slips.where((l) => l.year == 3).toList();
    } else if (_pinkSlipSectionFilter == 'IV Year') {
      slips = slips.where((l) => l.year == 4).toList();
    }

    // Filter by Status
    if (_pinkSlipStatusFilter == 'Pending Review') {
      slips = slips.where((l) => l.letterStatus == LetterStatus.submitted).toList();
    } else if (_pinkSlipStatusFilter == 'Forwarded to HOD') {
      slips = slips.where((l) => l.letterStatus == LetterStatus.forwarded).toList();
    } else if (_pinkSlipStatusFilter == 'Approved by HOD') {
      slips = slips.where((l) => l.letterStatus == LetterStatus.approved).toList();
    } else if (_pinkSlipStatusFilter == 'Rejected') {
      slips = slips.where((l) => l.letterStatus == LetterStatus.rejected).toList();
    }

    // Filter by Search Query
    if (_pinkSlipSearchQuery.isNotEmpty) {
      final q = _pinkSlipSearchQuery.toLowerCase();
      slips = slips.where((l) =>
        l.studentName.toLowerCase().contains(q) ||
        l.studentRollNumber.contains(q) ||
        l.reason.toLowerCase().contains(q)
      ).toList();
    }

    if (slips.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.inbox_outlined, size: 36, color: Color(0xFF94A3B8)),
                const SizedBox(height: 6),
                Text(
                  _pinkSlipSearchQuery.isNotEmpty
                      ? 'No pink slips matching "$_pinkSlipSearchQuery"'
                      : 'No pink slip records in this filter view.',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: slips.map((slip) => _PinkSlipTile(
          leave: slip,
          onAcceptAndForward: () => _showAdvisorRemarksDialog(slip, isForward: true),
          onRejectProposal: () => _showAdvisorRemarksDialog(slip, isForward: false),
          onViewVoucher: () => _showPinkSlipVoucherDialog(slip),
        )).toList(),
      ),
    );
  }

  void _showAdvisorRemarksDialog(LeaveModel leave, {required bool isForward}) {
    final remarksCtrl = TextEditingController(
      text: isForward
          ? 'Medical proof & parent intimation verified by Class Advisor ${_currentAdvisor.name}. Recommended for HOD approval.'
          : 'Returned to student by Class Advisor for lack of valid proof.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isForward ? 'Endorse & Forward to HOD' : 'Return / Reject Proposal',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isForward ? const Color(0xFF047857) : const Color(0xFFDC2626),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isForward ? "Endorsing" : "Rejecting"} proposal for ${leave.studentName} (${leave.studentRollNumber}).',
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: remarksCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isForward ? 'Advisor Endorsement Remarks' : 'Reason for rejection',
                border: const OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (isForward) {
                  MockDataService.forwardToHod(leave.id, advisorRemarks: remarksCtrl.text.trim());
                } else {
                  MockDataService.rejectByAdvisor(leave.id, remarks: remarksCtrl.text.trim());
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isForward
                      ? '✓ Proposal endorsed and forwarded to HOD for ${leave.studentName}!'
                      : 'Proposal returned for ${leave.studentName}.'),
                  backgroundColor: isForward ? const Color(0xFF047857) : const Color(0xFFDC2626),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isForward ? const Color(0xFF047857) : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(isForward ? 'Confirm & Forward' : 'Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  void _showPinkSlipVoucherDialog(LeaveModel leave) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: const [
                    Text('VSB ENGINEERING COLLEGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                    SizedBox(height: 2),
                    Text('DEPARTMENT OF ARTIFICIAL INTELLIGENCE & DATA SCIENCE', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: leave.isOnDuty ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: leave.isOnDuty ? const Color(0xFFBFDBFE) : const Color(0xFFFBCFE8)),
                ),
                child: Text(
                  leave.isOnDuty ? 'OFFICIAL ON-DUTY (OD) PASS' : 'OFFICIAL PINK SLIP / MOVEMENT VOUCHER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: leave.isOnDuty ? const Color(0xFF1D4ED8) : const Color(0xFFBE185D),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _voucherRow('Voucher Serial', leave.id.toUpperCase()),
                    const Divider(height: 10),
                    _voucherRow('Student Name', leave.studentName),
                    const Divider(height: 10),
                    _voucherRow('Roll Number', leave.studentRollNumber),
                    const Divider(height: 10),
                    _voucherRow('Section', 'Yr ${leave.year ?? 2}-${leave.section ?? "A"} (AI&DS)'),
                    const Divider(height: 10),
                    _voucherRow('Previous Leaves', '${leave.totalLeavesTaken} Days Taken'),
                    const Divider(height: 10),
                    _voucherRow('Reason', leave.reason),
                    if (leave.advisorRemarks != null) ...[
                      const Divider(height: 10),
                      _voucherRow('Advisor Sign', 'Verified (${leave.advisorRemarks})'),
                    ],
                    const Divider(height: 10),
                    _voucherRow(
                      'HOD Authority',
                      leave.letterStatus == LetterStatus.approved
                          ? '✓ Digitally Authorized'
                          : leave.letterStatus == LetterStatus.forwarded
                              ? 'Forwarded to HOD for Signature'
                              : 'Pending Advisor Endorsement',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🖨️ Pink Slip Voucher sent to printer!'), backgroundColor: Color(0xFF0284C7)),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                      icon: const Icon(Icons.print_rounded, size: 14),
                      label: const Text('Print Voucher', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _voucherRow(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 105, child: Text(key, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    )),
              ),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinkSlipTile extends StatelessWidget {
  final LeaveModel leave;
  final VoidCallback onAcceptAndForward;
  final VoidCallback onRejectProposal;
  final VoidCallback onViewVoucher;

  const _PinkSlipTile({
    required this.leave,
    required this.onAcceptAndForward,
    required this.onRejectProposal,
    required this.onViewVoucher,
  });

  @override
  Widget build(BuildContext context) {
    final isPendingWithAdvisor = leave.letterStatus == LetterStatus.submitted;
    final isApproved = leave.letterStatus == LetterStatus.approved;
    final isRejected = leave.letterStatus == LetterStatus.rejected;
    final isForwarded = leave.letterStatus == LetterStatus.forwarded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPendingWithAdvisor ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: leave.isOnDuty ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  leave.categoryDisplay.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: leave.isOnDuty ? const Color(0xFF2563EB) : const Color(0xFFDB2777),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isApproved
                      ? const Color(0xFFD1FAE5)
                      : isRejected
                          ? const Color(0xFFFEE2E2)
                          : isForwarded
                              ? const Color(0xFFE0E7FF)
                              : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  leave.letterStatusDisplay,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isApproved
                        ? const Color(0xFF047857)
                        : isRejected
                            ? const Color(0xFFDC2626)
                            : isForwarded
                                ? const Color(0xFF4338CA)
                                : const Color(0xFFD97706),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${leave.leaveDate.day.toString().padLeft(2, '0')}/${leave.leaveDate.month.toString().padLeft(2, '0')}/${leave.leaveDate.year}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(leave.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
          Text(
            'Roll: ${leave.studentRollNumber} • Class: Yr ${leave.year ?? 2}-${leave.section ?? "A"} • Prev Leaves: ${leave.totalLeavesTaken} Days',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Reason: ${leave.reason}',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
            ),
          ),
          if (leave.hasAttachment) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${leave.attachmentFileName}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => LetterAttachmentViewerDialog(
                          leave: leave,
                          onForwardToHod: onAcceptAndForward,
                        ),
                      );
                    },
                    child: const Text('Inspect Proof', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                  ),
                ],
              ),
            ),
          ],
          if (leave.advisorRemarks != null) ...[
            const SizedBox(height: 6),
            Text(
              'Advisor Note: ${leave.advisorRemarks}',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontStyle: FontStyle.italic),
            ),
          ],
          if (leave.hodRemarks != null) ...[
            const SizedBox(height: 4),
            Text(
              'HOD Digital Stamp: ${leave.hodRemarks}',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onViewVoucher,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.receipt_outlined, size: 13),
                label: const Text('View Voucher', style: TextStyle(fontSize: 10.5)),
              ),
              const Spacer(),
              if (isPendingWithAdvisor) ...[
                OutlinedButton(
                  onPressed: onRejectProposal,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('✕ Reject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onAcceptAndForward,
                  icon: const Icon(Icons.send_rounded, size: 13),
                  label: const Text('✓ Endorse & Forward', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
