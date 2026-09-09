import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/leave_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/promotion_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../core/data/student_directory_data.dart';
import '../../../core/widgets/smart_pro_logo.dart';
import '../../../chatbot/widgets/jarvis_fab.dart';
import '../../shared/widgets/letter_attachment_viewer_dialog.dart';
import '../../shared/widgets/storage_management_dialog.dart';
import '../../shared/widgets/promotion_dossier_viewer_dialog.dart';
import '../../shared/widgets/attendance_report_viewer_dialog.dart';

class HodDashboardScreen extends StatefulWidget {
  const HodDashboardScreen({super.key});

  @override
  State<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends State<HodDashboardScreen> {
  int _currentTabIndex = 0;
  int _selectedYear = 2;
  String _selectedSection = 'A';
  bool _showDepartmentGraph = false;
  String _pinkSlipFilter = 'All'; // All, Awaiting, Approved, OD, Leave, Rejected
  final TextEditingController _pinkSlipSearchCtrl = TextEditingController();
  String _pinkSlipQuery = '';

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    if (user != null && (user.id == 'hod-002' || user.name.toLowerCase().contains('kavitha'))) {
      _selectedYear = 2;
    } else {
      _selectedYear = 3;
    }
  }

  @override
  void dispose() {
    _pinkSlipSearchCtrl.dispose();
    super.dispose();
  }

  int get _awaitingCount => MockDataService.leaveRequests
      .where((l) =>
          l.letterStatus == LetterStatus.forwarded ||
          l.letterStatus == LetterStatus.submitted)
      .length;

  String get _currentHodName {
    final user = AuthService().currentUser;
    if (user != null && user.role == UserRole.hod) {
      return user.name;
    }
    return 'DR. MANIVANNAN (Ph.D.)';
  }

  String get _currentHodTitle {
    final user = AuthService().currentUser;
    if (user != null && user.role == UserRole.hod) {
      return 'Head of Department • Department of AI&DS';
    }
    return 'Head of Department • Department of AI&DS';
  }

  List<String> get _currentSections {
    if (_selectedYear == 4) return ['A', 'B'];
    return ['A', 'B', 'C', 'D'];
  }

