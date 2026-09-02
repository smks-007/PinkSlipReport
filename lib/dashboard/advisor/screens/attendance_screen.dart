import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../chatbot/widgets/jarvis_fab.dart';

/// Attendance screen for Advisors — view and edit attendance.
/// Advisors can toggle present/absent but CANNOT delete records.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late List<AttendanceRecord> _records;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _records = MockDataService.generateAttendanceForDate(_selectedDate);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
      _records = MockDataService.generateAttendanceForDate(date);
    });
  }

  void _toggleAttendance(int index) {
    setState(() {
      _records[index] = _records[index].copyWith(
        isPresent: !_records[index].isPresent,
        source: 'manual',
        recordedBy: 'adv-001',
        updatedAt: DateTime.now(),
      );
    });
  }

  List<AttendanceRecord> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    return _records.where((r) {
      final student = MockDataService.students.firstWhere(
        (s) => s.id == r.studentId,
        orElse: () => MockDataService.students.first,
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
      floatingActionButton: const JarvisFAB(),
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Attendance',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, size: 22),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) _onDateChanged(picked);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          _buildStatsBar(),
          const SizedBox(height: 12),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: AppStyles.inputDecoration(
                hintText: 'Search student name or roll number...',
                prefixIcon: Icons.search_rounded,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Mark All Present button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _records = _records
                            .map((r) => r.copyWith(
                                  isPresent: true,
                                  source: 'manual',
                                  recordedBy: 'adv-001',
                                  updatedAt: DateTime.now(),
                                ))
                            .toList();
                      });
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark All Present'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusApproved,
                      side: const BorderSide(color: AppColors.statusApproved),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Student list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _filteredRecords.length,
              itemBuilder: (context, index) {
                final record = _filteredRecords[index];
                final student = MockDataService.students.firstWhere(
                  (s) => s.id == record.studentId,
                  orElse: () => MockDataService.students.first,
                );
                return _AttendanceTile(
                  name: student.name,
                  rollNumber: student.rollNumber,
                  isPresent: record.isPresent,
                  source: record.source,
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

  Widget _buildStatsBar() {
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
            _miniStat('Total', '${_records.length}', Icons.people_rounded),
            Container(height: 30, width: 1, color: Colors.white30),
            _miniStat('Present', '$_presentCount', Icons.check_circle_rounded),
            Container(height: 30, width: 1, color: Colors.white30),
            _miniStat('Absent', '$_absentCount', Icons.cancel_rounded),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(height: 4),
        Text(value,
            style: AppStyles.headingSmall
                .copyWith(color: Colors.white, fontSize: 18)),
        Text(label,
            style: AppStyles.bodySmall
                .copyWith(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final String name;
  final String rollNumber;
  final bool isPresent;
  final String source;
  final DateTime? punchIn;
  final VoidCallback onToggle;

  const _AttendanceTile({
    required this.name,
    required this.rollNumber,
    required this.isPresent,
    required this.source,
    this.punchIn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: isPresent
                ? AppColors.statusApprovedBg
                : AppColors.statusRejectedBg,
            child: Text(
              name[0],
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color:
                    isPresent ? AppColors.statusApproved : AppColors.statusRejected,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppStyles.bodyLarge
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(rollNumber, style: AppStyles.bodySmall),
                    if (source == 'biometric') ...[
                      const SizedBox(width: 6),
                      Icon(Icons.fingerprint, size: 14, color: AppColors.primaryPurple),
                      const SizedBox(width: 2),
                      Text('Biometric',
                          style: AppStyles.bodySmall
                              .copyWith(color: AppColors.primaryPurple, fontSize: 10)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Toggle
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isPresent
                    ? AppColors.statusApproved
                    : AppColors.statusRejected,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPresent ? 'Present' : 'Absent',
                style: AppStyles.chipText.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
