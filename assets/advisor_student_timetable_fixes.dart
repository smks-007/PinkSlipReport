// lib/dashboard/  — Advisor + Student + Timetable RESPONSIVE PATCHES
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FIX 10 — Advisor Dashboard AppBar title overflow under high font scaling
// ══════════════════════════════════════════════════════════════════════════════

/// Drop-in replacement for the title widget inside your AppBar.
class AdvisorAppBarTitle extends StatelessWidget {
  final String portalName;
  final String subtitle;

  const AdvisorAppBarTitle({
    super.key,
    required this.portalName,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // BEFORE: Column(children: [Text(portalName), Text(subtitle)])
    //         → has no width bound; at 1.5× text scale it overflows AppBar.
    // AFTER:  Wrap inside Expanded so Flutter can measure and truncate.
    return Expanded(                                           // ← KEY CHANGE
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            portalName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,                  // ← ADDED
            maxLines: 1,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: context.responsiveFontSize(compact: 10, normal: 12),
              color: Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,                  // ← ADDED
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 11 — Advisor _PinkSlipTile bottom button row
// ══════════════════════════════════════════════════════════════════════════════

class PinkSlipTileActions extends StatelessWidget {
  final VoidCallback onView;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const PinkSlipTileActions({
    super.key,
    required this.onView,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    // BEFORE: Row(children: [...]) — overflows on narrow screens.
    // AFTER:  Wrap wraps to second line when needed.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(onPressed: onView, child: const Text('View')),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: onReject,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: onApprove,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approve'),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 12 — Advisor Dashboard today's attendance overview stat cards
// ══════════════════════════════════════════════════════════════════════════════

class AttendanceOverviewRow extends StatelessWidget {
  final List<_AttendanceStat> stats;

  const AttendanceOverviewRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.expand((stat) sync* {
        yield Expanded(child: _AttendanceStatCard(stat: stat)); // ← ADDED Expanded
        if (stat != stats.last) yield const SizedBox(width: 8);
      }).toList(),
    );
  }
}

class _AttendanceStatCard extends StatelessWidget {
  final _AttendanceStat stat;

  const _AttendanceStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              stat.value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              stat.label,
              style: TextStyle(
                fontSize: context.responsiveFontSize(compact: 10, normal: 11.5),
              ),
              maxLines: 1,                                     // ← ADDED
              overflow: TextOverflow.ellipsis,                 // ← ADDED
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceStat {
  final String value;
  final String label;
  const _AttendanceStat(this.value, this.label);
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 13 — Student Dashboard: bottom sheet keyboard handling
// ══════════════════════════════════════════════════════════════════════════════

/// Call this instead of bare showModalBottomSheet to avoid double padding.
Future<T?> showLeaveModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    // BEFORE: isScrollControlled not set (defaults to false) — Flutter
    //         auto-applies keyboard insets AND the sheet also adds them manually.
    // AFTER:  isScrollControlled: true — Flutter hands inset control to the sheet.
    isScrollControlled: true,                                  // ← ADDED
    useSafeArea: true,                                         // ← ADDED
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: builder,
  );
}

/// Template for the leave modal content — single correct keyboard inset padding.
class SubmitLeaveModal extends StatelessWidget {
  const SubmitLeaveModal({super.key});

  @override
  Widget build(BuildContext context) {
    // BEFORE: padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16)
    //         ALSO set on the outer showModalBottomSheet caller — double padding.
    // AFTER:  padding applied exactly once here; caller uses isScrollControlled: true.
    final keyboardHeight = context.bottomInset;               // ← single source

    return Padding(
      padding: EdgeInsets.only(
        left: context.responsiveHorizontalPadding,
        right: context.responsiveHorizontalPadding,
        top: 20,
        bottom: keyboardHeight + 20,                          // ← single inset
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Submit Leave Request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // … rest of your form fields go here …
          const TextField(decoration: InputDecoration(labelText: 'Reason')),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 14 — Student Dashboard metric row (Class Strength, Present, Absentees)
// ══════════════════════════════════════════════════════════════════════════════

class StudentMetricRow extends StatelessWidget {
  const StudentMetricRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      // BEFORE: children: [_MetricItem(...), VerticalDivider(), _MetricItem(...), ...]
      // AFTER:  each MetricItem wrapped in Expanded; divider is bounded.
      children: const [
        Expanded(child: _MetricItem(label: 'Class Strength', value: '60')), // ← Expanded
        _BoundedDivider(),
        Expanded(child: _MetricItem(label: 'Present Today', value: '54')),
        _BoundedDivider(),
        Expanded(child: _MetricItem(label: 'Absentees', value: '6')),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsiveFontSize(compact: 10, normal: 12),
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _BoundedDivider extends StatelessWidget {
  const _BoundedDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: Colors.grey.shade300);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 15 — Timetable: section header card text truncation
// ══════════════════════════════════════════════════════════════════════════════

class TimetableSectionHeaderCard extends StatelessWidget {
  final String section;
  final String room;
  final String batch;

  const TimetableSectionHeaderCard({
    super.key,
    required this.section,
    required this.room,
    required this.batch,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveHorizontalPadding,
          vertical: 12,
        ),
        child: Row(
          children: [
            const Icon(Icons.class_, color: Colors.pink),
            const SizedBox(width: 12),
            // BEFORE: Column(children: [Text(section), Text(room)])
            //         — no width bound, overflows on narrow screens.
            // AFTER:  Expanded wraps it.
            Expanded(                                          // ← KEY CHANGE
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    '$room  ·  $batch',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(compact: 11, normal: 13),
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,          // ← ADDED
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 16 — Timetable Period Card: subject badge overflow
// ══════════════════════════════════════════════════════════════════════════════

class PeriodCard extends StatelessWidget {
  final String periodLabel;
  final String subjectShort;
  final String subjectFull;
  final bool isLab;
  final String timeRange;

  const PeriodCard({
    super.key,
    required this.periodLabel,
    required this.subjectShort,
    required this.subjectFull,
    required this.isLab,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Period number — fixed width
            SizedBox(
              width: 28,
              child: Text(periodLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),

            // Subject — grows, truncates
            // BEFORE: Text(subjectShort)  — pushes badges offscreen
            // AFTER:  Flexible + ellipsis
            Flexible(                                          // ← KEY CHANGE
              child: Text(
                subjectShort,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,              // ← ADDED
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 6),

            // Lab/Theory badge — fixed, always visible
            _TypeBadge(isLab: isLab),
            const SizedBox(width: 6),

            // Time — fixed
            Text(
              timeRange,
              style: TextStyle(
                fontSize: context.responsiveFontSize(compact: 10, normal: 11.5),
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isLab;

  const _TypeBadge({required this.isLab});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isLab ? Colors.orange.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isLab ? 'LAB' : 'TH',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isLab ? Colors.orange.shade800 : Colors.blue.shade800,
        ),
      ),
    );
  }
}
