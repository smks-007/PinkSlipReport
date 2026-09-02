import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/leave_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/mock_data_service.dart';
import '../../shared/widgets/letter_attachment_viewer_dialog.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _rosterSearchCtrl = TextEditingController();
  String _rosterQuery = '';
  String _rosterFilter = 'All'; // All, Present, Absent
  String _leavesFilter = 'All'; // All, Leave, On-Duty

  UserModel get _currentUser =>
      AuthService().currentUser ?? AuthService.classRepresentatives[2];

  int get _sectionYear => _currentUser.year ?? 2;
  String get _sectionLetter => _currentUser.section ?? 'B';

  List<StudentModel> get _classStudents {
    final list = MockDataService.getStudentsBySection(_sectionYear, _sectionLetter);
    return list.where((s) {
      final matchesQuery = _rosterQuery.isEmpty ||
          s.name.toLowerCase().contains(_rosterQuery.toLowerCase()) ||
          s.rollNumber.contains(_rosterQuery);
      if (!matchesQuery) return false;
      if (_rosterFilter == 'Present') return s.isPresentToday;
      if (_rosterFilter == 'Absent') return !s.isPresentToday;
      return true;
    }).toList();
  }

  List<LeaveModel> get _sectionLeaves {
    final list = MockDataService.leaveRequests
        .where((l) => l.year == _sectionYear && l.section == _sectionLetter)
        .toList();
    if (_leavesFilter == 'Leave') return list.where((l) => !l.isOnDuty).toList();
    if (_leavesFilter == 'On-Duty') return list.where((l) => l.isOnDuty).toList();
    return list;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rosterSearchCtrl.dispose();
    super.dispose();
  }

  void _openSubmitLeaveDialog([StudentModel? preselectedStudent]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SubmitLeaveModal(
        year: _sectionYear,
        section: _sectionLetter,
        batchYear: _currentUser.batchYear ?? '2025 BATCH',
        students: MockDataService.getStudentsBySection(_sectionYear, _sectionLetter),
        initialStudent: preselectedStudent,
        onSubmit: (newLeave) {
          setState(() {
            MockDataService.submitLeaveRequest(newLeave);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Leave/OD submitted: '),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allStudents = MockDataService.getStudentsBySection(_sectionYear, _sectionLetter);
    final sectionLeaves = _sectionLeaves;
    final totalCount = allStudents.length;
    final presentCount = allStudents.where((s) => s.isPresentToday).length;
    final absentCount = totalCount - presentCount;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      // NOTE: Chatbot Jarvis FAB is strictly disabled & hidden for student & CR accounts
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildRepresentativeBanner(totalCount, presentCount, absentCount),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryPurple,
                indicatorWeight: 3,
                labelColor: AppColors.primaryPurple,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.people_alt_outlined, size: 19),
                    text: 'Class Roster ()',
                  ),
                  Tab(
                    icon: const Icon(Icons.attach_file_rounded, size: 19),
                    text: 'Leaves & OD ()',
                  ),
                  const Tab(
                    icon: Icon(Icons.schedule_rounded, size: 19),
                    text: 'Timetable',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRosterTab(totalCount, presentCount, absentCount),
                  _buildLettersTab(sectionLeaves),
                  _buildTimetableTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.note_add_rounded),
        label: const Text('Submit Leave / OD', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openSubmitLeaveDialog(),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'V.S.B. ENGINEERING COLLEGE',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Text(
                'AI & DS • Class Representative Portal',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            tooltip: 'Sign Out',
            onPressed: () {
              AuthService().logout();
              Navigator.pushReplacementNamed(context, '/sign-in');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRepresentativeBanner(int total, int present, int absent) {
    final pct = total > 0 ? ((present / total) * 100).toStringAsFixed(1) : '0';

    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2A55), Color(0xFF1B1938)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D2A55).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF67E8F9).withValues(alpha: 0.2),
                child: Text(
                  _currentUser.gender == 'Girl' ? '♀' : '♂',
                  style: const TextStyle(fontSize: 24, color: Color(0xFF67E8F9), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _currentUser.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF67E8F9).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF67E8F9), width: 0.8),
                          ),
                          child: Text(
                            '${_currentUser.gender ?? "Student"} CR',
                            style: const TextStyle(
                              color: Color(0xFF67E8F9),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Roll No: ${_currentUser.rollNumber ?? ""} • ${_currentUser.classSection ?? ""} (${_currentUser.batchYear ?? "2025 BATCH"})',
                      style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Class Strength', '$total', Colors.white),
                Container(height: 26, width: 1, color: Colors.white24),
                _statItem('Present Today', '$present ($pct%)', const Color(0xFF34D399)),
                Container(height: 26, width: 1, color: Colors.white24),
                _statItem('Absentees', '$absent', const Color(0xFFF87171)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
      ],
    );
  }

  Widget _buildRosterTab(int total, int present, int absent) {
    final list = _classStudents;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            controller: _rosterSearchCtrl,
            decoration: InputDecoration(
              hintText: 'Search student by name or roll number...',
              hintStyle: const TextStyle(fontSize: 12.5, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            onChanged: (val) => setState(() => _rosterQuery = val),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _filterChip('All ()', 'All'),
              const SizedBox(width: 8),
              _filterChip('Present ()', 'Present', activeColor: const Color(0xFF059669)),
              const SizedBox(width: 8),
              _filterChip('Absent ()', 'Absent', activeColor: const Color(0xFFDC2626)),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text('No students match your filter', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  physics: const BouncingScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final s = list[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.purpleSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'E. Code:  • ',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          if (!s.isPresentToday)
                            IconButton(
                              icon: const Icon(Icons.note_add_outlined, color: AppColors.primaryPurple, size: 20),
                              tooltip: 'Submit Leave for ',
                              onPressed: () => _openSubmitLeaveDialog(s),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: s.isPresentToday
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.isPresentToday ? 'Present' : 'Absent',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: s.isPresentToday
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value, {Color? activeColor}) {
    final isSelected = _rosterFilter == value;
    final color = activeColor ?? AppColors.primaryPurple;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _rosterFilter = value);
      },
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected ? color : const Color(0xFF64748B),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildTimetableTab() {
    final schedule = [
      {'period': '1', 'time': '08:45 - 09:35', 'subject': 'Machine Learning', 'code': 'AI301', 'staff': 'Mrs. S. Muthulakshmi', 'room': 'LH-204'},
      {'period': '2', 'time': '09:35 - 10:25', 'subject': 'Natural Language Processing', 'code': 'AI302', 'staff': 'Dr. M. Rajendiran', 'room': 'LH-204'},
      {'period': '3', 'time': '10:45 - 11:35', 'subject': 'Deep Learning Architectures', 'code': 'AI303', 'staff': 'Dr. D. Anandan', 'room': 'LH-204'},
      {'period': '4', 'time': '11:35 - 12:25', 'subject': 'Big Data Analytics', 'code': 'AI304', 'staff': 'Mr. A. Bharathidasan', 'room': 'LH-204'},
      {'period': '5', 'time': '01:15 - 02:05', 'subject': 'AI Project Lab (Session 1)', 'code': 'AI311', 'staff': 'Mrs. P. Kavitha / Faculty', 'room': 'AI-Lab 2'},
      {'period': '6', 'time': '02:05 - 02:55', 'subject': 'AI Project Lab (Session 2)', 'code': 'AI311', 'staff': 'Mrs. P. Kavitha / Faculty', 'room': 'AI-Lab 2'},
      {'period': '7', 'time': '03:10 - 04:00', 'subject': 'Library / Mentoring Hour', 'code': 'AI312', 'staff': 'Class Advisor', 'room': 'LH-204'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: schedule.length,
      itemBuilder: (ctx, i) {
        final item = schedule[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.purpleSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('P', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryPurple)),
                      Text('', style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['subject']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(' • ', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(item['time']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLettersTab(List<LeaveModel> leaves) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              _categoryFilterChip('All Requests', 'All'),
              const SizedBox(width: 8),
              _categoryFilterChip('Standard Leaves', 'Leave'),
              const SizedBox(width: 8),
              _categoryFilterChip('On-Duty (OD)', 'On-Duty'),
            ],
          ),
        ),
        Expanded(
          child: leaves.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No Leave or On-Duty letters found',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap "Submit Leave / OD" below to submit with file attachment.',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: leaves.length,
                  itemBuilder: (ctx, i) {
                    final l = leaves[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: l.isOnDuty ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l.categoryDisplay.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: l.isOnDuty ? const Color(0xFF2563EB) : const Color(0xFFDB2777),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusChip(l.letterStatus),
                                const Spacer(),
                                Text(
                                  '${l.leaveDate.day}/${l.leaveDate.month}/${l.leaveDate.year}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l.studentName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Roll No: ${l.studentRollNumber}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.reason,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded, size: 20, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l.attachmentFileName ?? 'Official_letter.pdf',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (dialogCtx) => LetterAttachmentViewerDialog(leave: l),
                                      );
                                    },
                                    child: const Text(
                                      'View Letter',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryPurple,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _categoryFilterChip(String label, String value) {
    final isSelected = _leavesFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _leavesFilter = value);
      },
      selectedColor: AppColors.primaryPurple.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected ? AppColors.primaryPurple : const Color(0xFF64748B),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildStatusChip(LetterStatus status) {
    Color bg;
    Color fg;
    String txt;

    switch (status) {
      case LetterStatus.notSubmitted:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        txt = 'Not Submitted';
        break;
      case LetterStatus.submitted:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        txt = 'Pending Advisor';
        break;
      case LetterStatus.forwarded:
        bg = const Color(0xFFEDE9FE);
        fg = AppColors.primaryPurple;
        txt = 'Forwarded to HOD';
        break;
      case LetterStatus.approved:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        txt = 'Approved by HOD';
        break;
      case LetterStatus.rejected:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        txt = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(txt, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}

class _SubmitLeaveModal extends StatefulWidget {
  final int year;
  final String section;
  final String batchYear;
  final List<StudentModel> students;
  final StudentModel? initialStudent;
  final ValueChanged<LeaveModel> onSubmit;

  const _SubmitLeaveModal({
    required this.year,
    required this.section,
    required this.batchYear,
    required this.students,
    this.initialStudent,
    required this.onSubmit,
  });

  @override
  State<_SubmitLeaveModal> createState() => _SubmitLeaveModalState();
}

class _SubmitLeaveModalState extends State<_SubmitLeaveModal> {
  final _formKey = GlobalKey<FormState>();
  late StudentModel _selectedStudent;
  LeaveCategory _category = LeaveCategory.leave;
  final LeaveType _type = LeaveType.informed;
  final _reasonCtrl = TextEditingController();

  String _attachedFileName = 'medical_or_od_proof.pdf';
  String _attachedFileType = 'Official Document Proof';
  String _attachedFileSize = '1.4 MB';
  bool _hasFileAttached = true;

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.initialStudent ?? (widget.students.isNotEmpty
        ? widget.students.first
        : const StudentModel(
            id: 's-demo',
            name: 'Sample Student',
            rollNumber: '25243100',
            department: 'AI&DS',
            section: 'B',
            year: 2,
            batchYear: '2025 BATCH',
            advisorId: 'adv-001',
          ));
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _simulateFilePick() {
    setState(() {
      if (_category == LeaveCategory.onDuty) {
        _attachedFileName = 'od_invitation_proof_${_selectedStudent.rollNumber}.pdf';
        _attachedFileType = 'Official OD Endorsement Letter';
        _attachedFileSize = '2.2 MB';
      } else {
        _attachedFileName = 'medical_certificate_${_selectedStudent.rollNumber}.pdf';
        _attachedFileType = 'Doctor Signed Medical Proof';
        _attachedFileSize = '1.6 MB';
      }
      _hasFileAttached = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📎 File attached: $_attachedFileName'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final newLeave = LeaveModel(
      id: 'leave-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _selectedStudent.id,
      studentName: _selectedStudent.name,
      studentRollNumber: _selectedStudent.rollNumber,
      category: _category,
      section: widget.section,
      year: widget.year,
      batchYear: widget.batchYear,
      leaveDate: DateTime.now(),
      leaveType: _type,
      reason: _reasonCtrl.text.trim(),
      letterSubmitted: true,
      letterStatus: LetterStatus.submitted,
      attachmentFileName: _hasFileAttached ? _attachedFileName : null,
      attachmentFileType: _hasFileAttached ? _attachedFileType : null,
      attachmentFileSize: _hasFileAttached ? _attachedFileSize : null,
      dateSubmittedToAdvisor: DateTime.now(),
      advisorRemarks: 'Submitted via Class Representative portal with attached file.',
      dueDays: 0,
      totalLeavesTaken: 1,
    );

    widget.onSubmit(newLeave);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Submit Leave / On-Duty Request',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Request Category',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Standard Leave')),
                      selected: _category == LeaveCategory.leave,
                      selectedColor: AppColors.primaryPurple.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: _category == LeaveCategory.leave ? AppColors.primaryPurple : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _category = LeaveCategory.leave);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('On-Duty (OD)')),
                      selected: _category == LeaveCategory.onDuty,
                      selectedColor: Colors.blue.shade100,
                      labelStyle: TextStyle(
                        color: _category == LeaveCategory.onDuty ? Colors.blue.shade800 : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _category = LeaveCategory.onDuty);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Select Student from Class',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 6),
              DropdownButtonFormField<StudentModel>(
                initialValue: _selectedStudent,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: widget.students.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text('${s.name} (${s.rollNumber})',
                        style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStudent = val);
                },
              ),
              const SizedBox(height: 16),
              const Text('Reason / Purpose of Absence or OD',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 2,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Please enter the specific reason' : null,
                decoration: InputDecoration(
                  hintText: _category == LeaveCategory.onDuty
                      ? 'e.g. Paper presentation at symposium / Anna University sports zonal'
                      : 'e.g. Viral fever / family emergency',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Official File Attachment (Proof Document)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_attachedFileName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('$_attachedFileType • $_attachedFileSize',
                              style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _simulateFilePick,
                      icon: const Icon(Icons.upload_file, size: 14),
                      label: const Text('Change File'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Submit for Advisor & HOD Review',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
