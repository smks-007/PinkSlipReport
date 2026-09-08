import 'package:flutter/material.dart';
import '../../../../core/models/promotion_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/mock_data_service.dart';
import '../../../../core/data/student_directory_data.dart';

/// Full interactive Academic Progression & Batch Promotion Dossier Viewer.
/// Allows Advisors and HOD to inspect attached credit sheets, exam records, student rosters,
/// verify compliance, print/export official documents, and approve promotions.
class PromotionDossierViewerDialog extends StatefulWidget {
  final PromotionRequest promotion;
  final VoidCallback? onAdvisorForward;
  final ValueChanged<String>? onHodApprove;
  final ValueChanged<String>? onHodReject;

  const PromotionDossierViewerDialog({
    super.key,
    required this.promotion,
    this.onAdvisorForward,
    this.onHodApprove,
    this.onHodReject,
  });

  static void show(
    BuildContext context, {
    required PromotionRequest promotion,
    VoidCallback? onAdvisorForward,
    ValueChanged<String>? onHodApprove,
    ValueChanged<String>? onHodReject,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => PromotionDossierViewerDialog(
        promotion: promotion,
        onAdvisorForward: onAdvisorForward,
        onHodApprove: onHodApprove,
        onHodReject: onHodReject,
      ),
    );
  }

  @override
  State<PromotionDossierViewerDialog> createState() => _PromotionDossierViewerDialogState();
}

