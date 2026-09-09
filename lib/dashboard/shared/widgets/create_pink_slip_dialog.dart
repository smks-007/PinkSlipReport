import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/leave_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/mock_data_service.dart';

/// Interactive dialog for the concerned Class Advisor to create/issue an official Pink Slip,
/// allowing them to explicitly mark a student as Present (e.g. OD / Event) or Absent (e.g. Leave / Medical).
class CreatePinkSlipDialog extends StatefulWidget {
  final StudentModel? initialStudent;
  final DateTime? initialDate;
  final bool initialMarkPresent;
  final ValueChanged<LeaveModel>? onSlipCreated;

  const CreatePinkSlipDialog({
    super.key,
    this.initialStudent,
    this.initialDate,
    this.initialMarkPresent = false,
    this.onSlipCreated,
  });

  @override
  State<CreatePinkSlipDialog> createState() => _CreatePinkSlipDialogState();
}

class _CreatePinkSlipDialogState extends State<CreatePinkSlipDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late bool _markPresent;
  late LeaveCategory _category;
  LeaveType _leaveType = LeaveType.informed;
  StudentModel? _selectedStudent;
  late List<StudentModel> _classStudents;

  final _reasonCtrl = TextEditingController();
  final _advisorRemarksCtrl = TextEditingController();

  String _attachedFileName = 'advisor_signed_clearance.pdf';
  String _attachedFileType = 'Official Pink Slip Endorsement';
  String _attachedFileSize = '1.1 MB';
  bool _hasAttachment = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _markPresent = widget.initialMarkPresent;
    _category = _markPresent ? LeaveCategory.onDuty : LeaveCategory.leave;

    final user = AuthService().currentUser;
    final int year = user?.year ?? 2;
    final String section = user?.section ?? 'B';

    _classStudents = MockDataService.getStudentsBySection(year, section);
    if (_classStudents.isEmpty) {
      _classStudents = MockDataService.allStudents.take(20).toList();
    }

    if (widget.initialStudent != null) {
      _selectedStudent = _classStudents.firstWhere(
        (s) => s.id == widget.initialStudent!.id || s.rollNumber == widget.initialStudent!.rollNumber,
        orElse: () => widget.initialStudent!,
      );
    } else {
      _selectedStudent = _classStudents.isNotEmpty ? _classStudents.first : null;
    }

    _updateDefaultTexts();
  }

  void _updateDefaultTexts() {
    final user = AuthService().currentUser;
    final advisorName = user?.name ?? 'Class Advisor';

    if (_markPresent) {
      if (_reasonCtrl.text.isEmpty || _reasonCtrl.text == 'Medical / Sick Leave' || _reasonCtrl.text == 'Personal Reason') {
        _reasonCtrl.text = 'On-Duty: Academic Symposium / Project Duty';
      }
      _attachedFileName = 'od_clearance_${_selectedStudent?.rollNumber ?? "doc"}.pdf';
      _attachedFileType = 'On-Duty Clearance Letter';
    } else {
      if (_reasonCtrl.text.isEmpty || _reasonCtrl.text.startsWith('On-Duty')) {
        _reasonCtrl.text = 'Medical / Sick Leave';
      }
      _attachedFileName = 'pink_slip_absent_${_selectedStudent?.rollNumber ?? "doc"}.pdf';
      _attachedFileType = 'Advisor Issued Pink Slip';
    }

    _advisorRemarksCtrl.text =
        'Authorized by Class Advisor $advisorName. Attendance marked as ${_markPresent ? "PRESENT (OD)" : "ABSENT"}.';
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _advisorRemarksCtrl.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _simulateFilePick() {
    setState(() {
      _attachedFileName = _markPresent
          ? 'od_proof_signed_${_selectedStudent?.rollNumber ?? "file"}.pdf'
          : 'doctor_signed_certificate_${_selectedStudent?.rollNumber ?? "file"}.pdf';
      _attachedFileType = _markPresent ? 'Faculty Approved OD Proof' : 'Doctor Medical Certificate';
      _attachedFileSize = '1.8 MB';
      _hasAttachment = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📎 Document attached: $_attachedFileName'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedStudent == null) return;

    final user = AuthService().currentUser;
    final advisorName = user?.name ?? 'Class Advisor';
    final advisorId = user?.id ?? 'adv-001';
    final int year = user?.year ?? _selectedStudent!.year;
    final String section = user?.section ?? _selectedStudent!.section;

    final newSlip = MockDataService.createAdvisorPinkSlip(
      student: _selectedStudent!,
      date: _selectedDate,
      markPresent: _markPresent,
      category: _category,
      leaveType: _leaveType,
      reason: _reasonCtrl.text.trim(),
      advisorName: advisorName,
      advisorId: advisorId,
      advisorRemarks: _advisorRemarksCtrl.text.trim(),
      attachmentFileName: _hasAttachment ? _attachedFileName : null,
      attachmentFileType: _hasAttachment ? _attachedFileType : null,
      attachmentFileSize: _hasAttachment ? _attachedFileSize : null,
      year: year,
      section: section,
    );

    widget.onSlipCreated?.call(newSlip);
    Navigator.pop(context, newSlip);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _markPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pink Slip issued for ${_selectedStudent!.name}! Marked ${_markPresent ? "PRESENT" : "ABSENT"}.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: _markPresent ? const Color(0xFF047857) : AppColors.absentRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isAdvisor = user?.role == UserRole.advisor;
    final year = user?.year ?? 2;
    final section = user?.section ?? 'B';
    final dateFormatted =
        '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 780),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF5FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Color(0xFFF3E8FF))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9333EA), Color(0xFFC026D3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Issue Official Pink Slip',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAdvisor
                                    ? '$year Year AI&DS - Sec $section (Class Scope)'
                                    : 'Department Class Advisor Portal',
                                style: const TextStyle(
                                  color: Color(0xFF7E22CE),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dual Action Selector: Mark Present vs Mark Absent
                      const Text(
                        'Pink Slip Attendance Action',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Mark Absent Card
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _markPresent = false;
                                  _category = LeaveCategory.leave;
                                  _updateDefaultTexts();
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: !_markPresent ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: !_markPresent ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                                    width: !_markPresent ? 2 : 1,
                                  ),
                                  boxShadow: !_markPresent
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cancel_rounded,
                                          size: 18,
                                          color: !_markPresent ? const Color(0xFFDC2626) : Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Mark ABSENT',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: !_markPresent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Leave / Medical / Sick',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: !_markPresent ? const Color(0xFFB91C1C) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Mark Present Card
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _markPresent = true;
                                  _category = LeaveCategory.onDuty;
                                  _updateDefaultTexts();
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: _markPresent ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _markPresent ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                                    width: _markPresent ? 2 : 1,
                                  ),
                                  boxShadow: _markPresent
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                          color: _markPresent ? const Color(0xFF059669) : Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Mark PRESENT',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _markPresent ? const Color(0xFF059669) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'On-Duty / Clearance / Event',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: _markPresent ? const Color(0xFF047857) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Select Student
                      const Text(
                        'Select Student from Assigned Class',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<StudentModel>(
                        initialValue: _selectedStudent,
                        isExpanded: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_rounded, size: 20, color: AppColors.primaryPurple),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        items: _classStudents.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Text(
                                  s.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${s.rollNumber})',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedStudent = val;
                              _updateDefaultTexts();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date & Category Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Attendance Date',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _selectDate,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFFF8FAFC),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryPurple),
                                        const SizedBox(width: 8),
                                        Text(
                                          dateFormatted,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Slip Category',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFFF8FAFC),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<LeaveCategory>(
                                      value: _category,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(
                                          value: LeaveCategory.leave,
                                          child: Text('Standard Leave', style: TextStyle(fontSize: 12.5)),
                                        ),
                                        DropdownMenuItem(
                                          value: LeaveCategory.onDuty,
                                          child: Text('On-Duty (OD)', style: TextStyle(fontSize: 12.5)),
                                        ),
                                      ],
                                      onChanged: (cat) {
                                        if (cat != null) {
                                          setState(() => _category = cat);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Leave Type Dropdown (Informed / Uninformed)
                      const Text(
                        'Leave Type',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF8FAFC),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<LeaveType>(
                            value: _leaveType,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryPurple, size: 28),
                            items: const [
                              DropdownMenuItem(
                                value: LeaveType.informed,
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF059669)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Informed',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: LeaveType.uninformed,
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Uninformed',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _leaveType = val;
                                  if (val == LeaveType.uninformed) {
                                    _reasonCtrl.text = 'Uninformed Absence';
                                  } else {
                                    _reasonCtrl.text = _markPresent
                                        ? 'On-Duty: Academic Symposium / Project Duty'
                                        : 'Medical / Sick Leave';
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Reason / Purpose Text Field
                      const Text(
                        'Reason / Purpose',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _reasonCtrl,
                        maxLines: 2,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter reason for the pink slip' : null,
                        decoration: InputDecoration(
                          hintText: _markPresent ? 'Enter official OD or clearance details' : 'Enter absence reason',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Advisor Remarks & Authorization
                      const Text(
                        'Class Advisor Authorization Remarks',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _advisorRemarksCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Advisor remarks and endorsement notes',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Document Proof / Attachment
                      const Text(
                        'Official Document Proof (Pink Slip Record)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _attachedFileName,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$_attachedFileType • $_attachedFileSize',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _simulateFilePick,
                              icon: const Icon(Icons.upload_file, size: 14),
                              label: const Text('Change File'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Button
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(
                  _markPresent ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                  size: 18,
                ),
                label: Text(
                  _markPresent
                      ? 'Issue Pink Slip & Mark as PRESENT'
                      : 'Issue Pink Slip & Mark as ABSENT',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _markPresent ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
