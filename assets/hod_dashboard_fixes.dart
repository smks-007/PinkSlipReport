// lib/dashboard/hod/screens/hod_dashboard_screen.dart — RESPONSIVE PATCHES
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FIX 6 — Executive Summary Banner (4 stats)
//
// CRASH: VerticalDivider in flat Row has no bounded height → RenderFlex crash.
// OVERFLOW: 4-item Row clips on screens < 360 px.
//
// SOLUTION: LayoutBuilder switches between:
//   • 4-column Row with bounded Container dividers  (width >= 360)
//   • 2×2 grid using Row/Column flex layout         (width < 360)
// ══════════════════════════════════════════════════════════════════════════════

class ExecutiveSummaryBanner extends StatelessWidget {
  final List<_StatItem> stats;

  const ExecutiveSummaryBanner({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    assert(stats.length == 4, 'Banner expects exactly 4 stats');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade700, Colors.pink.shade900],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(
        vertical: 16,
        horizontal: context.responsiveHorizontalPadding,
      ),
      // LayoutBuilder reads actual available width, not screen width.
      child: LayoutBuilder(
        builder: (context, constraints) {
          // BEFORE: GridView.count(crossAxisCount: 4) — causes height bloat
          //         and VerticalDivider crash.
          if (constraints.maxWidth < 360) {
            // ── 2 × 2 grid for ultra-compact screens ──────────────────────
            return Column(
              mainAxisSize: MainAxisSize.min,                  // exact intended height
              children: [
                _StatRow(left: stats[0], right: stats[1]),
                const SizedBox(height: 12),
                _StatRow(left: stats[2], right: stats[3]),
              ],
            );
          } else {
            // ── 4-column row for standard screens ─────────────────────────
            return Row(
              children: [
                Expanded(child: _StatCell(stat: stats[0])),
                _BoundedDivider(),                             // ← FIX for crash
                Expanded(child: _StatCell(stat: stats[1])),
                _BoundedDivider(),
                Expanded(child: _StatCell(stat: stats[2])),
                _BoundedDivider(),
                Expanded(child: _StatCell(stat: stats[3])),
              ],
            );
          }
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final _StatItem left;
  final _StatItem right;

  const _StatRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCell(stat: left)),
        _BoundedDivider(),
        Expanded(child: _StatCell(stat: right)),
      ],
    );
  }
}

/// FIX: bounded divider — replaces VerticalDivider which has no intrinsic height.
class _BoundedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // BEFORE: VerticalDivider(color: Colors.white30) — CRASHES (unbounded height)
    // AFTER:  Container with explicit height — always safe
    return Container(
      width: 1,
      height: 32,                                              // ← bounded height
      color: Colors.white30,
    );
  }
}

class _StatCell extends StatelessWidget {
  final _StatItem stat;

  const _StatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stat.value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stat.label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: context.responsiveFontSize(compact: 10.0, normal: 11.5),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatItem {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 7 — Segmented Navigation Bar (4 tabs)
//
// PROBLEM: Tab label text clips on compact screens.
// SOLUTION: Flexible + ellipsis + responsive horizontal padding.
// ══════════════════════════════════════════════════════════════════════════════

class HodSegmentedNav extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const HodSegmentedNav({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected ? Colors.pink : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                // BEFORE: padding: EdgeInsets.symmetric(horizontal: 10)
                // AFTER:  shrinks on compact screens
                padding: EdgeInsets.symmetric(
                  horizontal: context.tabHorizontalPadding,   // ← CHANGED
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // BEFORE: Text(labels[i])  — overflows on compact
                    // AFTER:  Flexible + ellipsis
                    Flexible(                                  // ← ADDED
                      child: Text(
                        labels[i],
                        overflow: TextOverflow.ellipsis,      // ← ADDED
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey.shade700,
                          fontSize: context.responsiveFontSize(
                            compact: 10.5,
                            normal: 12.0,
                          ),
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 8 — Pink Slip Approval Card Action Buttons
//
// PROBLEM: Row + Spacer() overflows on 320 px screens with 3 buttons.
// SOLUTION: Wrap with WrapAlignment.spaceBetween + runSpacing.
// ══════════════════════════════════════════════════════════════════════════════

class PinkSlipCardActions extends StatelessWidget {
  final VoidCallback onViewVoucher;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const PinkSlipCardActions({
    super.key,
    required this.onViewVoucher,
    required this.onReject,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    // BEFORE: Row(children: [TextButton('View Voucher'), Spacer(), OutlinedButton('Reject'), ElevatedButton('Approve')])
    // AFTER:  Wrap — buttons move to next line if they don't fit
    return Wrap(
      alignment: WrapAlignment.spaceBetween,                   // ← KEY CHANGE
      spacing: 8,
      runSpacing: 8,
      children: [
        TextButton.icon(
          onPressed: onViewVoucher,
          icon: const Icon(Icons.receipt_long, size: 16),
          label: const Text('View Voucher'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Approve'),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 9 — Pink Slip Card Header Badges
//
// PROBLEM: 'ON-DUTY OD PASS' + status + date badges in a flat Row overflow.
// SOLUTION: Wrap with spacing/runSpacing.
// ══════════════════════════════════════════════════════════════════════════════

class PinkSlipCardHeaderBadges extends StatelessWidget {
  final String passType;
  final String status;
  final String date;

  const PinkSlipCardHeaderBadges({
    super.key,
    required this.passType,
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    // BEFORE: Row(children: [Chip(passType), Chip(status), Spacer(), Text(date)])
    // AFTER:  Wrap — overflowing badges drop to next line
    return Wrap(                                               // ← KEY CHANGE
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Badge(label: passType, color: Colors.pink.shade100),
        _Badge(label: status, color: Colors.blue.shade100),
        Text(
          date,
          style: TextStyle(
            fontSize: context.responsiveFontSize(compact: 10.5, normal: 12.0),
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.responsiveFontSize(compact: 9.5, normal: 11.0),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