class _PromotionDossierViewerDialogState extends State<PromotionDossierViewerDialog> {
  int _selectedTab = 0; // 0: Dossier & Attached Docs, 1: Student Roster & Credits, 2: Official Seals
  String? _selectedDocumentName;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isHod = user?.role == UserRole.hod;
    final isAdvisor = user?.role == UserRole.advisor;
    final p = widget.promotion;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 750),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // College & Academic Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0369A1)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded, color: Color(0xFF38BDF8), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'V.S.B. ENGINEERING COLLEGE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ACADEMIC PROGRESSION & BATCH PROMOTION DOSSIER • SEM ${p.semesterCompleted}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab Navigation Bar
            Container(
              color: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildTabButton(0, '📋 Dossier & Proofs', Icons.folder_open_rounded),
                  const SizedBox(width: 8),
                  _buildTabButton(1, '👥 Student Roster (${p.totalStudents})', Icons.people_alt_outlined),
                  const SizedBox(width: 8),
                  _buildTabButton(2, '📜 Official Seals', Icons.verified_rounded),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                physics: const BouncingScrollPhysics(),
                child: _selectedTab == 0
                    ? _buildDossierAndProofsTab(p)
                    : _selectedTab == 1
                        ? _buildStudentRosterTab(p)
                        : _buildOfficialSealsTab(p),
              ),
            ),

            // Footer Action Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📥 Exporting Official PDF Dossier (Anna University Format)...'),
                          backgroundColor: Color(0xFF0369A1),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 15),
                    label: const Text('Export PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🖨️ Sending Batch Promotion Sheet to Department Network Printer...'),
                          backgroundColor: Color(0xFF059669),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFFA7F3D0)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.print_rounded, size: 15),
                    label: const Text('Print Sheet', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),

                  // Advisor Forward Action
                  if (isAdvisor && p.status == PromotionApprovalStatus.pendingAdvisorReview)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (widget.onAdvisorForward != null) {
                          widget.onAdvisorForward!();
                        } else {
                          MockDataService.advisorForwardPromotion(
                            p.id,
                            advisorName: user?.name ?? 'Class Advisor',
                            remarks: 'Batch verified for academic credits and attendance compliance.',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: const Text('Endorse & Forward', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),

                  // HOD Approval Action
                  if (isHod && p.status != PromotionApprovalStatus.approvedByHod) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (widget.onHodApprove != null) {
                          widget.onHodApprove!('Approved by HOD. Batch officially promoted to next academic tier.');
                        } else {
                          MockDataService.hodApprovePromotion(
                            p.id,
                            hodName: user?.name ?? 'Dr. Manivannan',
                            remarks: 'Approved by HOD. Batch officially promoted to next academic tier.',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.verified_rounded, size: 15),
                      label: Text(
                        p.isGraduation ? 'Approve Graduation' : 'Approve & Promote Batch',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDossierAndProofsTab(PromotionRequest p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progression Target Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'BATCH: ${p.batchYear}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.status == PromotionApprovalStatus.approvedByHod
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.statusBadgeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: p.status == PromotionApprovalStatus.approvedByHod
                            ? const Color(0xFF047857)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p.promotionTitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                'Completed: Semester ${p.semesterCompleted} • Total Enrolled: ${p.totalStudents} Students • Evaluation Window: ${p.graceTransitionDays} Days Grace Elapsed',
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Attached Official Documents & Proofs Section
        const Text(
          '📎 Attached Academic Progression Documents & Proofs',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Click any document below to inspect the verified university transcripts, credit matrices, and examiner clearances:',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),

        _buildAttachedDocumentTile(
          title: 'Anna University Semester Credit & Grade Matrix',
          fileName: 'anna_university_semester_${p.semesterCompleted}_credit_matrix.pdf',
          fileSize: '2.4 MB',
          docType: 'Credit Clearance Sheet',
          icon: Icons.table_chart_rounded,
          iconColor: Colors.blue,
          p: p,
        ),
        const SizedBox(height: 8),
        _buildAttachedDocumentTile(
          title: 'Internal Assessment & 75% Attendance Clearance Dossier',
          fileName: 'iat_attendance_cutoff_verification_report.pdf',
          fileSize: '1.8 MB',
          docType: 'Attendance Audit',
          icon: Icons.checklist_rounded,
          iconColor: Colors.green,
          p: p,
        ),
        const SizedBox(height: 8),
        _buildAttachedDocumentTile(
          title: 'Laboratory & Practical External Examiner Clearance',
          fileName: 'lab_practical_external_viva_signoff.pdf',
          fileSize: '1.1 MB',
          docType: 'Practical Sign-Off',
          icon: Icons.biotech_rounded,
          iconColor: Colors.purple,
          p: p,
        ),
        if (p.isGraduation) ...[
          const SizedBox(height: 8),
          _buildAttachedDocumentTile(
            title: 'Alumni 2-Year Data Retention & Degree Award Certificate',
            fileName: 'alumni_2yr_data_retention_compliance_certificate.pdf',
            fileSize: '3.1 MB',
            docType: 'Alumni Compliance',
            icon: Icons.history_edu_rounded,
            iconColor: Colors.amber,
            p: p,
          ),
        ],

        // Document Expanded Preview (If clicked)
        if (_selectedDocumentName != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDocumentName!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _selectedDocumentName = null),
                    ),
                  ],
                ),
                const Divider(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ANNA UNIVERSITY CHENNAI — AFFILIATED INSTITUTIONS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Department of Artificial Intelligence & Data Science • ${p.batchYear}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'STATUS: VERIFIED & SEALED BY CONTROLLER OF EXAMINATIONS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'All candidate credits, internal assessments, continuous evaluations, laboratory clearances, and attendance minimums (>=75%) have been audited and found in full compliance with Regulation 2021.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachedDocumentTile({
    required String title,
    required String fileName,
    required String fileSize,
    required String docType,
    required IconData icon,
    required Color iconColor,
    required PromotionRequest p,
  }) {
    final isSelected = _selectedDocumentName == fileName;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        subtitle: Text('$fileName • $fileSize • $docType', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        trailing: ElevatedButton(
          onPressed: () => setState(() => _selectedDocumentName = fileName),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
            foregroundColor: isSelected ? Colors.white : const Color(0xFF0F172A),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(isSelected ? 'Viewing' : 'Inspect Proof', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildStudentRosterTab(PromotionRequest p) {
    final students = StudentDirectoryData.bySection['${p.fromYear}-${p.section}'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Batch Student Roster (${students.length} Candidates)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('100% Eligible', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...students.take(15).map((st) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: Text(
                    st.name.isNotEmpty ? st.name[0] : 'S',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('Roll: ${st.rollNumber} • Sem ${p.semesterCompleted} Credits: 24/24', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('✓ Cleared', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                ),
              ],
            ),
          );
        }),
        if (students.length > 15)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '+ ${students.length - 15} more candidates verified in this batch',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOfficialSealsTab(PromotionRequest p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏛️ Official Department Endorsement & Signatures',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),

        // Class Advisor Sign-off Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, color: Color(0xFF0284C7), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Class Advisor Endorsement: ${p.advisorName ?? "Pending"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                p.advisorRemarks ?? 'Awaiting advisor review.',
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // HOD Final Authority Seal Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.status == PromotionApprovalStatus.approvedByHod ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: p.status == PromotionApprovalStatus.approvedByHod ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    p.status == PromotionApprovalStatus.approvedByHod ? Icons.verified_rounded : Icons.pending_actions_rounded,
                    color: p.status == PromotionApprovalStatus.approvedByHod ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HOD Authority Approval: ${p.hodName ?? "Head of Department (AI&DS)"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                p.hodRemarks ?? 'Pending final HOD review and digital signature stamp.',
                style: TextStyle(
                  fontSize: 11,
                  color: p.status == PromotionApprovalStatus.approvedByHod ? const Color(0xFF166534) : const Color(0xFF92400E),
                  fontWeight: p.status == PromotionApprovalStatus.approvedByHod ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
