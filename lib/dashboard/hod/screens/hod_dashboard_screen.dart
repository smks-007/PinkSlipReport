import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../chatbot/widgets/jarvis_fab.dart';

class HodDashboardScreen extends StatefulWidget {
  const HodDashboardScreen({super.key});

  @override
  State<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends State<HodDashboardScreen> {
  int _selectedYear = 2;
  String _selectedSection = 'B';
  int _awaitingCount = 9;

  String get _currentHodName {
    final user = AuthService().currentUser;
    if (user != null && user.role == UserRole.hod) {
      return user.name;
    }
    return (_selectedYear == 1 || _selectedYear == 2)
        ? 'Mrs. Kavitha'
        : 'Dr. Manivannan';
  }

  String get _currentHodTitle {
    return (_selectedYear == 1 || _selectedYear == 2)
        ? 'I & II Year HOD (Junior Wing)'
        : 'Overall Department HOD (III & IV Year)';
  }

  final List<Map<String, String>> _instructions = [
    {
      'scope': 'Overall Department',
      'title': 'Biometric Cut-off & 75% Exam Eligibility',
      'body': 'Gate in-time cutoff is 8:45 AM. All students must maintain a minimum of 75% overall attendance to be eligible for End Semester Examinations.',
      'date': 'Today, 8:30 AM',
      'badge': 'ALL SECTIONS',
    },
    {
      'scope': '3rd Year (All Sections)',
      'title': 'Mini-Project Phase-I Review Attendance',
      'body': 'Attendance for the upcoming Mini-Project review on Friday is strictly mandatory. No On-Duty (OD) will be sanctioned.',
      'date': 'Yesterday, 3:15 PM',
      'badge': 'III YEAR',
    },
    {
      'scope': '4th Year (Sec A & B)',
      'title': 'Campus Placement Drive OD Exemption',
      'body': 'Students attending on-campus recruitment drives must submit their OD slips endorsed by placement coordinators within 24 hours.',
      'date': '24 Aug 2026',
      'badge': 'IV YEAR',
    },
    {
      'scope': '2nd Year (Sec B)',
      'title': 'Pending Medical Letter Regularization',
      'body': 'Students with uninformed absences between 20-22 August must submit signed parent letters to Advisor Dr. M. Rajendiran / Mrs. S. Muthulakshmi by 25 August.',
      'date': '22 Aug 2026',
      'badge': 'II-B',
    },
  ];

  final List<Map<String, dynamic>> _pendingSlips = [
    {
      'id': 'p1',
      'name': 'Lithesh Hari R',
      'roll': '25243100',
      'section': 'II AI&DS - Sec B',
      'reason': 'Fees not paid (Family Discussion)',
      'advisor': 'Dr. M. Rajendiran',
      'date': '22 Aug 2026',
      'approved': null,
    },
    {
      'id': 'p2',
      'name': 'Deepika S',
      'roll': '25243044',
      'section': 'II AI&DS - Sec A',
      'reason': 'Viral fever / Hospital OPD',
      'advisor': 'Dr. D. Anandan',
      'date': '23 Aug 2026',
      'approved': null,
    },
    {
      'id': 'p3',
      'name': 'Kavya S',
      'roll': '25243072',
      'section': 'III AI&DS - Sec A',
      'reason': 'Paper Presentation at NIT',
      'advisor': 'Mrs. P. Kavitha',
      'date': '24 Aug 2026',
      'approved': null,
    },
  ];

  List<String> get _currentSections {
    if (_selectedYear == 4) return ['A', 'B'];
    return ['A', 'B', 'C', 'D'];
  }

  Map<String, dynamic> get _sectionStats {
    final key = '$_selectedYear-$_selectedSection';
    final map = {
      '1-A': {'strength': 60, 'present': 56, 'pct': 93.3, 'advisor': 'Dr. A. Saravanan'},
      '1-B': {'strength': 59, 'present': 55, 'pct': 93.2, 'advisor': 'Mrs. M. Revathi'},
      '1-C': {'strength': 60, 'present': 54, 'pct': 90.0, 'advisor': 'Mr. P. Vijay'},
      '1-D': {'strength': 59, 'present': 56, 'pct': 94.9, 'advisor': 'Mrs. T. Nandhini'},
      '2-A': {'strength': 62, 'present': 58, 'pct': 93.5, 'advisor': 'Dr. D. Anandan'},
      '2-B': {'strength': 63, 'present': 59, 'pct': 93.65, 'advisor': 'Dr. M. Rajendiran'},
      '2-C': {'strength': 61, 'present': 55, 'pct': 90.1, 'advisor': 'Mr. A. Bharathidasan'},
      '2-D': {'strength': 61, 'present': 57, 'pct': 93.4, 'advisor': 'Mr. R. Palraj'},
      '3-A': {'strength': 60, 'present': 58, 'pct': 96.6, 'advisor': 'Mrs. P. Kavitha'},
      '3-B': {'strength': 58, 'present': 53, 'pct': 91.3, 'advisor': 'Mr. S. Dinesh'},
      '3-C': {'strength': 59, 'present': 54, 'pct': 91.5, 'advisor': 'Mrs. N. Geetha'},
      '3-D': {'strength': 58, 'present': 55, 'pct': 94.8, 'advisor': 'Mr. G. Anand'},
      '4-A': {'strength': 56, 'present': 54, 'pct': 96.4, 'advisor': 'Dr. V. Sathish'},
      '4-B': {'strength': 56, 'present': 53, 'pct': 94.6, 'advisor': 'Mrs. K. Malathi'},
    };
    return map[key] ?? {'strength': 60, 'present': 56, 'pct': 93.3, 'advisor': 'Staff Advisor'};
  }

  void _approveSlip(int index, bool approve) {
    setState(() {
      _pendingSlips[index]['approved'] = approve;
      if (_awaitingCount > 0) _awaitingCount--;
    });
  }

  void _showAddInstructionDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String scope = 'Overall Department';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Post Department Instruction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Target Scope:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: scope,
                  decoration: AppStyles.inputDecoration(hintText: 'Scope', prefixIcon: Icons.campaign_rounded),
                  items: const [
                    DropdownMenuItem(value: 'Overall Department', child: Text('Overall Department')),
                    DropdownMenuItem(value: '1st Year (All Sections)', child: Text('1st Year (All Sections)')),
                    DropdownMenuItem(value: '2nd Year (All Sections)', child: Text('2nd Year (All Sections)')),
                    DropdownMenuItem(value: '3rd Year (All Sections)', child: Text('3rd Year (All Sections)')),
                    DropdownMenuItem(value: '4th Year (All Sections)', child: Text('4th Year (All Sections)')),
                    DropdownMenuItem(value: 'Specific: II-AIDS-B', child: Text('Specific: II-AIDS-B')),
                  ],
                  onChanged: (v) => setDialogState(() => scope = v!),
                ),
                const SizedBox(height: 14),
                const Text('Title / Subject:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(controller: titleCtrl, decoration: AppStyles.inputDecoration(hintText: 'e.g. Exam Attendance Cutoff', prefixIcon: Icons.title_rounded)),
                const SizedBox(height: 14),
                const Text('Instruction Body:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(controller: bodyCtrl, maxLines: 3, decoration: AppStyles.inputDecoration(hintText: 'Enter instructions...', prefixIcon: Icons.description_rounded)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  _instructions.insert(0, {
                    'scope': scope,
                    'title': titleCtrl.text.trim(),
                    'body': bodyCtrl.text.trim(),
                    'date': 'Just Now',
                    'badge': scope.contains('Overall') ? 'ALL' : 'TARGETED',
                  });
                });
                Navigator.pop(ctx);
              },
              child: const Text('Broadcast', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _sectionStats;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      floatingActionButton: const JarvisFAB(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              _buildAuthorityBanner(),
              const SizedBox(height: 6),
              _buildHODWelcomeCard(),
              const SizedBox(height: 20),
              _buildSectionTitle('Browse All 14 Sections'),
              const SizedBox(height: 10),
              _buildYearSelector(),
              const SizedBox(height: 8),
              _buildSectionSelector(),
              const SizedBox(height: 12),
              _buildActiveSectionCard(stats),
              const SizedBox(height: 24),
              _buildSectionTitle('Department Attendance Overview'),
              const SizedBox(height: 12),
              _buildDepartmentKPIs(),
              const SizedBox(height: 24),
              _buildInstructionHeader(),
              const SizedBox(height: 12),
              _buildInstructionCards(),
              const SizedBox(height: 24),
              _buildApprovalHeader(),
              const SizedBox(height: 12),
              _buildApprovalQueue(),
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
            decoration: BoxDecoration(color: AppColors.purpleSurface, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.description_outlined, size: 20, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(children: [
              TextSpan(text: 'Pink', style: AppStyles.headingSmall.copyWith(color: AppColors.primaryPurple, fontSize: 18)),
              TextSpan(text: 'SlipReport', style: AppStyles.headingSmall.copyWith(color: AppColors.primaryPurple, fontWeight: FontWeight.w400, fontSize: 18)),
            ]),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.notifications_none_rounded, size: 26), onPressed: () {}),
          IconButton(icon: const Icon(Icons.logout_rounded, size: 24), onPressed: () => Navigator.pushReplacementNamed(context, '/sign-in')),
        ],
      ),
    );
  }

  Widget _buildAuthorityBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFA7F3D0))),
        child: Row(
          children: const [
            Icon(Icons.verified_user_rounded, color: Color(0xFF047857), size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('HOD Full Authority — View, Edit, Delete & Instructions Enabled', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.w700, fontSize: 11.5))),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0369A1), Color(0xFF0284C7)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text(_currentHodTitle, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Text('AI & DS (14 Sections)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_currentHodName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
                    const PopupMenuItem(
                      value: 'kavitha',
                      child: Text('Mrs. Kavitha (1st & 2nd Year HOD)'),
                    ),
                    const PopupMenuItem(
                      value: 'manivannan',
                      child: Text('Dr. Manivannan (Overall HOD)'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('V.S.B. Engineering College, Karur', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: AppStyles.headingMedium.copyWith(fontSize: 17)),
    );
  }

  Widget _buildYearSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [1, 2, 3, 4].map((year) {
          final isSelected = _selectedYear == year;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$year${year == 1 ? 'st' : year == 2 ? 'nd' : year == 3 ? 'rd' : 'th'} Year'),
              selected: isSelected,
              selectedColor: AppColors.primaryPurple,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryPurple : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppColors.primaryPurple : const Color(0xFFBAE6FD)),
                ),
                child: Center(
                  child: Text(sec, style: TextStyle(color: isSelected ? Colors.white : AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 14)),
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Year $_selectedYear AI&DS — Section $_selectedSection', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Advisor: ${stats['advisor']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Text('${stats['pct']}%', style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: (stats['pct'] as double) / 100, minHeight: 8, backgroundColor: const Color(0xFFE0F2FE), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple)),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${stats['present']} / ${stats['strength']} Present', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('${(stats['strength'] as int) - (stats['present'] as int)} Absent Today', style: const TextStyle(fontSize: 12, color: AppColors.absentRed, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/timetable'),
                icon: const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.primaryPurple),
                label: Text(
                  'View Timetable (Sec $_selectedSection)',
                  style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryPurple),
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

  Widget _buildDepartmentKPIs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _miniKPICard('Dept Attendance', '91.8%', '418/455 Present', Icons.pie_chart_outline_rounded, AppColors.primaryPurple)),
              const SizedBox(width: 12),
              Expanded(child: _miniKPICard('Total Sections', '14', '1st-4th Years', Icons.grid_view_rounded, AppColors.primaryPurple)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniKPICard('Awaiting HOD', '$_awaitingCount', 'Final Signature', Icons.hourglass_bottom_rounded, AppColors.pendingOrange)),
              const SizedBox(width: 12),
              Expanded(child: _miniKPICard('Escalated', '2', 'Overdue >48h', Icons.flag_rounded, AppColors.absentRed)),
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
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildInstructionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Department Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          TextButton.icon(
            onPressed: _showAddInstructionDialog,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primaryPurple),
            label: const Text('Post Notice', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _instructions.map((inst) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
                      child: Text(inst['badge']!, style: const TextStyle(color: AppColors.primaryPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Text(inst['date']!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(inst['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(inst['body']!, style: const TextStyle(color: Colors.black87, fontSize: 12, height: 1.4)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildApprovalHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Needs Your Final Approval', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          TextButton(
            onPressed: () {
              for (int i = 0; i < _pendingSlips.length; i++) {
                _approveSlip(i, true);
              }
            },
            child: const Text('Approve All', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalQueue() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _pendingSlips.asMap().entries.map((entry) {
          final idx = entry.key;
          final slip = entry.value;
          final isResolved = slip['approved'] != null;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFFEF3C7),
                      child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(slip['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${slip['roll']} • ${slip['section']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Reason: ${slip['reason']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Text('Forwarded by: ${slip['advisor']} on ${slip['date']}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                const SizedBox(height: 12),
                if (!isResolved)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _approveSlip(idx, false),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.absentRed, side: const BorderSide(color: Color(0xFFFCA5A5))),
                          child: const Text('✕ Reject'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approveSlip(idx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                          child: const Text('✓ Approve', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: slip['approved'] == true ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        slip['approved'] == true ? '✓ Approved & Signed by HOD' : '✕ Rejected by HOD',
                        style: TextStyle(color: slip['approved'] == true ? const Color(0xFF047857) : AppColors.absentRed, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
