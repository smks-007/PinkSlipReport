import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/models/leave_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/mock_data_service.dart';
import '../../shared/widgets/letter_attachment_viewer_dialog.dart';

/// Leave Management screen for Advisors & HODs.
/// Advisors can only view and manage leaves for their own assigned class.
/// HODs can view and approve leaves across all classes.
class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  String _filter = 'All';
  late List<LeaveModel> _leaves;

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  void _loadLeaves() {
    final user = AuthService().currentUser;
    final all = MockDataService.leaveRequests;
    if (user != null && user.role == UserRole.advisor && user.year != null && user.section != null) {
      _leaves = all.where((l) => l.year == user.year && l.section == user.section).toList();
    } else {
      _leaves = List.from(all);
    }
  }

  List<LeaveModel> get _filteredLeaves {
    if (_filter == 'All') return _leaves;
    return _leaves.where((l) {
      switch (_filter) {
        case 'Pending':
          return l.letterStatus == LetterStatus.submitted ||
              l.letterStatus == LetterStatus.notSubmitted;
        case 'Forwarded':
          return l.letterStatus == LetterStatus.forwarded;
        case 'Approved':
          return l.letterStatus == LetterStatus.approved;
        case 'Rejected':
          return l.letterStatus == LetterStatus.rejected;
        default:
          return true;
      }
    }).toList();
  }

  void _forwardToHod(int index) {
    final leave = _leaves[index];
    MockDataService.forwardToHod(leave.id);
    setState(() {
      _leaves[index] = leave.copyWith(
        letterStatus: LetterStatus.forwarded,
        dateReceivedByHod: DateTime.now(),
        advisorRemarks: 'Forwarded by advisor for HOD review.',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leave forwarded to HOD for approval')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isAdvisor = user?.role == UserRole.advisor;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leave Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              isAdvisor
                  ? '${user?.year ?? 2} Year AI&DS - Section ${user?.section ?? "B"} (Your Class)'
                  : 'Overall Department (All Sections)',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          const SizedBox(height: 12),

          // Leave list
          Expanded(
            child: _filteredLeaves.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No leave requests found',
                            style: AppStyles.bodyMedium),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredLeaves.length,
                    itemBuilder: (context, index) {
                      final leave = _filteredLeaves[index];
                      return _LeaveCard(
                        leave: leave,
                        onForward: leave.letterStatus == LetterStatus.submitted
                            ? () {
                                final originalIndex =
                                    _leaves.indexWhere((l) => l.id == leave.id);
                                if (originalIndex != -1) {
                                  _forwardToHod(originalIndex);
                                }
                              }
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Pending', 'Forwarded', 'Approved', 'Rejected'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (_) => setState(() => _filter = f),
              selectedColor: AppColors.primaryPurple,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryPurple
                      : AppColors.inputBorder,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveModel leave;
  final VoidCallback? onForward;

  const _LeaveCard({required this.leave, this.onForward});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Status
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _statusBgColor,
                child: Icon(_statusIcon, size: 20, color: _statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leave.studentName,
                        style: AppStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('${leave.studentRollNumber} • ${leave.reason}',
                        style: AppStyles.bodySmall),
                  ],
                ),
              ),
              _statusBadge(),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Details Grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _detailChip(
                  leave.isOnDuty ? Icons.badge_outlined : Icons.event_busy,
                  leave.categoryDisplay,
                  leave.isOnDuty ? const Color(0xFF2563EB) : const Color(0xFFDB2777)),
              _detailChip(Icons.category_rounded,
                  'Type: ${leave.leaveTypeDisplay}',
                  leave.leaveType == LeaveType.informed
                      ? AppColors.statusApproved
                      : AppColors.statusPending),
              _detailChip(
                  Icons.mail_outline,
                  'Letter: ${leave.letterSubmitted ? "Yes" : "No"}',
                  leave.letterSubmitted
                      ? AppColors.statusApproved
                      : AppColors.statusRejected),
              _detailChip(Icons.hourglass_bottom,
                  'Due: ${leave.dueDays} days', AppColors.statusPending),
              _detailChip(Icons.event_repeat,
                  'Total Leaves: ${leave.totalLeavesTaken}',
                  AppColors.attendanceBlue),
            ],
          ),
          const SizedBox(height: 10),

          // File Attachment Box (if present)
          if (leave.hasAttachment) ...[
            Container(
              margin: const EdgeInsets.only(top: 6, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${leave.attachmentFileName} (${leave.attachmentFileSize ?? "Proof"})',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => LetterAttachmentViewerDialog(
                          leave: leave,
                          onForwardToHod: onForward,
                        ),
                      );
                    },
                    child: const Text(
                      'Inspect Proof',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Date info
          if (leave.dateSubmittedToAdvisor != null)
            _dateRow('Submitted to Advisor',
                _formatDate(leave.dateSubmittedToAdvisor!)),
          if (leave.dateReceivedByHod != null)
            _dateRow('Received by HOD',
                _formatDate(leave.dateReceivedByHod!)),
          if (leave.dateApprovedRejected != null)
            _dateRow(
                leave.letterStatus == LetterStatus.approved
                    ? 'Approved on'
                    : 'Rejected on',
                _formatDate(leave.dateApprovedRejected!)),

          // Remarks
          if (leave.advisorRemarks != null) ...[
            const SizedBox(height: 8),
            _remarkBox('Advisor Remarks', leave.advisorRemarks!),
          ],
          if (leave.hodRemarks != null) ...[
            const SizedBox(height: 8),
            _remarkBox('HOD Remarks', leave.hodRemarks!),
          ],

          // Action Buttons: View Full Letter + Forward
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => LetterAttachmentViewerDialog(
                        leave: leave,
                        onForwardToHod: onForward,
                      ),
                    );
                  },
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('View Full Letter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPurple,
                    side: const BorderSide(color: Color(0xFFDDD6FE)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (onForward != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onForward,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Forward to HOD'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusBgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        leave.letterStatusDisplay,
        style: AppStyles.chipText.copyWith(color: _statusColor),
      ),
    );
  }

  Widget _detailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: AppStyles.bodySmall
                  .copyWith(color: color, fontWeight: FontWeight.w500, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _dateRow(String label, String date) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text('$label: ', style: AppStyles.bodySmall.copyWith(fontSize: 11)),
          Text(date,
              style: AppStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _remarkBox(String title, String remark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.purpleSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurple,
                  fontSize: 11)),
          const SizedBox(height: 2),
          Text(remark, style: AppStyles.bodySmall.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color get _statusColor {
    switch (leave.letterStatus) {
      case LetterStatus.approved:
        return AppColors.statusApproved;
      case LetterStatus.rejected:
        return AppColors.statusRejected;
      case LetterStatus.forwarded:
        return AppColors.statusForwarded;
      default:
        return AppColors.statusPending;
    }
  }

  Color get _statusBgColor {
    switch (leave.letterStatus) {
      case LetterStatus.approved:
        return AppColors.statusApprovedBg;
      case LetterStatus.rejected:
        return AppColors.statusRejectedBg;
      case LetterStatus.forwarded:
        return AppColors.statusForwardedBg;
      default:
        return AppColors.statusPendingBg;
    }
  }

  IconData get _statusIcon {
    switch (leave.letterStatus) {
      case LetterStatus.approved:
        return Icons.check_circle_rounded;
      case LetterStatus.rejected:
        return Icons.cancel_rounded;
      case LetterStatus.forwarded:
        return Icons.send_rounded;
      default:
        return Icons.pending_rounded;
    }
  }
}
