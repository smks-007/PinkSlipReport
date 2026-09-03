import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/data/student_directory_data.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/mock_data_service.dart';

/// Attendance screen for Advisors & HODs — multi-day manual attendance and absentee management.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _selectedYear = 2;
  String _selectedSection = 'B';
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  late List<AttendanceRecord> _records;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    if (user != null && user.year != null && user.section != null) {
      _selectedYear = user.year!;
      _selectedSection = user.section!;
    }
    _loadRecords();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadRecords() {
    setState(() {
      _records = MockDataService.getAttendanceForDate(
        _selectedDate,
        year: _selectedYear,
        section: _selectedSection,
      );
    });
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
      _loadRecords();
    });
  }

  void _onSectionChanged(int year, String section) {
    final user = AuthService().currentUser;
    if (user != null && user.role == UserRole.advisor) {
      // Class advisor cannot access any other year or section
      return;
    }
    setState(() {
      _selectedYear = year;
      _selectedSection = section;
      _loadRecords();
    });
  }

  void _toggleAttendance(int index) {
    final updated = _records[index].copyWith(
      isPresent: !_records[index].isPresent,
      source: 'manual',
      recordedBy: AuthService().currentUser?.name ?? 'Class Advisor',
      updatedAt: DateTime.now(),
    );

    setState(() {
      _records[index] = updated;
    });

    MockDataService.updateAttendanceRecord(
      updated,
      year: _selectedYear,
      section: _selectedSection,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Updated: ${updated.isPresent ? "Marked Present" : "Marked Absent"}',
        ),
        duration: const Duration(milliseconds: 700),
        backgroundColor: updated.isPresent ? const Color(0xFF047857) : AppColors.absentRed,
      ),
    );
  }

  void _markAllPresent() {
    final advisorName = AuthService().currentUser?.name ?? 'Class Advisor';
    MockDataService.markAllPresentForDate(
      _selectedDate,
      year: _selectedYear,
      section: _selectedSection,
      recordedBy: advisorName,
    );
    _loadRecords();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All ${_records.length} students marked Present for $_formattedDate'),
        backgroundColor: const Color(0xFF047857),
      ),
    );
  }

  String get _formattedDate {
    return '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}';
  }

  List<StudentModel> get _sectionStudents {
    return MockDataService.getStudentsBySection(_selectedYear, _selectedSection);
  }

  List<AttendanceRecord> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    return _records.where((r) {
      final student = _sectionStudents.firstWhere(
        (s) => s.id == r.studentId,
        orElse: () => StudentDirectoryData.allStudents.first,
      );
      return student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.rollNumber.contains(_searchQuery);
    }).toList();
  }

  int get _presentCount => _records.where((r) => r.isPresent).length;
  int get _absentCount => _records.where((r) => !r.isPresent).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Register',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$_selectedYear Year AI&DS - Section $_selectedSection • $_formattedDate',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primaryPurple),
            tooltip: 'Select Date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2025),
                lastDate: DateTime.now().add(const Duration(days: 7)),
              );
              if (picked != null) _onDateChanged(picked);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Section & Year Selector Bar
          _buildSectionBar(),

          // Stats bar
          _buildStatsBar(),
          const SizedBox(height: 10),

          // Search Bar & Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: AppStyles.inputDecoration(
                hintText: 'Search by student name or roll number...',
                prefixIcon: Icons.search_rounded,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Date & Quick Actions Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _markAllPresent,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Mark All Present', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusApproved,
                      side: const BorderSide(color: AppColors.statusApproved),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_calendar_rounded, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        _formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Student list
          Expanded(
            child: _filteredRecords.isEmpty
                ? const Center(
                    child: Text('No students found matching query.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = _filteredRecords[index];
                      final student = _sectionStudents.firstWhere(
                        (s) => s.id == record.studentId,
                        orElse: () => StudentDirectoryData.allStudents.first,
                      );
                      return _AttendanceTile(
                        indexNumber: index + 1,
                        name: student.name,
                        rollNumber: student.rollNumber,
                        gender: student.gender,
                        isPresent: record.isPresent,
                        source: record.source,
                        recordedBy: record.recordedBy,
                        punchIn: record.biometricPunchIn,
                        onToggle: () => _toggleAttendance(
                          _records.indexWhere((r) => r.id == record.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBar() {
    final user = AuthService().currentUser;
    final isAdvisor = user?.role == UserRole.advisor;

    if (isAdvisor) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(bottom: 8),
        color: Colors.white,
        child: Row(
          children: [
            const Icon(Icons.lock_person_rounded, size: 16, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Class Advisor Portal: $_selectedYear Year AI&DS - Section $_selectedSection (Restricted to your class)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      );
    }

    final sections = _selectedYear == 4 ? ['A', 'B'] : ['A', 'B', 'C', 'D'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('HOD Full Access', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
            ),
            // Year Chips
            const Text('Year: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ...[2, 3, 4].map((y) {
              final isSelected = _selectedYear == y;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  label: Text('$y Yr', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textPrimary)),
                  selected: isSelected,
                  selectedColor: AppColors.primaryPurple,
                  backgroundColor: const Color(0xFFF1F5F9),
                  onSelected: (selected) {
                    if (selected) _onSectionChanged(y, 'A');
                  },
                ),
              );
            }),
            const SizedBox(width: 8),
            const Text('Sec: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            // Section Chips
            ...sections.map((sec) {
              final isSelected = _selectedSection == sec;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  label: Text('Sec $sec', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textPrimary)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0284C7),
                  backgroundColor: const Color(0xFFF1F5F9),
                  onSelected: (selected) {
                    if (selected) _onSectionChanged(_selectedYear, sec);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    final pct = _records.isNotEmpty ? ((_presentCount / _records.length) * 100).toStringAsFixed(1) : '0';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _miniStat('Strength', '${_records.length}', Icons.people_rounded),
            Container(height: 30, width: 1, color: Colors.white30),
            _miniStat('Present', '$_presentCount', Icons.check_circle_rounded),
            Container(height: 30, width: 1, color: Colors.white30),
            _miniStat('Absent', '$_absentCount', Icons.cancel_rounded),
            Container(height: 30, width: 1, color: Colors.white30),
            _miniStat('Turnout', '$pct%', Icons.pie_chart_rounded),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(height: 2),
        Text(value, style: AppStyles.headingSmall.copyWith(color: Colors.white, fontSize: 16)),
        Text(label, style: AppStyles.bodySmall.copyWith(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final int indexNumber;
  final String name;
  final String rollNumber;
  final String gender;
  final bool isPresent;
  final String source;
  final String? recordedBy;
  final DateTime? punchIn;
  final VoidCallback onToggle;

  const _AttendanceTile({
    required this.indexNumber,
    required this.name,
    required this.rollNumber,
    required this.gender,
    required this.isPresent,
    required this.source,
    this.recordedBy,
    this.punchIn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPresent
              ? AppColors.statusApproved.withValues(alpha: 0.3)
              : AppColors.statusRejected.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // SNo badge
          Container(
            width: 24,
            alignment: Alignment.center,
            child: Text(
              '$indexNumber',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isPresent
                ? AppColors.statusApprovedBg
                : AppColors.statusRejectedBg,
            child: Text(
              gender == 'Female' ? '♀' : (name.isNotEmpty ? name[0] : 'S'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isPresent ? AppColors.statusApproved : AppColors.statusRejected,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppStyles.bodyLarge.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(rollNumber, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: source == 'biometric' ? const Color(0xFFF3E8FF) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        source == 'biometric' ? 'Biometric' : 'Manual',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: source == 'biometric' ? AppColors.primaryPurple : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Toggle Button
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPresent ? AppColors.statusApproved : AppColors.statusRejected,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isPresent ? AppColors.statusApproved : AppColors.statusRejected).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPresent ? 'Present' : 'Absent',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
