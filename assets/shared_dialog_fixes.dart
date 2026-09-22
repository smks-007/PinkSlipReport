// lib/dashboard/shared/widgets/  — Dialog + AI Agent Sheet PATCHES
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FIX 17 — AttendanceReportViewerDialog
//
// PROBLEM 1: 4-column flat metric banner clips on < 380 px screens.
// PROBLEM 2: Dialog clips vertically on 568 px height devices.
// ══════════════════════════════════════════════════════════════════════════════

class AttendanceReportViewerDialog extends StatelessWidget {
  final List<_ReportStat> stats;
  final Widget reportBody;

  const AttendanceReportViewerDialog({
    super.key,
    required this.stats,
    required this.reportBody,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // BEFORE: Dialog with no constraints — overflows vertically on 568 px.
      // AFTER:  dialogConstraints caps at 88 % screen height, 95 % screen width.
      constraints: context.dialogConstraints(maxWidth: 680),  // ← KEY CHANGE
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          _ReportMetricBanner(stats: stats),                   // adaptive 4→2×2
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.responsiveHorizontalPadding),
              child: reportBody,
            ),
          ),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsiveHorizontalPadding),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Attendance Report',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.responsiveHorizontalPadding),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }
}

/// Adaptive 4-stat banner: 4-column on >= 380 px, 2×2 on smaller screens.
class _ReportMetricBanner extends StatelessWidget {
  final List<_ReportStat> stats;

  const _ReportMetricBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.pink.shade50,
      padding: EdgeInsets.symmetric(
        vertical: 12,
        horizontal: context.responsiveHorizontalPadding,
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          if (constraints.maxWidth < 380) {
            // 2 × 2 grid
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatRowPair(left: stats[0], right: stats[1]),
                const SizedBox(height: 8),
                _StatRowPair(left: stats[2], right: stats[3]),
              ],
            );
          }
          // 4-column row
          return Row(
            children: stats.map((s) => Expanded(child: _StatCell(stat: s))).toList(),
          );
        },
      ),
    );
  }
}

class _StatRowPair extends StatelessWidget {
  final _ReportStat left;
  final _ReportStat right;

  const _StatRowPair({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCell(stat: left)),
        Container(width: 1, height: 28, color: Colors.pink.shade200),
        Expanded(child: _StatCell(stat: right)),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final _ReportStat stat;

  const _StatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(stat.value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(
          stat.label,
          style: TextStyle(
            fontSize: context.responsiveFontSize(compact: 10, normal: 11.5),
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ReportStat {
  final String value;
  final String label;
  const _ReportStat(this.value, this.label);
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 18 — CreatePinkSlipDialog + viewer dialogs
//
// PROBLEM: Fixed dialog dimensions overflow on short screens.
// SOLUTION: Apply dialogConstraints to every Dialog.
// ══════════════════════════════════════════════════════════════════════════════

class CreatePinkSlipDialog extends StatefulWidget {
  const CreatePinkSlipDialog({super.key});

  @override
  State<CreatePinkSlipDialog> createState() => _CreatePinkSlipDialogState();
}

class _CreatePinkSlipDialogState extends State<CreatePinkSlipDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      constraints: context.dialogConstraints(maxWidth: 580),  // ← KEY CHANGE
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(                           // ← ensures scrollable
        child: Padding(
          padding: EdgeInsets.all(context.responsiveHorizontalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DialogHeader(title: 'Create Pink Slip'),
              const SizedBox(height: 16),
              // … your form fields here …
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(                                               // ← Wrap not Row
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 19 — AI Agent / Jarvis Sheet
//
// PROBLEM: Sheet header title + badges overflow; keyboard insets not applied.
// SOLUTION: Flexible text, single keyboard inset.
// ══════════════════════════════════════════════════════════════════════════════

class RoleAiAgentSheet extends StatelessWidget {
  final String agentTitle;
  final String agentBadge;
  final Widget chatContent;

  const RoleAiAgentSheet({
    super.key,
    required this.agentTitle,
    required this.agentBadge,
    required this.chatContent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // BEFORE: padding that duplicated keyboard insets.
      // AFTER:  single keyboard inset via bottomInset extension.
      padding: EdgeInsets.only(bottom: context.bottomInset),  // ← KEY CHANGE
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) {
          return Column(
            children: [
              _AgentSheetHeader(title: agentTitle, badge: agentBadge),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  child: chatContent,
                ),
              ),
              _AgentInputBar(),
            ],
          );
        },
      ),
    );
  }
}

class _AgentSheetHeader extends StatelessWidget {
  final String title;
  final String badge;

  const _AgentSheetHeader({required this.title, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveHorizontalPadding,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFF880E4F)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          // BEFORE: Column(children: [Text(title), Text(badge)])  — overflows
          // AFTER:  Flexible wraps both text nodes
          Flexible(                                            // ← KEY CHANGE
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,            // ← ADDED
                  maxLines: 1,
                ),
                Text(
                  badge,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,            // ← ADDED
                  maxLines: 1,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _AgentInputBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveHorizontalPadding,
          vertical: 8,
        ),
        child: Row(
          children: [
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Ask Jarvis…',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.pink),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shared reusable dialog header
// ──────────────────────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final String title;

  const _DialogHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
