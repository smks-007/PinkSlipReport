import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/leave_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/mock_data_service.dart';
import '../../shared/widgets/create_pink_slip_dialog.dart';

/// Attendance screen for Advisors & HODs — supports 2026 Academic Calendar (Sep-Dec),
/// date-wise manual attendance marking with Present, Absent, and On-Duty (OD) states.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _selectedYear = 2;
  String _selectedSection = 'A';
  int _selectedMonth = 9; // 9 = September, 10 = October, 11 = November, 12 = December 2026
  DateTime _selectedDate = DateTime(2026, 9, 7); // Default to current date in 2026
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

  void _openCreatePinkSlipDialog({StudentModel? student, bool? markPresent}) async {
    final result = await showDialog<LeaveModel>(
      context: context,
      builder: (ctx) => CreatePinkSlipDialog(
        initialStudent: student,
        initialDate: _selectedDate,
        initialMarkPresent: markPresent ?? false,
      ),
    );
    if (result != null) {
      _loadRecords();
    }
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
      _selectedMonth = date.month;
      _loadRecords();
    });
  }

  void _onMonthChanged(int month) {
    setState(() {
      _selectedMonth = month;
      _selectedDate = DateTime(2026, month, 1);
      _loadRecords();
    });
  }

  void _onSectionChanged(int year, String section) {
    final user = AuthService().currentUser;
    if (user != null && user.role == UserRole.advisor) {
      // Class advisor cannot switch to other sections
      return;
    }
    setState(() {
      _selectedYear = year;
      _selectedSection = section;
      _loadRecords();
    });
  }

  void _setStatus(int index, AttendanceStatus newStatus, {String? odReason, String? typedLetter}) {
    final advisorName = AuthService().currentUser?.name ?? 'Class Advisor';
    final updated = _records[index].copyWith(
      status: newStatus,
      source: 'manual',
      recordedBy: advisorName,
      onDutyReason: odReason,
      typedLetter: typedLetter,
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
          'Updated: ${updated.statusDisplay}',
        ),
        duration: const Duration(milliseconds: 600),
        backgroundColor: updated.isPresent
            ? const Color(0xFF047857)
            : updated.isOnDuty
                ? const Color(0xFF2563EB)
                : AppColors.absentRed,
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

  void _markAllAbsent() {
    final advisorName = AuthService().currentUser?.name ?? 'Class Advisor';
    MockDataService.markAllAbsentForDate(
      _selectedDate,
      year: _selectedYear,
      section: _selectedSection,
      recordedBy: advisorName,
    );
    _loadRecords();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked all students as Absent for $_formattedDate'),
        backgroundColor: AppColors.absentRed,
      ),
    );
  }

  void _showOnDutyDialog(int recordIndex, StudentModel student) {
    final reasonCtrl = TextEditingController(text: _records[recordIndex].onDutyReason ?? '');
    final letterCtrl = TextEditingController(text: _records[recordIndex].typedLetter ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.badge_rounded, color: Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mark On-Duty (OD)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${student.name} (${student.rollNumber})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OD Reason / Event Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: 'Technical Symposium / Paper Presentation',
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'Technical Symposium / Paper Presentation', child: Text('Symposium / Paper Presentation', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Smart India Hackathon (SIH)', child: Text('Smart India Hackathon (SIH)', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Zonal / State Sports Tournament', child: Text('Sports / Athletic Tournament', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Campus Recruitment / Placement Drive', child: Text('Placement / Technical Interview', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'NPTEL / Anna University Exam Duty', child: Text('NPTEL / University Exam Duty', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Other Official Duty', child: Text('Other Official Duty', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (v) {
                  if (v != null) reasonCtrl.text = v;
                },
              ),
              const SizedBox(height: 12),
              const Text('Explanation / Letter Words:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: letterCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter student on-duty details, organizing college, and endorsement...',
                  hintStyle: const TextStyle(fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _setStatus(
                recordIndex,
                AttendanceStatus.onDuty,
                odReason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : 'Symposium / OD Event',
                typedLetter: letterCtrl.text.trim(),
              );
            },
            child: const Text('Save On-Duty'),
          ),
        ],
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
        orElse: () => MockDataService.allStudents.first,
      );
      return student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.rollNumber.contains(_searchQuery);
    }).toList();
  }

  int get _presentCount => _records.where((r) => r.isPresent).length;
  int get _absentCount => _records.where((r) => r.isAbsent).length;
  int get _onDutyCount => _records.where((r) => r.isOnDuty).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Register (2026)',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '$_selectedYear Year AI&DS - Section $_selectedSection • $_formattedDate',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, size: 22, color: Color(0xFF6366F1)),
            tooltip: '2026 Academic Calendar (Sep-Dec)',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2026, 9, 1),
                lastDate: DateTime(2026, 12, 31),
                helpText: 'SELECT 2026 ACADEMIC WORKING DATE',
              );
              if (picked != null) _onDateChanged(picked);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Section Access & Year Selector Bar
          _buildSectionBar(),

          // 2026 Academic Calendar Month Selector
          _buildMonthTabs(),

          // Horizontal Date Selector Strip for Active Month
          _buildDateStrip(),

          // Live Stats Bar (Strength, Present, Absent, OD, Turnout)
          _buildStatsBar(),
          const SizedBox(height: 10),

          // Search Bar & Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search student name or roll number (e.g. 25243001)...',
                hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF6366F1)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Quick Action Buttons (Mark All Present, Mark All Absent)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _markAllPresent,
                    icon: const Icon(Icons.check_circle_outline, size: 15),
                    label: const Text('Mark All Present', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _markAllAbsent,
                    icon: const Icon(Icons.cancel_outlined, size: 15),
                    label: const Text('Mark All Absent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.absentRed,
                      side: const BorderSide(color: AppColors.absentRed),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _openCreatePinkSlipDialog(),
                  icon: const Icon(Icons.receipt_long_rounded, size: 14),
                  label: const Text('Issue Pink Slip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          if (MockDataService.isCollegeHoliday(_selectedDate))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🏛️ College Declared Leave / Holiday',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          MockDataService.getCollegeHolidayReason(_selectedDate) ?? 'Official Institutional Holiday • Attendance Exempted',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // Student Attendance List with 3-way toggle (Present, Absent, On-Duty)
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
                        orElse: () => MockDataService.allStudents.first,
                      );
                      final recordIdx = _records.indexWhere((r) => r.id == record.id);

                      return _AttendanceTile(
                        indexNumber: index + 1,
                        name: student.name,
                        rollNumber: student.rollNumber,
                        gender: student.gender,
                        status: record.status,
                        source: record.source,
                        onDutyReason: record.onDutyReason,
                        recordedBy: record.recordedBy,
                        punchIn: record.biometricPunchIn,
                        onSetPresent: () => _setStatus(recordIdx, AttendanceStatus.present),
                        onSetAbsent: () => _setStatus(recordIdx, AttendanceStatus.absent),
                        onSetOnDuty: () => _showOnDutyDialog(recordIdx, student),
                        onPinkSlip: () => _openCreatePinkSlipDialog(
                          student: student,
                          markPresent: !record.isPresent,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: MockDataService.academicMonths2026.map((m) {
          final isSelected = _selectedMonth == m['month'];
          return InkWell(
            onTap: () => _onMonthChanged(m['month'] as int),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                m['short'] as String,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateStrip() {
    final dates = MockDataService.getDatesForMonth(_selectedMonth);

    return Container(
      height: 68,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: dates.length,
        itemBuilder: (ctx, i) {
          final d = dates[i];
          final isSelected = d.day == _selectedDate.day && d.month == _selectedDate.month;
          final isHoliday = MockDataService.isCollegeHoliday(d);
          final dayName = MockDataService.getDayAbbreviation(d.weekday);

          return GestureDetector(
            onTap: () => _onDateChanged(d),
            child: Container(
              width: 52,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isHoliday ? const Color(0xFFD97706) : const Color(0xFF0F172A))
                    : (isHoliday ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (isHoliday ? const Color(0xFFF59E0B) : const Color(0xFF0284C7))
                      : (isHoliday ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isHoliday ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                        ),
                      ),
                      if (isHoliday) ...[
                        const SizedBox(width: 2),
                        const Icon(Icons.celebration_rounded, size: 9, color: Color(0xFFD97706)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isHoliday ? const Color(0xFF92400E) : const Color(0xFF0F172A)),
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

  Widget _buildSectionBar() {
    final user = AuthService().currentUser;
    final isAdvisor = user?.role == UserRole.advisor;

    if (isAdvisor) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFFEEF2FF),
        child: Row(
          children: [
            const Icon(Icons.lock_person_rounded, size: 16, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Class Advisor: $_selectedYear Year AI&DS - Section $_selectedSection (Restricted Access)',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF312E81)),
              ),
            ),
          ],
        ),
      );
    }

    final sections = _selectedYear == 4 ? ['A', 'B'] : ['A', 'B', 'C', 'D'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              child: const Text('HOD Full View', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
            ),
            const Text('Year: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ...[2, 3, 4].map((y) {
              final isSelected = _selectedYear == y;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  label: Text('$y Yr', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textPrimary)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF6366F1),
                  backgroundColor: const Color(0xFFF1F5F9),
                  onSelected: (selected) {
                    if (selected) _onSectionChanged(y, 'A');
                  },
                ),
              );
            }),
            const SizedBox(width: 8),
            const Text('Sec: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
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
    final total = _records.length;
    final pct = total > 0 ? (((_presentCount + _onDutyCount) / total) * 100).toStringAsFixed(1) : '0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _miniStat('Total', '$total', Icons.groups_rounded, Colors.white),
            Container(height: 26, width: 1, color: Colors.white24),
            _miniStat('Present', '$_presentCount', Icons.check_circle_rounded, const Color(0xFF34D399)),
            Container(height: 26, width: 1, color: Colors.white24),
            _miniStat('Absent', '$_absentCount', Icons.cancel_rounded, const Color(0xFFF87171)),
            Container(height: 26, width: 1, color: Colors.white24),
            _miniStat('On-Duty', '$_onDutyCount', Icons.badge_rounded, const Color(0xFF60A5FA)),
            Container(height: 26, width: 1, color: Colors.white24),
            _miniStat('Turnout', '$pct%', Icons.pie_chart_rounded, const Color(0xFFFBBF24)),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
      ],
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final int indexNumber;
  final String name;
  final String rollNumber;
  final String gender;
  final AttendanceStatus status;
  final String source;
  final String? onDutyReason;
  final String? recordedBy;
  final DateTime? punchIn;
  final VoidCallback onSetPresent;
  final VoidCallback onSetAbsent;
  final VoidCallback onSetOnDuty;
  final VoidCallback? onPinkSlip;

  const _AttendanceTile({
    required this.indexNumber,
    required this.name,
    required this.rollNumber,
    required this.gender,
    required this.status,
    required this.source,
    this.onDutyReason,
    this.recordedBy,
    this.punchIn,
    required this.onSetPresent,
    required this.onSetAbsent,
    required this.onSetOnDuty,
    this.onPinkSlip,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = status == AttendanceStatus.present;
    final isAbsent = status == AttendanceStatus.absent;
    final isOnDuty = status == AttendanceStatus.onDuty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPresent
              ? const Color(0xFFD1FAE5)
              : isOnDuty
                  ? const Color(0xFFBFDBFE)
                  : const Color(0xFFFEE2E2),
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
            radius: 17,
            backgroundColor: isPresent
                ? const Color(0xFFD1FAE5)
                : isOnDuty
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFFEE2E2),
            child: Text(
              gender == 'Female' ? '♀' : (name.isNotEmpty ? name[0] : 'S'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isPresent
                    ? const Color(0xFF047857)
                    : isOnDuty
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFDC2626),
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
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(rollNumber, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    if (isOnDuty && onDutyReason != null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '• $onDutyReason',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Pink Slip Button
          if (onPinkSlip != null) ...[
            InkWell(
              onTap: onPinkSlip,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 12, color: Color(0xFFEA580C)),
                    SizedBox(width: 3),
                    Text(
                      'Slip',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 3-Way Selector (P, A, OD)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _optionButton('P', isPresent, const Color(0xFF047857), onSetPresent),
                _optionButton('A', isAbsent, const Color(0xFFDC2626), onSetAbsent),
                _optionButton('OD', isOnDuty, const Color(0xFF2563EB), onSetOnDuty),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionButton(String label, bool isSelected, Color activeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
