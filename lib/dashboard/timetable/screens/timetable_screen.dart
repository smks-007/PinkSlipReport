import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/models/timetable_model.dart';
import '../../../core/services/timetable_data_service.dart';
import '../../../chatbot/widgets/jarvis_fab.dart';

/// Interactive Timetable Screen for 2nd Year B.Tech AI&DS (Sections A, B, C, D).
class TimetableScreen extends StatefulWidget {
  final String initialSection;

  const TimetableScreen({
    super.key,
    this.initialSection = 'A',
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late String _selectedSection;
  late String _selectedDay;
  late SectionTimetable _currentTimetable;

  final List<String> _sections = TimetableDataService.availableSections;
  final List<String> _days = TimetableDataService.days;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection;
    _currentTimetable = TimetableDataService.getSectionTimetable(_selectedSection);

    // Auto-select current day of the week, defaulting to Monday on Sunday
    final weekday = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    if (weekday >= 1 && weekday <= 6) {
      _selectedDay = _days[weekday - 1];
    } else {
      _selectedDay = _days[0];
    }
  }

  void _onSectionChanged(String section) {
    setState(() {
      _selectedSection = section;
      _currentTimetable = TimetableDataService.getSectionTimetable(section);
    });
  }

  void _onDayChanged(String day) {
    setState(() {
      _selectedDay = day;
    });
  }

  void _showFacultySubjectDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FacultySubjectSheet(timetable: _currentTimetable),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayPeriods = _currentTimetable.schedule[_selectedDay] ?? [];

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      floatingActionButton: const JarvisFAB(),
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Class Timetable',
          style: AppStyles.headingMedium.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: AppColors.primaryPurple),
            tooltip: 'View Subject & Faculty Details',
            onPressed: _showFacultySubjectDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Section Selector Chips (A, B, C, D)
            _buildSectionSelector(),

            // Section Info Header
            _buildSectionHeaderCard(),

            // Day Selector Chips (Mon - Sat)
            _buildDaySelector(),

            const SizedBox(height: 8),

            // Periods List
            Expanded(
              child: dayPeriods.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: dayPeriods.length,
                      itemBuilder: (context, index) {
                        final period = dayPeriods[index];
                        return _PeriodCard(
                          entry: period,
                          isFirst: index == 0,
                          isLast: index == dayPeriods.length - 1,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: _sections.map((sec) {
          final isSelected = _selectedSection == sec;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => _onSectionChanged(sec),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryPurple
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryPurple
                          : AppColors.inputBorder,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryPurple.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Sec $sec',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'II AI&DS',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeaderCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.purpleSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Room ${_currentTimetable.classRoom}',
                        style: const TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentTimetable.year} - Sec ${_currentTimetable.section}',
                      style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _showFacultySubjectDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryPurple),
                  label: const Text('Faculty', style: TextStyle(fontSize: 12, color: AppColors.primaryPurple)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_pin_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Class Advisor: ${_currentTimetable.classAdvisor}',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _currentTimetable.counselingDetails,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
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

  Widget _buildDaySelector() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = _selectedDay == day;
          return ChoiceChip(
            label: Text(day),
            selected: isSelected,
            onSelected: (_) => _onDayChanged(day),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
            selectedColor: AppColors.primaryPurple,
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? AppColors.primaryPurple : AppColors.inputBorder,
              ),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No classes scheduled for this day.'),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Period Card Tile
// ══════════════════════════════════════════════════════════════════
class _PeriodCard extends StatelessWidget {
  final TimetableEntry entry;
  final bool isFirst;
  final bool isLast;

  const _PeriodCard({
    required this.entry,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isLab
              ? AppColors.primaryPurple.withValues(alpha: 0.3)
              : AppColors.inputBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Period Number Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: entry.isLab
                    ? AppColors.purpleSurface
                    : AppColors.pageBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: entry.isLab
                      ? AppColors.primaryPurple.withValues(alpha: 0.4)
                      : AppColors.inputBorder,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'P${entry.periodNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: entry.isLab
                            ? AppColors.primaryPurple
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Subject & Faculty Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.subjectShort,
                        style: AppStyles.headingSmall.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (entry.isLab)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.statusApprovedBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LAB',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusApproved,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purpleSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'THEORY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.subjectName,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.facultyName} [${entry.facultyShort}]',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Time Slot Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.timeSlot,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Faculty & Subject Info Sheet Modal
// ══════════════════════════════════════════════════════════════════
class _FacultySubjectSheet extends StatelessWidget {
  final SectionTimetable timetable;

  const _FacultySubjectSheet({required this.timetable});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Section ${timetable.section} Subjects & Faculty',
                style: AppStyles.headingMedium.copyWith(fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            '${timetable.department} • Room ${timetable.classRoom}',
            style: AppStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: timetable.subjects.length,
              separatorBuilder: (_, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final sub = timetable.subjects[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: sub.isLab
                          ? AppColors.statusApprovedBg
                          : AppColors.purpleSurface,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sub.isLab
                              ? AppColors.statusApproved
                              : AppColors.primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${sub.code} - ${sub.name} [${sub.shortName}]',
                            style: AppStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Faculty: ${sub.facultyName} [${sub.facultyShort}]',
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.pageBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${sub.periodsPerWeek} hrs/wk',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
