import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/leave_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/promotion_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../core/widgets/smart_pro_logo.dart';
import '../../../chatbot/widgets/jarvis_fab.dart';
import '../../shared/widgets/letter_attachment_viewer_dialog.dart';
import '../../shared/widgets/storage_management_dialog.dart';

class HodDashboardScreen extends StatefulWidget {
  const HodDashboardScreen({super.key});

  @override
  State<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends State<HodDashboardScreen> {
  int _selectedYear = 2;
  String _selectedSection = 'A';
  bool _showDepartmentGraph = false;

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
    return (_selectedYear == 1 || _selectedYear == 2)
        ? 'Mrs. Kavitha'
        : 'DR. MANIVANNAN (Ph.D.)';
  }

  String get _currentHodTitle {
    return (_selectedYear == 1 || _selectedYear == 2)
        ? 'I & II Year HOD (Junior Wing)'
        : 'Overall Department HOD (III & IV Year)';
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

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(),
                  _buildAuthorityBanner(),
                  const SizedBox(height: 8),
                  _buildHODWelcomeCard(),
                  const SizedBox(height: 20),

                  // Low Attendance (<75%) Alert Section
                  if (defaulters.isNotEmpty) ...[
                    _buildLowAttendanceAlertCard(defaulters),
                    const SizedBox(height: 20),
                  ],

                  _buildSectionTitle('Browse All 10 Sections (622 Students)'),
                  const SizedBox(height: 10),
                  _buildYearSelector(),
                  const SizedBox(height: 8),
                  _buildSectionSelector(),
                  const SizedBox(height: 12),
                  _buildActiveSectionCard(stats),
                  const SizedBox(height: 24),

                  // Weekly Daily Attendance Trend Graph
                  _buildWeeklyTrendGraphSection(),
                  const SizedBox(height: 24),

                  // End of Month / Monthly Attendance Progression Graph
                  _buildMonthlyProgressionSection(),
                  const SizedBox(height: 24),

                  // Today's Absentees & On-Duty Students with Proof Attachment Viewer
                  _buildAbsenteesAndODSection(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Department Attendance Overview'),
                  const SizedBox(height: 12),
                  _buildDepartmentKPIs(),
                  const SizedBox(height: 24),

                  // Academic Year-End Promotion & Progression Batch Queue
                  _buildPromotionApprovalSection(),
                  const SizedBox(height: 24),

                  // 2-Year Alumni Data Retention & Automated Database Purge Manager
                  _buildAlumniRetentionSection(),
                  const SizedBox(height: 24),

                  _buildApprovalHeader(),
                  const SizedBox(height: 12),
                  _buildApprovalQueue(),
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
                  'AI&DS • 622 Students',
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
                Text(_currentHodName, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
                  tooltip: 'Switch HOD Profile',
                  onSelected: (val) {
                    setState(() {
                      if (val == 'kavitha') {
                        AuthService().switchHod(AuthService.juniorHod);
                        _selectedYear = 2;
                      } else {
                        AuthService().switchHod(AuthService.overallHod);
                        _selectedYear = 3;
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'kavitha', child: Text('Mrs. Kavitha (1st & 2nd Year HOD)')),
                    const PopupMenuItem(value: 'manivannan', child: Text('Dr. Manivannan (Overall HOD)')),
                  ],
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/attendance'),
                icon: const Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFF6366F1)),
                label: Text('Open Full Attendance Register (Sec $_selectedSection)', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12.5)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
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
                final s = students.firstWhere((st) => st.id == r.studentId, orElse: () => students.first);
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
                          Text('${s.name} (${s.rollNumber})', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                        ],
                      ),
                      Text(r.onDutyReason ?? 'On-Duty OD', style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }),
              // Absentees
              ...absentees.map((r) {
                final s = students.firstWhere((st) => st.id == r.studentId, orElse: () => students.first);
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
                          Text('${s.name} (${s.rollNumber})', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _miniKPICard('Dept Attendance', '${MockDataService.attendancePercentage.toStringAsFixed(1)}%', '${MockDataService.presentToday}/${MockDataService.totalStrength} Present', Icons.pie_chart_outline_rounded, const Color(0xFF6366F1))),
              const SizedBox(width: 12),
              Expanded(child: _miniKPICard('Total Students', '${MockDataService.totalStrength}', '10 AIDS Sections (622)', Icons.groups_rounded, const Color(0xFF0284C7))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniKPICard('Awaiting HOD', '$_awaitingCount', 'Digital Signature', Icons.hourglass_bottom_rounded, AppColors.pendingOrange)),
              const SizedBox(width: 12),
              Expanded(child: _miniKPICard('Defaulters (<75%)', '${MockDataService.getAllDepartmentDefaulters().length}', 'Notified to Advisors', Icons.flag_rounded, AppColors.absentRed)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniKPICard(String label, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildApprovalHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Needs Your Final Signature ($_awaitingCount)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
          TextButton(
            onPressed: () {
              setState(() {
                for (final l in MockDataService.leaveRequests) {
                  if (l.letterStatus == LetterStatus.forwarded || l.letterStatus == LetterStatus.submitted) {
                    MockDataService.approveByHod(l.id);
                  }
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All pending requests approved by HOD! ⚡'), backgroundColor: Color(0xFF047857)),
              );
            },
            child: const Text('Approve All', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalQueue() {
    final leaves = MockDataService.leaveRequests;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: leaves.map((leave) {
          final isPending = leave.letterStatus == LetterStatus.forwarded || leave.letterStatus == LetterStatus.submitted;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: leave.isOnDuty ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        leave.categoryDisplay.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: leave.isOnDuty ? const Color(0xFF2563EB) : const Color(0xFFDB2777)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          fontSize: 10,
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
                    Text('${leave.leaveDate.day}/${leave.leaveDate.month}/${leave.leaveDate.year}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(leave.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Roll: ${leave.studentRollNumber} • Class: Year ${leave.year ?? 2} - Sec ${leave.section ?? "B"}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 6),
                Text('Reason: ${leave.reason}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                if (leave.advisorRemarks != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Advisor Endorsement: ${leave.advisorRemarks}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                  ),
                if (leave.hodRemarks != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('HOD Remarks: ${leave.hodRemarks}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                  ),
                if (leave.hasAttachment) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${leave.attachmentFileName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
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
                          child: const Text('Inspect Proof', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => MockDataService.rejectByHod(leave.id)),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.absentRed, side: const BorderSide(color: Color(0xFFFCA5A5))),
                          child: const Text('✕ Reject'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => MockDataService.approveByHod(leave.id)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white),
                          child: const Text('✓ Approve'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }).toList(),
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
