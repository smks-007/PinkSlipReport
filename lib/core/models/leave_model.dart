/// Category: Standard Leave vs On-Duty (OD)
enum LeaveCategory { leave, onDuty }

/// Type of leave taken by the student.
enum LeaveType { informed, uninformed }

/// Status of the leave letter workflow.
enum LetterStatus {
  notSubmitted,
  submitted,
  forwarded,
  approved,
  rejected,
}

/// Represents a leave request or On-Duty (OD) application with file attachment & workflow tracking.
class LeaveModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentRollNumber;
  final LeaveCategory category;
  final String? section;
  final int? year;
  final String? batchYear;
  final DateTime leaveDate;
  final LeaveType leaveType;
  final String reason;
  final bool letterSubmitted;
  final LetterStatus letterStatus;
  final String? attachmentFileName;
  final String? attachmentFileType; // e.g., 'PDF Document', 'Medical Certificate', 'OD Endorsement'
  final String? attachmentFileSize; // e.g., '1.2 MB'
  final DateTime? dateSubmittedToAdvisor;
  final DateTime? dateReceivedByHod;
  final DateTime? dateApprovedRejected;
  final String? advisorId;
  final String? hodId;
  final String? advisorRemarks;
  final String? hodRemarks;
  final int dueDays;
  final int totalLeavesTaken;

  const LeaveModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentRollNumber,
    this.category = LeaveCategory.leave,
    this.section,
    this.year,
    this.batchYear,
    required this.leaveDate,
    required this.leaveType,
    required this.reason,
    this.letterSubmitted = false,
    this.letterStatus = LetterStatus.notSubmitted,
    this.attachmentFileName,
    this.attachmentFileType,
    this.attachmentFileSize,
    this.dateSubmittedToAdvisor,
    this.dateReceivedByHod,
    this.dateApprovedRejected,
    this.advisorId,
    this.hodId,
    this.advisorRemarks,
    this.hodRemarks,
    this.dueDays = 0,
    this.totalLeavesTaken = 0,
  });

  bool get hasAttachment =>
      attachmentFileName != null && attachmentFileName!.isNotEmpty;

  bool get isOnDuty => category == LeaveCategory.onDuty;

  String get categoryDisplay =>
      category == LeaveCategory.onDuty ? 'On-Duty (OD)' : 'Leave';

  String get leaveTypeDisplay =>
      leaveType == LeaveType.informed ? 'Informed' : 'Uninformed';

  String get letterStatusDisplay {
    switch (letterStatus) {
      case LetterStatus.notSubmitted:
        return 'Not Submitted';
      case LetterStatus.submitted:
        return 'Submitted to Advisor';
      case LetterStatus.forwarded:
        return 'Forwarded to HOD';
      case LetterStatus.approved:
        return 'Approved by HOD';
      case LetterStatus.rejected:
        return 'Rejected by HOD';
    }
  }

  LeaveModel copyWith({
    LetterStatus? letterStatus,
    DateTime? dateSubmittedToAdvisor,
    DateTime? dateReceivedByHod,
    DateTime? dateApprovedRejected,
    String? hodRemarks,
    String? advisorRemarks,
    String? attachmentFileName,
    String? attachmentFileType,
    String? attachmentFileSize,
    bool? letterSubmitted,
  }) {
    return LeaveModel(
      id: id,
      studentId: studentId,
      studentName: studentName,
      studentRollNumber: studentRollNumber,
      category: category,
      section: section,
      year: year,
      batchYear: batchYear,
      leaveDate: leaveDate,
      leaveType: leaveType,
      reason: reason,
      letterSubmitted: letterSubmitted ?? this.letterSubmitted,
      letterStatus: letterStatus ?? this.letterStatus,
      attachmentFileName: attachmentFileName ?? this.attachmentFileName,
      attachmentFileType: attachmentFileType ?? this.attachmentFileType,
      attachmentFileSize: attachmentFileSize ?? this.attachmentFileSize,
      dateSubmittedToAdvisor:
          dateSubmittedToAdvisor ?? this.dateSubmittedToAdvisor,
      dateReceivedByHod: dateReceivedByHod ?? this.dateReceivedByHod,
      dateApprovedRejected:
          dateApprovedRejected ?? this.dateApprovedRejected,
      advisorId: advisorId,
      hodId: hodId,
      advisorRemarks: advisorRemarks ?? this.advisorRemarks,
      hodRemarks: hodRemarks ?? this.hodRemarks,
      dueDays: dueDays,
      totalLeavesTaken: totalLeavesTaken,
    );
  }
}