  Map<String, dynamic> get _sectionStats {
    final strength = MockDataService.getSectionStrength(_selectedYear, _selectedSection);
    final present = MockDataService.getSectionPresent(_selectedYear, _selectedSection);
    final absent = MockDataService.getSectionAbsent(_selectedYear, _selectedSection);
    final od = MockDataService.getSectionOnDuty(_selectedYear, _selectedSection);
    final pct = MockDataService.getSectionAttendancePercentage(_selectedYear, _selectedSection);

    String advisor = 'Department Advisor';
    for (final adv in AuthService.sectionAdvisors) {
      if (adv.year == _selectedYear && adv.section == _selectedSection) {
        advisor = adv.name;
        break;
      }
    }

    return {
      'strength': strength,
      'present': present,
      'absent': absent,
      'od': od,
      'pct': double.parse(pct.toStringAsFixed(1)),
      'advisor': advisor,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: const JarvisFAB(),
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: MockDataService.changeNotifier,
          builder: (context, _, child) {
            final stats = _sectionStats;
            final defaulters = MockDataService.getAllDepartmentDefaulters();
            final pendingPromotions = MockDataService.getPendingPromotionsForHod();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(),
                  _buildAuthorityBanner(),
                  const SizedBox(height: 8),
                  _buildHODWelcomeCard(),
                  const SizedBox(height: 12),

                  // Executive Summary Banner
                  _buildExecutiveSummaryBanner(_awaitingCount, pendingPromotions.length),
                  const SizedBox(height: 14),

                  // Executive Segmented Navigation Bar
                  _buildExecutiveSegmentedNavBar(_awaitingCount, pendingPromotions.length),
                  const SizedBox(height: 16),

                  // Tab 0: Executive Overview & Analytics
                  if (_currentTabIndex == 0) ...[
                    _buildTab0Overview(stats, defaulters),
                  ]
                  // Tab 1: Section Portals & Attendance
                  else if (_currentTabIndex == 1) ...[
                    _buildTab1Sections(stats),
                  ]
                  // Tab 2: Approvals & Movement Passes
                  else if (_currentTabIndex == 2) ...[
                    _buildTab2Approvals(),
                  ]
                  // Tab 3: Academic Progression & Alumni Retention
                  else if (_currentTabIndex == 3) ...[
                    _buildTab3Progression(pendingPromotions),
                  ],

                  const SizedBox(height: 100),
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
          Row(
            children: const [
              Text(
                'SMART',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 4),
              Text(
                'PRO',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.dns_rounded, size: 22, color: Color(0xFF0284C7)),
            tooltip: 'Storage & System Health',
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

  Widget _buildAuthorityBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: const [
            Icon(Icons.verified_user_rounded, color: Color(0xFF047857), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'HOD Central Authority — Real-Time Live Sync & Attendance Verification Enabled',
                style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHODWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF38BDF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      _currentHodTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI&DS • 627 Students',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _currentHodName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Verified HOD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('V.S.B. Engineering College • Academic Term Sep-Dec 2026', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveSummaryBanner(int awaitingCount, int pendingPromotionsCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _microSummaryItem('Total Enrolled', '627', '10 Sections', const Color(0xFF6366F1)),
            Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
            _microSummaryItem('Present Today', '533', '85.0% Rate', const Color(0xFF10B981)),
            Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
            _microSummaryItem('Absentees', '94', 'Uninformed/OD', const Color(0xFFEF4444)),
            Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
            _microSummaryItem('Pending Slips', '$awaitingCount', 'HOD Action', const Color(0xFFF59E0B)),
          ],
        ),
      ),
    );
  }

  Widget _microSummaryItem(String label, String value, String sub, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildExecutiveSegmentedNavBar(int awaitingCount, int pendingPromotionsCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _buildSegmentTabItem(
              index: 0,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Overview',
              badgeCount: 0,
            ),
            _buildSegmentTabItem(
              index: 1,
              icon: Icons.domain_outlined,
              activeIcon: Icons.domain_rounded,
              label: 'Sections',
              badgeCount: 0,
            ),
            _buildSegmentTabItem(
              index: 2,
              icon: Icons.draw_outlined,
              activeIcon: Icons.draw_rounded,
              label: 'Approvals',
              badgeCount: awaitingCount,
              badgeColor: const Color(0xFFEC4899),
            ),
            _buildSegmentTabItem(
              index: 3,
              icon: Icons.school_outlined,
              activeIcon: Icons.school_rounded,
              label: 'Promotion',
              badgeCount: pendingPromotionsCount,
              badgeColor: const Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int badgeCount,
    Color badgeColor = const Color(0xFFEF4444),
  }) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        key: ValueKey('hod_tab_$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 16,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab0Overview(Map<String, dynamic> stats, List<Map<String, dynamic>> defaulters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Action Bar
        _buildQuickActionToolbar(),
        const SizedBox(height: 18),

        // Department Attendance Overview KPIs
        _buildSectionTitle('Department Live Statistics (627 Students)'),
        const SizedBox(height: 10),
        _buildDepartmentKPIs(),
        const SizedBox(height: 18),

        // Low Attendance (<75%) Alert Section
        if (defaulters.isNotEmpty) ...[
          _buildLowAttendanceAlertCard(defaulters),
          const SizedBox(height: 18),
        ],

        // Weekly Daily Attendance Trend Graph
        _buildWeeklyTrendGraphSection(),
        const SizedBox(height: 18),

        // End of Month / Monthly Attendance Progression Graph
        _buildMonthlyProgressionSection(),
      ],
    );
  }

  Widget _buildQuickActionToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '⚡ Executive Quick Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
              ),
              Text(
                'Instant HOD Operations',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _quickActionButton(
                  icon: Icons.receipt_long_rounded,
                  title: 'Issue Pink Slip',
                  subtitle: 'Movement / OD pass',
                  color: const Color(0xFFEC4899),
                  onTap: _showIssuePinkSlipModal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickActionButton(
                  icon: Icons.campaign_rounded,
                  title: 'Broadcast Notice',
                  subtitle: 'Advisors & CRs',
                  color: const Color(0xFF6366F1),
                  onTap: _showBroadcastNoticeModal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab1Sections(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Browse All 10 Sections (627 Students)'),
        const SizedBox(height: 10),
        _buildYearSelector(),
        const SizedBox(height: 8),
        _buildSectionSelector(),
        const SizedBox(height: 12),
        _buildActiveSectionCard(stats),
        const SizedBox(height: 18),
        _buildAbsenteesAndODSection(),
      ],
    );
  }

  Widget _buildTab2Approvals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildApprovalHeader(),
        const SizedBox(height: 12),
        _buildApprovalQueue(),
      ],
    );
  }

  Widget _buildTab3Progression(List<PromotionRequest> pendingPromotions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPromotionApprovalSection(),
        const SizedBox(height: 20),
        _buildAlumniRetentionSection(),
      ],
    );
  }

  void _showBroadcastNoticeModal() {
    final titleCtrl = TextEditingController(text: 'Urgent: Department Attendance & IA Review');
    final msgCtrl = TextEditingController(
      text: 'All Section Advisors and Class Representatives are requested to verify today\'s attendance muster rolls and submit defaulter lists to the HOD office by 4:00 PM.',
    );
    String audience = 'All 10 Sections (627 Students)';
    String priority = 'High Priority';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
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
                              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.campaign_rounded, color: Color(0xFF6366F1), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Broadcast Department Notice',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Target Audience
                  const Text('Target Audience', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: audience,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All 10 Sections (627 Students)', child: Text('📢 All 10 Sections (627 Students)', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'All Section Advisors (10 Faculty)', child: Text('👨‍🏫 All Section Advisors (10 Faculty)', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Class Representatives (CRs)', child: Text('⭐ Class Representatives (CRs)', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'II Year Only (2025 Batch)', child: Text('📘 II Year Only (Sec A, B, C, D)', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'III Year Only (2024 Batch)', child: Text('📗 III Year Only (Sec A, B, C, D)', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'IV Year Only (2023 Batch)', child: Text('📙 IV Year Only (Sec A, B)', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => audience = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Priority Level
                  const Text('Notice Priority & Category', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'High Priority', child: Text('🚨 Urgent / High Priority Alert', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 'Academic Circular', child: Text('📝 Academic Circular & Assessment', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Attendance Intimation', child: Text('⏱️ Attendance & Defaulter Notice', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Symposium & Events', child: Text('🏆 Symposium & Hackathon Guidelines', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => priority = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Preset Templates
                  const Text('Quick Notice Templates', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          label: const Text('Attendance Defaulters', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setModalState(() {
                              titleCtrl.text = '⚠️ Low Attendance (<75%) Parent Call';
                              msgCtrl.text = 'All students with attendance below 75% are directed to meet their Section Advisor along with their parents on Friday.';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          label: const Text('IA Mark Sheets', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setModalState(() {
                              titleCtrl.text = '📊 IA-1 Marks Submission';
                              msgCtrl.text = 'Course coordinators and section advisors are advised to upload IA-1 assessment rubrics by tomorrow evening.';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          label: const Text('Hackathon / OD Proofs', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setModalState(() {
                              titleCtrl.text = '🏆 OD Certificates & Hackathon Proofs';
                              msgCtrl.text = 'Submit participation certificates and registration proof for symposiums to the HOD portal for On-Duty leave credit.';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notice Title
                  const Text('Notice Title', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Notice Content
                  const Text('Notice Body / Instructions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Broadcast Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        final msg = msgCtrl.text.trim();
                        if (title.isEmpty || msg.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter notice title and message body.')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('📢 Notice "$title" broadcasted successfully to $audience!'),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF6366F1),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Broadcast Notice to Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  // ignore: unused_element
  void _showParentNoticeGeneratorModal() {
    final defaulters = MockDataService.getAllDepartmentDefaulters();
    StudentModel selectedStudent = defaulters.isNotEmpty
        ? (defaulters.first['student'] as StudentModel)
        : StudentDirectoryData.allStudents.first;
    double currentPct = defaulters.isNotEmpty
        ? (defaulters.first['percentage'] as double)
        : 72.4;
    String noticeFormat = 'Bilingual Absent Alert (English / Tamil)';

    final customMsgCtrl = TextEditingController();

    void updateMessageText() {
      if (noticeFormat.contains('Bilingual')) {
        customMsgCtrl.text =
            'Dear Parent, Your ward ${selectedStudent.name} (Roll: ${selectedStudent.rollNumber}, Yr ${selectedStudent.year}-${selectedStudent.section}) is absent today (07/09/2026). Kindly contact the Class Advisor.\n\n'
            'அன்புள்ள பெற்றோருக்கு, உங்கள் மகன்/மகள் ${selectedStudent.name} இன்று கல்லூரிக்கு வரவில்லை. வகுப்பு ஆலோசகரை தொடர்பு கொள்ளவும். - HOD/AI&DS, VSBEC';
      } else if (noticeFormat.contains('Low Attendance')) {
        customMsgCtrl.text =
            'VSB ENGINEERING COLLEGE - AI&DS DEPT\n'
            'Official Notice: Attendance of ${selectedStudent.name} (${selectedStudent.rollNumber}) is currently ${currentPct.toStringAsFixed(1)}%, which is below the statutory Anna University minimum 75% requirement. Please meet the HOD immediately.';
      } else {
        customMsgCtrl.text =
            'URGENT PARENT CALL:\n'
            'Parents of ${selectedStudent.name} (${selectedStudent.rollNumber}, Sec ${selectedStudent.year}-${selectedStudent.section}) are requested to attend a special counseling meeting with HOD and Section Advisor on Friday at 10:30 AM.';
      }
    }

    updateMessageText();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
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
                              color: const Color(0xFF059669).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF059669), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Parent SMS & WhatsApp Intimation',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Select Student
                  const Text('Select Student (Defaulter / Absentee)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStudent.rollNumber,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: StudentDirectoryData.allStudents.take(60).map((st) {
                      return DropdownMenuItem<String>(
                        value: st.rollNumber,
                        child: Text('${st.name} (${st.rollNumber}) • Yr ${st.year}-${st.section}', style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final st = StudentDirectoryData.byRollNumber[val];
                        if (st != null) {
                          setModalState(() {
                            selectedStudent = st;
                            final d = defaulters.firstWhere(
                              (item) => (item['student'] as StudentModel).rollNumber == st.rollNumber,
                              orElse: () => {'percentage': 74.0},
                            );
                            currentPct = (d['percentage'] as num).toDouble();
                            updateMessageText();
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Intimation Type
                  const Text('Intimation Template Format', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: noticeFormat,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Bilingual Absent Alert (English / Tamil)', child: Text('🚨 Today\'s Absent Alert (English / தமிழ்)', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Low Attendance (<75%) Warning Letter', child: Text('⚠️ Low Attendance (<75%) Warning', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Formal Parent Call for HOD Review', child: Text('📞 Urgent Parent-HOD Meeting Call', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          noticeFormat = val;
                          updateMessageText();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Generated Message Box
                  const Text('Message Body Preview', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: customMsgCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📋 Intimation message copied to clipboard!'),
                                backgroundColor: Color(0xFF334155),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy Text', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📱 SMS & WhatsApp Intimation dispatched to parents of ${selectedStudent.name}!'),
                                backgroundColor: const Color(0xFF047857),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.send_to_mobile_rounded, size: 16),
                          label: const Text('Dispatch SMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLowAttendanceAlertCard(List<Map<String, dynamic>> defaulters) {
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
                const Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ Department Defaulters Alert (< 75% Attendance)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(10)),
                  child: Text('${defaulters.length} Defaulters', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Students falling short of minimum 75% requirement. Notification sent to respective Section Advisors for parent intimation:',
              style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
            ),
            const SizedBox(height: 8),
            ...defaulters.take(4).map((d) {
              final student = d['student'] as StudentModel;
              final pct = d['percentage'] as double;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${student.name} (${student.rollNumber}) • ${student.classDisplay}',
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

  Widget _buildYearSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [2, 3, 4].map((year) {
          final isSelected = _selectedYear == year;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$year${year == 2 ? 'nd' : year == 3 ? 'rd' : 'th'} Year (${year == 2 ? "2025" : year == 3 ? "2024" : "2023"} Batch)'),
              selected: isSelected,
              selectedColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11.5),
              backgroundColor: Colors.white,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedYear = year;
                    if (year == 4 && (_selectedSection == 'C' || _selectedSection == 'D')) _selectedSection = 'A';
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _currentSections.map((sec) {
          final isSelected = _selectedSection == sec;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSection = sec),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1)),
                ),
                child: Center(
                  child: Text(sec, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveSectionCard(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Year $_selectedYear AI&DS — Section $_selectedSection', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Class Advisor: ${stats['advisor']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
                Text('${stats['pct']}%', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (stats['pct'] as double) / 100,
                minHeight: 8,
                backgroundColor: const Color(0xFFEEF2FF),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${stats['present']} Present • ${stats['od']} On-Duty', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                Text('${stats['absent']} Absent Today', style: const TextStyle(fontSize: 12, color: AppColors.absentRed, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/attendance'),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 15, color: Color(0xFF6366F1)),
                    label: Text('Edit Register (Sec $_selectedSection)', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 11.5)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => AttendanceReportViewerDialog.show(
                      context,
                      year: _selectedYear,
                      section: _selectedSection,
                    ),
                    icon: const Icon(Icons.fact_check_rounded, size: 15),
                    label: const Text('Inspect Reports & Proofs', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildWeeklyTrendGraphSection() {
    final weeklyData = _showDepartmentGraph
        ? MockDataService.getOverallDepartmentWeeklyTrend()
        : MockDataService.getWeeklyTrend(_selectedYear, _selectedSection);

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
                    const Text('📊 Last Week Attendance Graph', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      _showDepartmentGraph ? 'Overall Department Trend' : 'Year $_selectedYear Section $_selectedSection Daily Stats',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _showDepartmentGraph = !_showDepartmentGraph),
                  child: Text(
                    _showDepartmentGraph ? 'Show Section' : 'Show Dept',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Visual Bar Chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyData.map((item) {
                final isHoliday = item['isHoliday'] == true;
                final holidayReason = item['holidayReason'] as String?;
                final pct = item['percentage'] as double;
                final height = isHoliday ? 70.0 : (pct - 70) * 4.5; // Scale height
                final clampedHeight = height.clamp(24.0, 120.0);
                final label = item['label'] as String;
                final dayName = item['dayName'] ?? label.split(' ')[0];

                return GestureDetector(
                  onTap: () {
                    if (isHoliday) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFFD97706),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          content: Row(
                            children: [
                              const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '🏛️ College Declared Leave: ${holidayReason ?? "Institutional Holiday"}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isHoliday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: const Text(
                            'LEAVE',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB45309),
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        width: 32,
                        height: clampedHeight,
                        decoration: BoxDecoration(
                          gradient: isHoliday
                              ? const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24), Color(0xFFFDE68A)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                )
                              : LinearGradient(
                                  colors: pct >= 95
                                      ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                                      : pct >= 85
                                          ? [const Color(0xFF0284C7), const Color(0xFF38BDF8)]
                                          : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                          borderRadius: BorderRadius.circular(8),
                          border: isHoliday
                              ? Border.all(color: const Color(0xFFD97706), width: 1.5)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: (isHoliday ? const Color(0xFFF59E0B) : (pct >= 95 ? const Color(0xFF10B981) : const Color(0xFF0284C7)))
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: isHoliday
                            ? const Center(
                                child: Icon(
                                  Icons.celebration_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: isHoliday ? const Color(0xFFB45309) : const Color(0xFF64748B),
                          fontWeight: isHoliday ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      if (isHoliday)
                        const Text(
                          'Holiday',
                          style: TextStyle(fontSize: 8.5, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            // Institutional Legend
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGraphLegendItem(const Color(0xFF10B981), '≥95% High'),
                  _buildGraphLegendItem(const Color(0xFF0284C7), '85-94% Std'),
                  _buildGraphLegendItem(const Color(0xFFF59E0B), '🏛️ College Leave'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.block_rounded, size: 11, color: Color(0xFF94A3B8)),
                      SizedBox(width: 3),
                      Text('No Sunday', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMonthlyProgressionSection() {
    final monthlyData = MockDataService.getMonthlyTrend(_selectedYear, _selectedSection);

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
            const Text('📅 2026 Academic Term Progression (Sep-Dec)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Text('Month-by-month attendance target vs actuals', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 14),
            ...monthlyData.map((m) {
              final pct = m['percentage'] as double;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(m['month'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('${pct.toStringAsFixed(1)}% (${m["status"]})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
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

  Widget _buildAbsenteesAndODSection() {
    final records = MockDataService.getAttendanceForDate(DateTime(2026, 9, 7), year: _selectedYear, section: _selectedSection);
    final absentees = records.where((r) => r.isAbsent).toList();
    final odList = records.where((r) => r.isOnDuty).toList();
    final students = MockDataService.getStudentsBySection(_selectedYear, _selectedSection);

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
                Text('Today\'s Absentees & OD ($_selectedYear-$_selectedSection)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                  child: Text('${absentees.length} Abs · ${odList.length} OD', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (absentees.isEmpty && odList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: Text('100% Attendance today for this section! 🎉', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 12))),
              )
            else ...[
              // On-Duty students
              ...odList.map((r) {
                StudentModel? s;
                for (final st in students) {
                  if (st.id == r.studentId) {
                    s = st;
                    break;
                  }
                }
                s ??= StudentDirectoryData.allStudents.cast<StudentModel?>().firstWhere(
                  (st) => st?.id == r.studentId,
                  orElse: () => StudentModel(
                    id: r.studentId,
                    rollNumber: '25243001',
                    name: 'Student ${r.studentId}',
                    department: 'AI&DS',
                    year: _selectedYear,
                    section: _selectedSection,
                    batchYear: '${_selectedYear == 2 ? "2025" : _selectedYear == 3 ? "2024" : "2023"} BATCH',
                    advisorId: 'adv_${_selectedYear}_$_selectedSection',
                  ),
                );
                final student = s!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.badge_rounded, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 6),
                          Text('${student.name} (${student.rollNumber})', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                        ],
                      ),
                      Text(r.onDutyReason ?? 'On-Duty OD', style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }),
              // Absentees
              ...absentees.map((r) {
                StudentModel? s;
                for (final st in students) {
                  if (st.id == r.studentId) {
                    s = st;
                    break;
                  }
                }
                s ??= StudentDirectoryData.allStudents.cast<StudentModel?>().firstWhere(
                  (st) => st?.id == r.studentId,
                  orElse: () => StudentModel(
                    id: r.studentId,
                    rollNumber: '25243001',
                    name: 'Student ${r.studentId}',
                    department: 'AI&DS',
                    year: _selectedYear,
                    section: _selectedSection,
                    batchYear: '${_selectedYear == 2 ? "2025" : _selectedYear == 3 ? "2024" : "2023"} BATCH',
                    advisorId: 'adv_${_selectedYear}_$_selectedSection',
                  ),
                );
                final student = s!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_off_rounded, size: 14, color: Color(0xFFDC2626)),
                          const SizedBox(width: 6),
                          Text('${student.name} (${student.rollNumber})', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                        ],
                      ),
                      const Text('Absent (Uninformed)', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentKPIs() {
    final leaves = MockDataService.leaveRequests;
    final totalSlips = leaves.length;
    final approvedSlips = leaves.where((l) => l.letterStatus == LetterStatus.approved).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _miniKPICard(
                  'Dept Attendance',
                  '${MockDataService.attendancePercentage.toStringAsFixed(1)}%',
                  '${MockDataService.presentToday}/${MockDataService.totalStrength} Present',
                  Icons.pie_chart_outline_rounded,
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniKPICard(
                  'Total Students',
                  '${MockDataService.totalStrength}',
                  '10 AIDS Sections (627)',
                  Icons.groups_rounded,
                  const Color(0xFF0284C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniKPICard(
                  'Awaiting HOD Sign',
                  '$_awaitingCount',
                  'Digital Signature Queue',
                  Icons.hourglass_bottom_rounded,
                  AppColors.pendingOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniKPICard(
                  'Pink Slips / ODs',
                  '$totalSlips Total',
                  '$approvedSlips Signed & Active',
                  Icons.receipt_long_rounded,
                  const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniKPICard(String label, String value, String sub, IconData icon, Color color) {
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
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildApprovalHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pink Slip & Digital Approval Central',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Official Movement Passes, OD Endorsements & Digital Signatures',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _awaitingCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_awaitingCount Awaiting',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showIssuePinkSlipModal(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Issue Pink Slip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showExportRegisterDialog(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Export Register', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              if (_awaitingCount > 0) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      for (final l in MockDataService.leaveRequests) {
                        if (l.letterStatus == LetterStatus.forwarded || l.letterStatus == LetterStatus.submitted) {
                          MockDataService.approveByHod(l.id, remarks: 'Bulk authorized by HOD ($_currentHodName)');
                        }
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚡ All pending Pink Slips & ODs signed and approved by HOD!'),
                        backgroundColor: Color(0xFF047857),
                      ),
                    );
                  },
                  icon: const Icon(Icons.done_all_rounded, color: Color(0xFF059669)),
                  tooltip: 'Batch Sign All',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFD1FAE5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalQueue() {
    var leaves = MockDataService.leaveRequests;

    // Filter by Tab
    if (_pinkSlipFilter == 'Awaiting') {
      leaves = leaves.where((l) => l.letterStatus == LetterStatus.forwarded || l.letterStatus == LetterStatus.submitted).toList();
    } else if (_pinkSlipFilter == 'Approved') {
      leaves = leaves.where((l) => l.letterStatus == LetterStatus.approved).toList();
    } else if (_pinkSlipFilter == 'OD') {
      leaves = leaves.where((l) => l.isOnDuty).toList();
    } else if (_pinkSlipFilter == 'Leaves') {
      leaves = leaves.where((l) => !l.isOnDuty).toList();
    } else if (_pinkSlipFilter == 'Rejected') {
      leaves = leaves.where((l) => l.letterStatus == LetterStatus.rejected).toList();
    }

    // Filter by Query
    if (_pinkSlipQuery.isNotEmpty) {
      final q = _pinkSlipQuery.toLowerCase();
      leaves = leaves.where((l) =>
        l.studentName.toLowerCase().contains(q) ||
        l.studentRollNumber.contains(q) ||
        l.reason.toLowerCase().contains(q)
      ).toList();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', MockDataService.leaveRequests.length),
                const SizedBox(width: 8),
                _buildFilterChip('Awaiting', _awaitingCount),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', MockDataService.leaveRequests.where((l) => l.letterStatus == LetterStatus.approved).length),
                const SizedBox(width: 8),
                _buildFilterChip('OD', MockDataService.leaveRequests.where((l) => l.isOnDuty).length),
                const SizedBox(width: 8),
                _buildFilterChip('Leaves', MockDataService.leaveRequests.where((l) => !l.isOnDuty).length),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', MockDataService.leaveRequests.where((l) => l.letterStatus == LetterStatus.rejected).length),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search Bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _pinkSlipSearchCtrl,
              onChanged: (val) => setState(() => _pinkSlipQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search student name, roll number, or reason...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _pinkSlipQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _pinkSlipSearchCtrl.clear();
                          setState(() => _pinkSlipQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (leaves.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.filter_list_off_rounded, size: 36, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    Text(
                      _pinkSlipQuery.isNotEmpty
                          ? 'No pink slip records matching "$_pinkSlipQuery"'
                          : 'No pink slip records found in this category.',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ...leaves.map((leave) => _buildPinkSlipCard(leave)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _pinkSlipFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _pinkSlipFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
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

  Widget _buildPinkSlipCard(LeaveModel leave) {
    final isPending = leave.letterStatus == LetterStatus.forwarded || leave.letterStatus == LetterStatus.submitted;
    final isApproved = leave.letterStatus == LetterStatus.approved;
    final isRejected = leave.letterStatus == LetterStatus.rejected;
    final isPresent = MockDataService.isStudentPresent(leave.studentRollNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPending ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
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
          // Top Badges Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: leave.isOnDuty ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      leave.isOnDuty ? Icons.card_membership_rounded : Icons.receipt_long_rounded,
                      size: 12,
                      color: leave.isOnDuty ? const Color(0xFF2563EB) : const Color(0xFFDB2777),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      leave.isOnDuty ? 'ON-DUTY OD PASS' : 'PINK SLIP / LEAVE PASS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: leave.isOnDuty ? const Color(0xFF2563EB) : const Color(0xFFDB2777),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isApproved
                      ? const Color(0xFFD1FAE5)
                      : isRejected
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  leave.letterStatusDisplay.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isApproved
                        ? const Color(0xFF047857)
                        : isRejected
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFD97706),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${leave.leaveDate.day.toString().padLeft(2, '0')}/${leave.leaveDate.month.toString().padLeft(2, '0')}/${leave.leaveDate.year}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Student Info Row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                child: Text(
                  leave.studentName.isNotEmpty ? leave.studentName[0] : 'S',
                  style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Roll: ${leave.studentRollNumber} • Class: Year ${leave.year ?? 2}-${leave.section ?? "B"}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPresent ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isPresent ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 11,
                      color: isPresent ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPresent ? 'Present Today' : 'Absent Today',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPresent ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Reason Box
          Container(
            width: double.infinity,
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
                    const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    const Text('Reason / Movement Purpose:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  leave.reason,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),

          // Advisor Endorsement Note
          if (leave.advisorRemarks != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Advisor Endorsement: ${leave.advisorRemarks}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // HOD Digital Signature Seal (if approved)
          if (isApproved) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Digitally Signed by HOD: ${leave.hodRemarks ?? "Officially authorized and recorded in department register."}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Attached Proof Document (if any)
          if (leave.hasAttachment) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${leave.attachmentFileName}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => LetterAttachmentViewerDialog(
                          leave: leave,
                          onApproveByHod: (remarks) => setState(() => MockDataService.approveByHod(leave.id, remarks: remarks)),
                          onRejectByHod: (remarks) => setState(() => MockDataService.rejectByHod(leave.id, remarks: remarks)),
                        ),
                      );
                    },
                    child: const Text(
                      'Inspect Proof',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          // Action Buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showPinkSlipVoucherDialog(leave),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                label: const Text('View Voucher', style: TextStyle(fontSize: 11)),
              ),
              const Spacer(),
              if (isPending) ...[
                OutlinedButton(
                  onPressed: () => _showRejectRemarksDialog(leave),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.absentRed,
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('✕ Reject', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showApproveWithRemarksDialog(leave),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('✓ Sign & Approve', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────── Pink Slip Helper Modals & Actions ────────────────────

  void _showIssuePinkSlipModal() {
    final nameCtrl = TextEditingController();
    final rollCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    String passType = 'Pink Slip / Exit Pass';
    int slipYear = _selectedYear;
    String slipSection = _selectedSection;
    StudentModel? selectedStudent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
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
                            'Issue Official Pink Slip / OD',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quick Student Picker from Section
                  const Text('Select Student from Directory', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    hint: const Text('Search by Name / Roll Number', style: TextStyle(fontSize: 12)),
                    items: StudentDirectoryData.allStudents.take(50).map((st) {
                      return DropdownMenuItem<String>(
                        value: st.rollNumber,
                        child: Text('${st.name} (${st.rollNumber}) • Yr ${st.year}-${st.section}', style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final st = StudentDirectoryData.byRollNumber[val];
                        if (st != null) {
                          setModalState(() {
                            selectedStudent = st;
                            nameCtrl.text = st.name;
                            rollCtrl.text = st.rollNumber;
                            slipYear = st.year;
                            slipSection = st.section;
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Manual Student Name and Roll
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Student Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            TextField(
                              controller: nameCtrl,
                              decoration: InputDecoration(
                                hintText: 'Student Name',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Roll Number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            TextField(
                              controller: rollCtrl,
                              decoration: InputDecoration(
                                hintText: 'e.g. 25243005',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pass Type
                  const Text('Pass / Slip Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: passType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Pink Slip / Exit Pass', child: Text('🎫 Pink Slip / Campus Exit Pass', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'On-Duty (OD) Pass', child: Text('🏆 On-Duty (OD) Official Pass', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Late Entry Pass', child: Text('⏱️ Late Gate Entry Pass', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Medical Emergency Pass', child: Text('🏥 Medical / Health Center Pass', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Academic Leave Slip', child: Text('📝 Academic Approved Leave', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => passType = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Reason
                  const Text('Reason / Event Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Hackathon participation, medical clinic visit, official lab contest...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // HOD Remarks
                  const Text('HOD Authorization Remarks', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: remarksCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Officially sanctioned by HOD. Valid for entry/exit.',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final stName = nameCtrl.text.trim();
                        final stRoll = rollCtrl.text.trim();
                        final reason = reasonCtrl.text.trim().isEmpty ? 'Official Department Clearance' : reasonCtrl.text.trim();
                        final remarks = remarksCtrl.text.trim().isEmpty ? 'Authorized by HOD ($_currentHodName)' : remarksCtrl.text.trim();

                        if (stName.isEmpty || stRoll.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please specify student name and roll number.')),
                          );
                          return;
                        }

                        final isOd = passType.contains('OD') || passType.contains('On-Duty');
                        final newLeave = LeaveModel(
                          id: 'slip_${DateTime.now().millisecondsSinceEpoch}',
                          studentId: selectedStudent?.id ?? 'stu_$stRoll',
                          studentName: stName,
                          studentRollNumber: stRoll,
                          category: isOd ? LeaveCategory.onDuty : LeaveCategory.leave,
                          leaveType: LeaveType.informed,
                          reason: '$passType: $reason',
                          leaveDate: DateTime.now(),
                          letterSubmitted: true,
                          letterStatus: LetterStatus.approved,
                          year: slipYear,
                          section: slipSection,
                          advisorRemarks: 'Recommended by Class Advisor',
                          hodRemarks: remarks,
                        );

                        setState(() {
                          MockDataService.submitLeaveRequest(newLeave);
                          MockDataService.approveByHod(newLeave.id, remarks: remarks);
                        });

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 Pink Slip issued and digitally authorized for $stName!'),
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
                      icon: const Icon(Icons.verified_rounded, size: 18),
                      label: const Text('Issue & Digitally Authorize', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // College Header
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: const [
                    Text(
                      'VSB ENGINEERING COLLEGE',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'DEPARTMENT OF ARTIFICIAL INTELLIGENCE & DATA SCIENCE',
                      style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Title Ribbon
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
              const SizedBox(height: 14),

              // Voucher Details Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _voucherRow('Voucher Serial', leave.id.toUpperCase()),
                    const Divider(height: 12),
                    _voucherRow('Student Name', leave.studentName),
                    const Divider(height: 12),
                    _voucherRow('Roll / Register No', leave.studentRollNumber),
                    const Divider(height: 12),
                    _voucherRow('Class & Section', 'Year ${leave.year ?? 2} - Sec ${leave.section ?? "B"} (AI&DS)'),
                    const Divider(height: 12),
                    _voucherRow('Date Valid', '${leave.leaveDate.day}/${leave.leaveDate.month}/${leave.leaveDate.year}'),
                    const Divider(height: 12),
                    _voucherRow('Reason / Activity', leave.reason),
                    if (leave.advisorRemarks != null) ...[
                      const Divider(height: 12),
                      _voucherRow('Advisor Sign', 'Verified (${leave.advisorRemarks})'),
                    ],
                    const Divider(height: 12),
                    _voucherRow(
                      'HOD Authority',
                      leave.letterStatus == LetterStatus.approved
                          ? '✓ Digitally Signed by $_currentHodName'
                          : 'Pending Signature',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Security QR Stamp Simulation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, size: 36, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SECURE QR VALIDATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                      Text('Dept Authenticated Code: VSB-${leave.studentRollNumber}', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      const Text('Status: Official Gate / OD Clearance', style: TextStyle(fontSize: 9, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🖨️ Pink Slip sent to Department Network Printer!'),
                            backgroundColor: Color(0xFF0284C7),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Print Voucher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        SizedBox(
          width: 110,
          child: Text(key, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  void _showExportRegisterDialog() {
    final leaves = MockDataService.leaveRequests;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.menu_book_rounded, color: Color(0xFF0284C7), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Pink Slip Register',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'AI&DS Department Official Movement & OD Log Register',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  itemCount: leaves.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final l = leaves[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: l.isOnDuty ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8),
                            child: Text('${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${l.studentName} (${l.studentRollNumber})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('Yr ${l.year}-${l.section} • ${l.reason}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: l.letterStatus == LetterStatus.approved ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l.letterStatusDisplay,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: l.letterStatus == LetterStatus.approved ? const Color(0xFF047857) : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📊 Exported register as CSV!'), backgroundColor: Color(0xFF059669)),
                        );
                      },
                      icon: const Icon(Icons.table_chart_outlined, size: 16),
                      label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📄 Pink Slip Register exported as official signed PDF!'), backgroundColor: Color(0xFF0F172A)),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('Export PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  void _showApproveWithRemarksDialog(LeaveModel leave) {
    final remarksCtrl = TextEditingController(text: 'Officially approved by HOD ($_currentHodName)');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Digital Signature & Endorsement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Approving movement / OD for ${leave.studentName} (${leave.studentRollNumber}).', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            const SizedBox(height: 10),
            TextField(
              controller: remarksCtrl,
              decoration: const InputDecoration(
                labelText: 'HOD Remarks',
                border: OutlineInputBorder(),
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
                MockDataService.approveByHod(leave.id, remarks: remarksCtrl.text.trim());
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Digitally signed and approved for ${leave.studentName}!'),
                  backgroundColor: const Color(0xFF047857),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white),
            child: const Text('Sign & Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectRemarksDialog(LeaveModel leave) {
    final remarksCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Return / Reject Slip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting request for ${leave.studentName} (${leave.studentRollNumber}).', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            const SizedBox(height: 10),
            TextField(
              controller: remarksCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection / return',
                hintText: 'e.g. Insufficient documentation, low attendance threshold...',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final remarks = remarksCtrl.text.trim().isEmpty ? 'Rejected by HOD' : remarksCtrl.text.trim();
              setState(() {
                MockDataService.rejectByHod(leave.id, remarks: remarks);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request returned/rejected for ${leave.studentName}.'),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  // ──────────────────── Academic Year-End Promotion Approval Section ────────────────────

  Widget _buildPromotionApprovalSection() {
    final pendingPromotions = MockDataService.getPendingPromotionsForHod();

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
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Academic Year Progression & Promotion Queue',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '1 Sem = ~3 Months • 2 Sems/Year • 7-10 Day Grace Window Approval',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pendingPromotions.length} Batches',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (pendingPromotions.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All section batches are actively promoted and synced.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...pendingPromotions.map((prom) => _buildPromotionRequestItem(prom)),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionRequestItem(PromotionRequest prom) {
    final isGrad = prom.isGraduation;
    final isPending = prom.status == PromotionApprovalStatus.forwardedToHod || prom.status == PromotionApprovalStatus.pendingAdvisorReview;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isGrad ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isGrad ? '🎓 FINAL YEAR GRADUATION' : 'BATCH PROMOTION',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prom.promotionTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Semester Completed: Sem ${prom.semesterCompleted} (End of Academic Year)',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
          ),
          Text(
            'Evaluation Window: ${prom.graceTransitionDays}-day grace period elapsed • Total: ${prom.totalStudents} Students',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          if (prom.advisorName != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Advisor (${prom.advisorName}): ${prom.advisorRemarks ?? "Recommended for promotion."}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isGrad) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFFDC2626)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '2-Year Alumni Retention Rule: Retain active records until June 2028, then auto-purge.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => PromotionDossierViewerDialog.show(
                context,
                promotion: prom,
                onHodApprove: (r) {
                  setState(() {
                    MockDataService.hodApprovePromotion(prom.id, hodName: _currentHodName, remarks: r);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Approved! Batch successfully promoted to ${prom.toYearRoman}.'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                },
                onHodReject: (r) {
                  setState(() {
                    MockDataService.hodRejectPromotion(prom.id, remarks: r);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Promotion request returned for review.'), backgroundColor: Colors.orange),
                  );
                },
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0284C7),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.folder_open_rounded, size: 16),
              label: const Text('Inspect Batch Dossier & Credit Proofs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        MockDataService.hodRejectPromotion(prom.id, remarks: 'Returned to Advisor for re-evaluation.');
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Promotion request returned for review.'), backgroundColor: Colors.orange),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Return / Hold', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        MockDataService.hodApprovePromotion(
                          prom.id,
                          hodName: _currentHodName,
                          remarks: 'Officially approved by HOD. Academic year upgraded.',
                        );
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🎉 Approved! Batch successfully promoted to ${prom.toYearRoman}.'),
                          backgroundColor: const Color(0xFF059669),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: Text(
                      isGrad ? 'Confirm Graduation' : 'Approve & Promote',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✓ Status: ${prom.statusBadgeLabel}',
                style: const TextStyle(color: Color(0xFF065F46), fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────── 2-Year Alumni Data Retention & Auto-Purge Section ────────────────────

  Widget _buildAlumniRetentionSection() {
    final archives = MockDataService.alumniArchiveRecords;
    final activeRetention = archives.where((a) => !a.isPurged).toList();
    final purgedRecords = archives.where((a) => a.isPurged).toList();

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
                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_delete_outlined, color: Color(0xFF0F172A), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alumni Data Retention & Auto-Purge Manager',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Mandatory 2-Year Statutory Archival • Automatic Database Purging',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Metrics Cards Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Under 2-Yr Retention', style: TextStyle(color: Color(0xFF166534), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '${activeRetention.length} Graduates',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF14532D)),
                        ),
                        const Text('Active compliance vault', style: TextStyle(color: Color(0xFF15803D), fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Auto-Purged (> 2 Yrs)', style: TextStyle(color: Color(0xFF991B1B), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '${purgedRecords.length} Records',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7F1D1D)),
                        ),
                        const Text('Pruned from database', style: TextStyle(color: Color(0xFFB91C1C), fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Alumni Records List
            ...archives.map((rec) => _buildAlumniArchiveItem(rec)),

            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final count = MockDataService.triggerAlumniRetentionPurgeCheck();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(count > 0
                              ? '🧹 Auto-Purge Completed: $count expired record(s) safely pruned from active database.'
                              : '✅ Retention Check OK: All active alumni records are within the 2-year retention window.'),
                          backgroundColor: count > 0 ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                    label: const Text('Run 2-Year Retention Auto-Purge Check', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlumniArchiveItem(AlumniRetentionRecord rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(
            rec.isPurged ? Icons.delete_sweep_outlined : Icons.inventory_2_outlined,
            color: rec.isPurged ? const Color(0xFF94A3B8) : const Color(0xFF059669),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rec.studentName} (${rec.rollNumber}) • ${rec.batchYear}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    decoration: rec.isPurged ? TextDecoration.lineThrough : null,
                    color: rec.isPurged ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rec.retentionTimelineLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: rec.isPurged ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
