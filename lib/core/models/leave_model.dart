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

/// Represents a leave request with full workflow tracking.
class LeaveModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentRollNumber;
  final DateTime leaveDate;
  final LeaveType leaveType;
  final String reason;
  final bool letterSubmitted;
  final LetterStatus letterStatus;
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
    required this.leaveDate,
    required this.leaveType,
    required this.reason,
    this.letterSubmitted = false,
    this.letterStatus = LetterStatus.notSubmitted,
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

  String get leaveTypeDisplay =>
      leaveType == LeaveType.informed ? 'Informed' : 'Uninformed';

  String get letterStatusDisplay {
    switch (letterStatus) {
      case LetterStatus.notSubmitted:
        return 'Not Submitted';
      case LetterStatus.submitted:
        return 'Submitted';
      case LetterStatus.forwarded:
        return 'Forwarded to HOD';
      case LetterStatus.approved:
        return 'Approved';
      case LetterStatus.rejected:
        return 'Rejected';
    }
  }

  LeaveModel copyWith({
    LetterStatus? letterStatus,
    DateTime? dateReceivedByHod,
    DateTime? dateApprovedRejected,
    String? hodRemarks,
    String? advisorRemarks,
  }) {
    return LeaveModel(
      id: id,
      studentId: studentId,
      studentName: studentName,
      studentRollNumber: studentRollNumber,
      leaveDate: leaveDate,
      leaveType: leaveType,
      reason: reason,
      letterSubmitted: letterSubmitted,
      letterStatus: letterStatus ?? this.letterStatus,
      dateSubmittedToAdvisor: dateSubmittedToAdvisor,
      dateReceivedByHod: dateReceivedByHod ?? this.dateReceivedByHod,
      dateApprovedRejected: dateApprovedRejected ?? this.dateApprovedRejected,
      advisorId: advisorId,
      hodId: hodId,
      advisorRemarks: advisorRemarks ?? this.advisorRemarks,
      hodRemarks: hodRemarks ?? this.hodRemarks,
      dueDays: dueDays,
      totalLeavesTaken: totalLeavesTaken,
    );
  }
}
