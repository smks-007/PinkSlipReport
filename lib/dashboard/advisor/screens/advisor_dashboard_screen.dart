import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/leave_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/mock_data_service.dart';
import '../../shared/widgets/storage_management_dialog.dart';

/// Advisor Dashboard — matches the provided design.
/// Shows attendance overview, quick actions, recent pink slips.
class AdvisorDashboardScreen extends StatefulWidget {
  const AdvisorDashboardScreen({super.key});

  @override
  State<AdvisorDashboardScreen> createState() => _AdvisorDashboardScreenState();
}

class _AdvisorDashboardScreenState extends State<AdvisorDashboardScreen> {
  UserModel get _advisor => AuthService().currentUser ?? AuthService.advisor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              const SizedBox(height: 8),
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildSectionTitle("Today's Attendance Overview"),
              const SizedBox(height: 12),
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 12),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRecentPinkSlipsHeader(),
              const SizedBox(height: 12),
              _buildRecentPinkSlips(),
              const SizedBox(height: 100),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.purpleSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_outlined,
                size: 20, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Pink',
                style: AppStyles.headingSmall.copyWith(
                  color: AppColors.primaryPurple,
                  fontSize: 18,
                ),
              ),
              TextSpan(
                text: 'Slip',
                style: AppStyles.headingSmall.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
              ),
              TextSpan(
                text: 'Report',
                style: AppStyles.headingSmall.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
              ),
            ]),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.dns_rounded, size: 22, color: Color(0xFF0284C7)),
            tooltip: 'Storage & Data Center',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const StorageManagementDialog(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 26),
            color: AppColors.textPrimary,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 24),
            color: AppColors.textPrimary,
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/sign-in'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: AppStyles.welcomeCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.statusApproved,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _advisor.roleBadge,
                    style: AppStyles.chipText.copyWith(color: Colors.white),
                  ),
                ),
                Text(
                  _advisor.classSection ?? '',
                  style: AppStyles.bodyOnPurple.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Welcome back,',
              style: AppStyles.bodyOnPurple,
            ),
            const SizedBox(height: 2),
            Text(
              _advisor.name,
              style: AppStyles.headingOnPurple.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              _advisor.college,
              style: AppStyles.bodyOnPurple.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: AppStyles.headingMedium.copyWith(fontSize: 18)),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Attendance',
                  value: '${MockDataService.attendancePercentage.toStringAsFixed(2)}%',
                  subtitle: '${MockDataService.presentToday}/${MockDataService.totalStrength} Present',
                  icon: Icons.pie_chart_outline_rounded,
                  iconColor: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Absentees',
                  value: '${MockDataService.absentToday}',
                  subtitle: 'Students',
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
                  value: '${MockDataService.pendingSlips}',
                  subtitle: 'Needs HOD',
                  icon: Icons.hourglass_bottom_rounded,
                  iconColor: AppColors.pendingOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Return Check',
                  value: '${MockDataService.returnCheckReady}',
                  subtitle: 'Ready',
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
              color: AppColors.primaryPurple,
              onTap: () => Navigator.pushNamed(context, '/timetable'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.assignment_outlined,
              label: 'Pink Slip',
              color: AppColors.primaryPurple,
              onTap: () => Navigator.pushNamed(context, '/leave-management'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.download_rounded,
              label: 'Reports',
              color: AppColors.primaryPurple,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPinkSlipsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Recent Pink Slips',
              style: AppStyles.headingMedium.copyWith(fontSize: 18)),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/leave-management'),
            child: Text('View All',
                style: AppStyles.linkText
                    .copyWith(color: AppColors.primaryPurple)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPinkSlips() {
    final recentSlips = MockDataService.leaveRequests.take(4).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: recentSlips.map((slip) => _PinkSlipTile(leave: slip)).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Private Widgets
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
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.statCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    )),
              ),
              Icon(icon, size: 22, color: iconColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: AppStyles.statValue),
          const SizedBox(height: 2),
          Text(subtitle, style: AppStyles.statLabel),
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _statusBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon, size: 20, color: _statusColor),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leave.studentName,
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${leave.studentRollNumber} • ${leave.reason}',
                  style: AppStyles.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              leave.letterStatusDisplay,
              style: AppStyles.chipText.copyWith(color: _statusColor),
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
