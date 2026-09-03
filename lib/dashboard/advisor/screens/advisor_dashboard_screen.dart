import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/leave_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../core/data/student_directory_data.dart';
import '../../shared/widgets/storage_management_dialog.dart';

/// Advisor Dashboard — Dedicated Section Portals for all 10 Section Class Advisors.
/// Supports individual section isolation, advisor details, class statistics, and full student rosters.
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
        (a) => a.id == 'adv-3d', // Default to III-D Mr. Velusamy or logged-in
        orElse: () => AuthService.sectionAdvisors.first,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = _currentAdvisor.year ?? 3;
    final section = _currentAdvisor.section ?? 'D';
    final students = StudentDirectoryData.bySection['$year-$section'] ?? [];
    final filteredStudents = students.where((s) {
      if (_studentSearchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_studentSearchQuery.toLowerCase()) ||
          s.rollNumber.contains(_studentSearchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              const SizedBox(height: 4),
              _buildAdvisorScopeBanner(),
              const SizedBox(height: 12),
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              _buildSectionTitle("Today's Section Attendance Overview"),
              const SizedBox(height: 12),
              _buildStatsGrid(year, section),
              const SizedBox(height: 20),
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 12),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildClassRepsCard(year, section),
              const SizedBox(height: 24),
              _buildStudentRosterSection(filteredStudents, students.length),
              const SizedBox(height: 24),
              _buildRecentPinkSlipsHeader(),
              const SizedBox(height: 12),
              _buildRecentPinkSlips(year, section),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.purpleSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, size: 22, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Pink',
                    style: AppStyles.headingSmall.copyWith(
                      color: AppColors.primaryPurple,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'Slip',
                    style: AppStyles.headingSmall.copyWith(
                      color: const Color(0xFF0284C7),
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  TextSpan(
                    text: 'Report',
                    style: AppStyles.headingSmall.copyWith(
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                    ),
                  ),
                ]),
              ),
              const Text(
                'Department of AI & DS • Section Advisor Portal',
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
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_person_rounded, size: 18, color: Color(0xFF475569)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Class Advisor Scope: Assigned exclusively to ${_currentAdvisor.classSection} • Department edits restricted to HOD',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
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
            colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4338CA).withValues(alpha: 0.35),
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
                    '👨‍🏫 Class Adviser Portal',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentAdvisor.classSection} (${_currentAdvisor.batchYear ?? "2026"})',
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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8),
                    borderRadius: BorderRadius.circular(10),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: AppStyles.headingMedium.copyWith(fontSize: 16, color: const Color(0xFF0F172A))),
    );
  }

  Widget _buildStatsGrid(int year, String section) {
    final strength = MockDataService.getSectionStrength(year, section);
    final present = MockDataService.getSectionPresent(year, section);
    final absent = MockDataService.getSectionAbsent(year, section);
    final percentage = MockDataService.getSectionAttendancePercentage(year, section);
    final pending = MockDataService.getSectionPendingSlips(year, section);
    final returnCheck = MockDataService.getSectionReturnCheck(year, section);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Section Attendance',
                  value: '${percentage.toStringAsFixed(2)}%',
                  subtitle: '$present/$strength Present',
                  icon: Icons.pie_chart_outline_rounded,
                  iconColor: AppColors.primaryPurple,
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
                  label: 'Pending Slips',
                  value: '$pending',
                  subtitle: 'Needs HOD/Review',
                  icon: Icons.hourglass_bottom_rounded,
                  iconColor: AppColors.pendingOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Return Check',
                  value: '$returnCheck',
                  subtitle: 'Approved & Ready',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.readyGreen,
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
              color: AppColors.primaryPurple,
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
              label: 'Pink Slip',
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

  Widget _buildClassRepsCard(int year, String section) {
    final crs = AuthService.classRepresentatives.where((c) => c.year == year && c.section == section).toList();
    final boyCr = crs.where((c) => c.gender == 'Boy').firstOrNull;
    final girlCr = crs.where((c) => c.gender == 'Girl').firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_outlined, color: AppColors.primaryPurple, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Section Class Representatives (CRs)',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('2 CRs Active', style: TextStyle(color: AppColors.primaryPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF0284C7),
                          child: Text('♂', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                boyCr?.name ?? 'Assigned Boy CR',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text('Roll: ${boyCr?.rollNumber ?? "N/A"}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFBCFE8)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFDB2777),
                          child: Text('♀', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                girlCr?.name ?? 'Assigned Girl CR',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text('Roll: ${girlCr?.rollNumber ?? "N/A"}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentRosterSection(List<StudentModel> students, int totalCount) {
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
                      'Total $totalCount Students Registered',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/attendance'),
                  icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                  label: const Text('Mark Attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
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
                hintText: 'Search student name or roll number in ${_currentAdvisor.year}-${_currentAdvisor.section}...',
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
              itemCount: students.length > 8 ? 8 : students.length,
              itemBuilder: (context, i) {
                final s = students[i];
                final isAbsent = (i == 2 || i == 5); // Sample representation
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
                            Text('${s.rollNumber} • ${s.batchYear}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAbsent ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAbsent ? 'Absent' : 'Present',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isAbsent ? const Color(0xFFDC2626) : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (students.length > 8) ...[
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/attendance'),
                  child: Text(
                    'View Complete List (${students.length} Students) in Attendance ➔',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
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
          Text('Section Pink Slips & Leave Requests', style: AppStyles.headingMedium.copyWith(fontSize: 16)),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/leave-management'),
            child: Text('View All', style: AppStyles.linkText.copyWith(color: AppColors.primaryPurple, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPinkSlips(int year, String section) {
    final slips = MockDataService.getSectionLeaves(year, section);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: slips.map((slip) => _PinkSlipTile(leave: slip)).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Private Component Widgets
// ══════════════════════════════════════════════════════════════════

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
                      fontSize: 12,
                    )),
              ),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
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
                fontSize: 11.5,
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

  const _PinkSlipTile({required this.leave});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _statusBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon, size: 18, color: _statusColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leave.studentName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${leave.studentRollNumber} • ${leave.reason}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              leave.letterStatusDisplay,
              style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (leave.letterStatus) {
      case LetterStatus.approved:
        return AppColors.statusApproved;
      case LetterStatus.rejected:
        return AppColors.statusRejected;
      case LetterStatus.forwarded:
        return AppColors.statusForwarded;
      default:
        return AppColors.statusPending;
    }
  }

  Color get _statusBgColor {
    switch (leave.letterStatus) {
      case LetterStatus.approved:
        return AppColors.statusApprovedBg;
      case LetterStatus.rejected:
        return AppColors.statusRejectedBg;
      case LetterStatus.forwarded:
        return AppColors.statusForwardedBg;
      default:
        return AppColors.statusPendingBg;
    }
  }

  IconData get _statusIcon {
    switch (leave.letterStatus) {
      case LetterStatus.approved:
        return Icons.check_circle_rounded;
      case LetterStatus.rejected:
        return Icons.cancel_rounded;
      case LetterStatus.forwarded:
        return Icons.send_rounded;
      default:
        return Icons.pending_rounded;
    }
  }
}

