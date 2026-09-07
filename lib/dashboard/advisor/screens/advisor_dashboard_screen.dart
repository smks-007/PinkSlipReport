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
import '../../shared/widgets/storage_management_dialog.dart';

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
            onPressed: () => Navigator.pushReplacementNamed(context, '/sign-in'),
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
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.verified_user_outlined, size: 16),
                    label: const Text('Review & Endorse to HOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
      child: Row(
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
              icon: Icons.calendar_month_outlined,
              label: 'Timetable',
              color: const Color(0xFF0284C7),
              onTap: () => Navigator.pushNamed(context, '/timetable'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.assignment_outlined,
              label: 'OD & Leaves',
              color: const Color(0xFFEA580C),
              onTap: () => Navigator.pushNamed(context, '/leave-management'),
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
    );
  }

  Widget _buildStudentRosterSection(List<StudentModel> students, int totalCount, int year, String section) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
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
                      '${_currentAdvisor.classSection} Student Roster',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'All $totalCount Students Assigned',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/attendance'),
                  icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                  label: const Text('Mark 2026 Date'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search student name or roll number in ${_currentAdvisor.classSection}...',
                hintStyle: const TextStyle(fontSize: 11.5),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
              onChanged: (v) => setState(() => _studentSearchQuery = v),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: students.length > 10 ? 10 : students.length,
              itemBuilder: (context, i) {
                final s = students[i];
                final records = MockDataService.getAttendanceForDate(DateTime(2026, 9, 7), year: year, section: section);
                final studentRec = records.firstWhere((r) => r.studentId == s.id, orElse: () => records.first);

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        alignment: Alignment.center,
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text('${s.rollNumber} • ${s.gender}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: studentRec.isPresent
                              ? const Color(0xFFD1FAE5)
                              : studentRec.isOnDuty
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          studentRec.statusDisplay,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: studentRec.isPresent
                                ? const Color(0xFF047857)
                                : studentRec.isOnDuty
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (students.length > 10) ...[
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/attendance'),
                  child: Text(
                    'Open Attendance Register (${students.length} Students) ➔',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPinkSlipsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Section OD & Leave Letters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/leave-management'),
            child: const Text('Manage Letters', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPinkSlips(int year, String section) {
    final slips = MockDataService.getLeavesForSection(year, section);
    if (slips.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Text('No pending leave letters for this section', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: slips.map((slip) => _PinkSlipTile(
          leave: slip,
          onForward: () {
            setState(() {
              MockDataService.forwardToHod(slip.id, advisorRemarks: 'Endorsed by ${_currentAdvisor.name}. Forwarded to HOD.');
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Forwarded to HOD for signature! ⚡'), backgroundColor: Color(0xFF047857)),
            );
          },
        )).toList(),
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
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
  final VoidCallback onForward;

  const _PinkSlipTile({required this.leave, required this.onForward});

  @override
  Widget build(BuildContext context) {
    final isPendingWithAdvisor = leave.letterStatus == LetterStatus.submitted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  color: leave.letterStatus == LetterStatus.approved
                      ? const Color(0xFFD1FAE5)
                      : leave.letterStatus == LetterStatus.rejected
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  leave.letterStatusDisplay,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: leave.letterStatus == LetterStatus.approved
                        ? const Color(0xFF047857)
                        : leave.letterStatus == LetterStatus.rejected
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFD97706),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${leave.leaveDate.day}/${leave.leaveDate.month}/${leave.leaveDate.year}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(leave.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text('Roll: ${leave.studentRollNumber} • Reason: ${leave.reason}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          if (leave.hasAttachment) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text('${leave.attachmentFileName}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
              ],
            ),
          ],
          if (isPendingWithAdvisor) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onForward,
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text('Endorse & Forward to HOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
