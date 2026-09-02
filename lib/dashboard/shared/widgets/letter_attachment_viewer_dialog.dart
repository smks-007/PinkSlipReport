import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/leave_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';

class LetterAttachmentViewerDialog extends StatelessWidget {
  final LeaveModel leave;
  final VoidCallback? onForwardToHod;
  final ValueChanged<String>? onApproveByHod;
  final ValueChanged<String>? onRejectByHod;

  const LetterAttachmentViewerDialog({
    super.key,
    required this.leave,
    this.onForwardToHod,
    this.onApproveByHod,
    this.onRejectByHod,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isHod = user?.role == UserRole.hod;
    final isAdvisor = user?.role == UserRole.advisor;
    final isCR = user?.role == UserRole.student;

    final dateStr =
        '${leave.leaveDate.day.toString().padLeft(2, '0')}/${leave.leaveDate.month.toString().padLeft(2, '0')}/${leave.leaveDate.year}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // College Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded, color: Color(0xFF38BDF8), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'V.S.B. ENGINEERING COLLEGE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DEPARTMENT OF ARTIFICIAL INTELLIGENCE & DATA SCIENCE',
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Letter Title & Category Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: leave.isOnDuty
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFFDF2F8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: leave.isOnDuty
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFFF472B6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                leave.isOnDuty ? Icons.badge_outlined : Icons.event_busy,
                                size: 14,
                                color: leave.isOnDuty
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFDB2777),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                leave.categoryDisplay.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: leave.isOnDuty
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFDB2777),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildStatusBadge(leave.letterStatus),
                        const Spacer(),
                        Text(
                          'Date: $dateStr',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Student Information Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.12),
                                child: Text(
                                  leave.studentName.isNotEmpty ? leave.studentName[0] : 'S',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      leave.studentName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Roll No: ${leave.studentRollNumber} • Class: ${leave.year != null ? "Year ${leave.year} - Sec ${leave.section}" : "Sec B"}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _buildDetailRow('Reason / Purpose', leave.reason),
                          const SizedBox(height: 8),
                          _buildDetailRow('Leave Type', leave.leaveTypeDisplay),
                          const SizedBox(height: 8),
                          _buildDetailRow('Total Leaves This Sem', '${leave.totalLeavesTaken} days'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Attached Document / File Section
                    const Text(
                      'Attached Document Proof',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (leave.hasAttachment)
                      _buildAttachmentCard(context)
                    else
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No official document proof attached yet. Student/CR should attach proof.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 22),

                    // Multi-Tier Workflow Review Timeline
                    const Text(
                      'Multi-Tier Approval Verification Flow',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildWorkflowTimeline(),
                  ],
                ),
              ),
            ),

            // Bottom Actions depending on Role
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Text(
                    isCR
                        ? 'Viewed as Class Representative'
                        : isAdvisor
                            ? 'Logged in as Class Advisor'
                            : 'Logged in as Head of Department',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const Spacer(),
                  if (isAdvisor && leave.letterStatus == LetterStatus.submitted)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onForwardToHod?.call();
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Forward to HOD'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  if (isHod &&
                      (leave.letterStatus == LetterStatus.forwarded ||
                          leave.letterStatus == LetterStatus.submitted)) ...[
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onRejectByHod?.call('Rejected: Document validation incomplete.');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onApproveByHod?.call('Approved by HOD. Document and signatures verified.');
                      },
                      icon: const Icon(Icons.verified_rounded, size: 16),
                      label: const Text('Check & Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  if ((!isAdvisor || leave.letterStatus != LetterStatus.submitted) &&
                      (!isHod ||
                          (leave.letterStatus != LetterStatus.forwarded &&
                              leave.letterStatus != LetterStatus.submitted)))
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leave.attachmentFileName ?? 'document.pdf',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${leave.attachmentFileType ?? "Official Document"} • ${leave.attachmentFileSize ?? "1.2 MB"}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _previewDocument(context),
            icon: const Icon(Icons.visibility_rounded, size: 14),
            label: const Text('Inspect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _previewDocument(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Official Document Preview',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'V.S.B. ENGINEERING COLLEGE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'Department of AI & Data Science',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('DOCUMENT: ${leave.attachmentFileName}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Applicant: ${leave.studentName} (${leave.studentRollNumber})',
                        style: const TextStyle(fontSize: 11.5)),
                    Text('Type: ${leave.categoryDisplay} • Purpose: ${leave.reason}',
                        style: const TextStyle(fontSize: 11.5)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'This document certifies that the aforementioned student has provided genuine documentation supporting their leave / On-Duty application. Verification details verified against department records.',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Advisor Verification',
                                style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text(leave.advisorRemarks != null ? '✅ Verified' : '⏳ Pending',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('HOD Digital Stamp',
                                style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text(
                              leave.letterStatus == LetterStatus.approved
                                  ? '🛡️ APPROVED (SEALED)'
                                  : '⏳ Awaiting Approval',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: leave.letterStatus == LetterStatus.approved
                                    ? Colors.green.shade700
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close Preview'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowTimeline() {
    return Column(
      children: [
        _buildTimelineStep(
          stepNumber: '1',
          title: 'Letter / OD Request Submitted',
          subtitle: leave.letterSubmitted
              ? 'Submitted with attached proof document by Class Representative / Student'
              : 'Pending letter submission',
          isDone: leave.letterSubmitted,
          isCurrent: leave.letterStatus == LetterStatus.submitted,
        ),
        _buildTimelineStep(
          stepNumber: '2',
          title: 'Class Advisor Review & Endorsement',
          subtitle: leave.advisorRemarks ??
              (leave.letterStatus == LetterStatus.submitted
                  ? 'Awaiting Class Advisor endorsement & signature'
                  : 'Pending submission'),
          isDone: leave.letterStatus == LetterStatus.forwarded ||
              leave.letterStatus == LetterStatus.approved ||
              leave.letterStatus == LetterStatus.rejected,
          isCurrent: leave.letterStatus == LetterStatus.forwarded,
        ),
        _buildTimelineStep(
          stepNumber: '3',
          title: 'Head of Department (HOD) Check & Final Approval',
          subtitle: leave.hodRemarks ??
              (leave.letterStatus == LetterStatus.forwarded
                  ? 'Document in HOD queue for final signature & approval'
                  : 'Pending advisor forward'),
          isDone: leave.letterStatus == LetterStatus.approved ||
              leave.letterStatus == LetterStatus.rejected,
          isCurrent: leave.letterStatus == LetterStatus.forwarded,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFF059669)
                    : isCurrent
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : Text(
                        stepNumber,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isDone ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDone || isCurrent ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(LetterStatus status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case LetterStatus.notSubmitted:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        text = 'NOT SUBMITTED';
        break;
      case LetterStatus.submitted:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        text = 'SUBMITTED TO ADVISOR';
        break;
      case LetterStatus.forwarded:
        bg = const Color(0xFFEDE9FE);
        fg = AppColors.primaryPurple;
        text = 'FORWARDED TO HOD';
        break;
      case LetterStatus.approved:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        text = 'APPROVED BY HOD';
        break;
      case LetterStatus.rejected:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        text = 'REJECTED BY HOD';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
