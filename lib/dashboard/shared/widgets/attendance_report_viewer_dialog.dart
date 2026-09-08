import 'package:flutter/material.dart';
import '../../../../core/services/mock_data_service.dart';

/// Full interactive Daily Attendance & Defaulter Summary Report Viewer.
/// Allows Advisors and HOD to inspect attached muster rolls, parent intimation letters,
/// export official reports, and print attendance records.
class AttendanceReportViewerDialog extends StatefulWidget {
  final int? year;
  final String? section;
  final DateTime? date;

  const AttendanceReportViewerDialog({
    super.key,
    this.year,
    this.section,
    this.date,
  });

  static void show(
    BuildContext context, {
    int? year,
    String? section,
    DateTime? date,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AttendanceReportViewerDialog(
        year: year,
        section: section,
        date: date,
      ),
    );
  }

  @override
  State<AttendanceReportViewerDialog> createState() => _AttendanceReportViewerDialogState();
}

class _AttendanceReportViewerDialogState extends State<AttendanceReportViewerDialog> {
  String? _selectedDocumentName;

  @override
  Widget build(BuildContext context) {
    final targetDate = widget.date ?? DateTime(2026, 9, 7);
    final isSection = widget.year != null && widget.section != null;
    
    final strength = isSection
        ? MockDataService.getSectionStrength(widget.year!, widget.section!)
        : MockDataService.totalStrength;
    final present = isSection
        ? MockDataService.getSectionPresent(widget.year!, widget.section!, targetDate)
        : MockDataService.presentToday;
    final absent = isSection
        ? MockDataService.getSectionAbsent(widget.year!, widget.section!, targetDate)
        : MockDataService.absentToday;
    final od = isSection
        ? MockDataService.getSectionOnDuty(widget.year!, widget.section!, targetDate)
        : 8;
    final percentage = isSection
        ? MockDataService.getSectionAttendancePercentage(widget.year!, widget.section!, targetDate)
        : MockDataService.attendancePercentage;

    final dateStr = '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';

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
            // Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF4F46E5)],
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
                    child: const Icon(Icons.fact_check_rounded, color: Color(0xFF818CF8), size: 24),
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
                          isSection
                              ? 'OFFICIAL ATTENDANCE REPORT • YR ${widget.year}-${widget.section} • $dateStr'
                              : 'DEPARTMENT OVERALL ATTENDANCE REPORT (ALL 10 SECTIONS) • $dateStr',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
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

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Metrics Grid
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('Attendance', '${percentage.toStringAsFixed(1)}%', const Color(0xFF4F46E5)),
                          Container(height: 30, width: 1, color: const Color(0xFFCBD5E1)),
                          _buildStatItem('Present', '$present / $strength', const Color(0xFF16A34A)),
                          Container(height: 30, width: 1, color: const Color(0xFFCBD5E1)),
                          _buildStatItem('Absent Today', '$absent', const Color(0xFFDC2626)),
                          Container(height: 30, width: 1, color: const Color(0xFFCBD5E1)),
                          _buildStatItem('On-Duty (OD)', '$od', const Color(0xFF0284C7)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Attached Reports & Files
                    const Text(
                      '📎 Attached Attendance Documents & Official Records',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Click to open and inspect verified muster rolls, OD approvals, and parent notices:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),

                    _buildDocTile(
                      title: 'Official Daily Attendance Muster Roll Sheet',
                      fileName: 'muster_roll_report_${targetDate.day}_${targetDate.month}_2026.pdf',
                      fileSize: '1.2 MB',
                      docType: 'Daily Attendance Sheet',
                      icon: Icons.assignment_turned_in_rounded,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildDocTile(
                      title: 'Parent Intimation Letter & Defaulter Notice Batch',
                      fileName: 'parent_intimation_defaulter_notices.pdf',
                      fileSize: '940 KB',
                      docType: 'Parent Communication',
                      icon: Icons.mark_email_read_rounded,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 8),
                    _buildDocTile(
                      title: 'On-Duty (OD) Symposium & Sports Sanction Order',
                      fileName: 'sanctioned_od_event_clearance.pdf',
                      fileSize: '1.5 MB',
                      docType: 'OD Order',
                      icon: Icons.emoji_events_rounded,
                      color: Colors.green,
                    ),

                    // Document Expanded View
                    if (_selectedDocumentName != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
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
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'V.S.B. ENGINEERING COLLEGE • DEPARTMENT OF AI & DS',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Verified Daily Attendance Roll • Date: $dateStr',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'SEALED: DIGITALLY VERIFIED BY HEAD OF DEPARTMENT & CLASS ADVISOR',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'All $strength student biometric/manual attendance entries for $dateStr recorded. $present Present, $absent Absent, $od On-Duty. Ready for institutional archival.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Toolbar
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
                          content: Text('📥 Exporting Attendance Register PDF...'),
                          backgroundColor: Color(0xFF4F46E5),
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
                          content: Text('🖨️ Printing Attendance Register Sheet...'),
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
                    label: const Text('Print Roll', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildDocTile({
    required String title,
    required String fileName,
    required String fileSize,
    required String docType,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedDocumentName == fileName;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelected ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        subtitle: Text('$fileName • $fileSize • $docType', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        trailing: ElevatedButton(
          onPressed: () => setState(() => _selectedDocumentName = fileName),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
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
}
