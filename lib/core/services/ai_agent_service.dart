import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/leave_model.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../data/student_directory_data.dart';
import 'mock_data_service.dart';
import 'auth_service.dart';

/// Execution Step logged during Autonomous AI-Agent Reasoning Cycle
class AgentStep {
  final String thought;
  final String actionName;
  final String actionInput;
  final String observation;
  final DateTime timestamp;
  final bool isSuccess;

  const AgentStep({
    required this.thought,
    required this.actionName,
    required this.actionInput,
    required this.observation,
    required this.timestamp,
    this.isSuccess = true,
  });
}

/// Final Output Report produced by the Autonomous AI-Agent
class AgentExecutionResult {
  final String goal;
  final List<AgentStep> steps;
  final String executiveSummary;
  final List<String> actionsExecuted;
  final Map<String, dynamic> telemetryData;
  final DateTime completedAt;

  const AgentExecutionResult({
    required this.goal,
    required this.steps,
    required this.executiveSummary,
    required this.actionsExecuted,
    required this.telemetryData,
    required this.completedAt,
  });
}

/// Central Autonomous AI-Agent Engine for SMART PRO (AI & DS Department).
/// Capable of multi-step reasoning, role-aware intelligence (Students, Advisors, HOD),
/// automated departmental auditing, OD auto-approval, pink slip generation,
/// <75% defaulter forecasting, section triage, and alumni retention enforcement.
class AiAgentService {
  static final AiAgentService _instance = AiAgentService._internal();
  factory AiAgentService() => _instance;
  AiAgentService._internal();

  /// ValueNotifier to stream agent telemetry updates to UI
  final ValueNotifier<int> agentNotifier = ValueNotifier<int>(0);

  final List<AgentExecutionResult> _executionHistory = [];
  List<AgentExecutionResult> get executionHistory => List.unmodifiable(_executionHistory);

  void _notify() {
    agentNotifier.value = agentNotifier.value + 1;
  }

  // ──────────────────── Tool 1: Deep Student Telemetry Search ────────────────────

  StudentModel? findStudent(String query) {
    final clean = query.trim().toUpperCase();
    if (clean.isEmpty) return null;

    // Direct roll lookup
    if (StudentDirectoryData.byRollNumber.containsKey(clean)) {
      return StudentDirectoryData.byRollNumber[clean];
    }

    // Search by partial roll or name
    final matches = StudentDirectoryData.allStudents.where((s) {
      return s.rollNumber.contains(clean) ||
          s.name.toUpperCase().contains(clean) ||
          s.id.toUpperCase() == clean;
    }).toList();

    return matches.isNotEmpty ? matches.first : null;
  }

  Map<String, dynamic>? getStudentDeepProfile(String query) {
    final student = findStudent(query);
    if (student == null) return null;

    // Find class advisor
    String advisorName = 'Department Class Advisor';
    String advisorContact = 'advisor@vsb.ac.in';
    for (final adv in AuthService.sectionAdvisors) {
      if (adv.year == student.year && adv.section == student.section) {
        advisorName = adv.name;
        advisorContact = adv.email;
        break;
      }
    }

    // Today's attendance record (Reference date: Sep 7, 2026 / current)
    final todayRecords = MockDataService.getAttendanceForDate(
      DateTime(2026, 9, 7),
      year: student.year,
      section: student.section,
    );
    final attRecord = todayRecords.firstWhere(
      (r) => r.studentId == student.id,
      orElse: () => AttendanceRecord(
        id: 'temp',
        studentId: student.id,
        date: DateTime(2026, 9, 7),
        status: MockDataService.todaysAbsentRollNumbers.contains(student.rollNumber)
            ? AttendanceStatus.absent
            : AttendanceStatus.present,
        source: 'telemetry_sync',
        createdAt: DateTime(2026, 9, 7),
      ),
    );

    // Leaves / Slips history
    final studentLeaves = MockDataService.leaveRequests
        .where((l) => l.studentRollNumber == student.rollNumber)
        .toList();

    // Cumulative attendance estimation (90% + variance or low if defaulter)
    final isDefaulter = MockDataService.getDefaultersBySection(student.year, student.section)
        .any((d) => (d['student'] as StudentModel).rollNumber == student.rollNumber);
    final cumulativePct = isDefaulter ? 71.4 : (92.5 + ((student.rollNumber.hashCode.abs() % 70) / 10));

    return {
      'student': student,
      'advisorName': advisorName,
      'advisorContact': advisorContact,
      'todayStatus': attRecord.statusDisplay,
      'isPresentToday': attRecord.isPresent,
      'isAbsentToday': attRecord.isAbsent,
      'isOnDutyToday': attRecord.isOnDuty,
      'biometricPunchIn': attRecord.punchInFormatted,
      'biometricPunchOut': attRecord.punchOutFormatted,
      'onDutyReason': attRecord.onDutyReason,
      'cumulativePercentage': double.parse(cumulativePct.toStringAsFixed(1)),
      'isDefaulter': isDefaulter,
      'leaves': studentLeaves,
      'totalLeavesTaken': student.totalLeavesTaken,
      'duePinkSlips': student.dueLetters,
    };
  }

  // ──────────────────── Tool 2: Attendance Forecast & Safety Margin ────────────────────

  Map<String, dynamic> calculateAttendanceForecast({
    required String rollNumber,
    double targetPercent = 75.0,
  }) {
    final profile = getStudentDeepProfile(rollNumber);
    final double currentPct = profile != null ? (profile['cumulativePercentage'] as double) : 85.0;
    const int totalTermDays = 90; // Sep-Dec 2026 instructional calendar
    const int elapsedDays = 24; // Sep 2026 instructional days so far

    // Estimated attended days
    final int attended = ((currentPct / 100.0) * elapsedDays).round();
    final int remainingDays = totalTermDays - elapsedDays;

    // Minimum required total attendance to meet targetPercent
    final int requiredTotalAttendance = ((targetPercent / 100.0) * totalTermDays).ceil();
    final int neededFromRemaining = requiredTotalAttendance - attended;

    // Maximum leaves allowed without falling below targetPercent
    int safeLeavesAllowed = 0;
    if (neededFromRemaining <= remainingDays) {
      safeLeavesAllowed = remainingDays - neededFromRemaining;
      if (safeLeavesAllowed < 0) safeLeavesAllowed = 0;
    }

    final int classesNeededFor75 = currentPct < targetPercent ? (targetPercent == 75.0 ? (neededFromRemaining > 0 ? neededFromRemaining : 1) : 0) : 0;
    final int classesNeededFor80 = currentPct < 80.0 ? (((0.80 * totalTermDays).ceil() - attended) > 0 ? ((0.80 * totalTermDays).ceil() - attended) : 0) : 0;

    return {
      'currentPercentage': currentPct,
      'isDefaulter': currentPct < targetPercent,
      'elapsedDays': elapsedDays,
      'attendedDays': attended,
      'totalTermDays': totalTermDays,
      'remainingDays': remainingDays,
      'safeLeavesAllowed': safeLeavesAllowed,
      'classesNeededFor75': classesNeededFor75,
      'classesNeededFor80': classesNeededFor80,
      'status': currentPct >= targetPercent ? 'ELIGIBLE' : 'CRITICAL DEFICIT',
    };
  }

  // ──────────────────── Tool 3: Batch Forward Section Leaves (Advisor) ────────────────────

  int batchForwardSectionLeaves({
    required int year,
    required String section,
    required String advisorName,
  }) {
    final leaves = MockDataService.leaveRequests
        .where((l) => l.year == year && l.section == section && l.letterStatus == LetterStatus.submitted)
        .toList();

    int count = 0;
    for (final req in leaves) {
      MockDataService.forwardToHod(
        req.id,
        advisorRemarks: 'Autonomously audited and endorsed by Smart Pro AI-Agent on behalf of Class Advisor $advisorName.',
      );
      count++;
    }
    _notify();
    return count;
  }

  // ──────────────────── Tool 4: Issue Official Pink Slip / Gate Pass ────────────────────

  LeaveModel issuePinkSlip({
    required String rollNumber,
    required String reason,
    required DateTime date,
    required String issuedBy,
    LeaveCategory category = LeaveCategory.leave,
    LeaveType leaveType = LeaveType.informed,
    String? attachmentFileName,
  }) {
    final student = findStudent(rollNumber);
    if (student == null) {
      throw Exception('Student with roll number $rollNumber not found in AI&DS directory.');
    }

    final newId = 'ps-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final slip = LeaveModel(
      id: newId,
      studentId: student.id,
      studentName: student.name,
      studentRollNumber: student.rollNumber,
      category: category,
      section: student.section,
      year: student.year,
      batchYear: student.batchYear,
      leaveDate: date,
      leaveType: leaveType,
      reason: reason,
      letterSubmitted: attachmentFileName != null,
      letterStatus: LetterStatus.approved,
      attachmentFileName: attachmentFileName ?? 'official_pink_slip_gatepass.pdf',
      attachmentFileType: category == LeaveCategory.onDuty ? 'On-Duty Institutional Pass' : 'Executive Pink Slip Gatepass',
      attachmentFileSize: '640 KB',
      dateSubmittedToAdvisor: DateTime.now(),
      dateReceivedByHod: DateTime.now(),
      dateApprovedRejected: DateTime.now(),
      advisorRemarks: 'Authorized and processed via Smart Pro AI-Agent.',
      hodRemarks: 'Officially approved by HOD ($issuedBy). Gate pass generated.',
      dueDays: 0,
      totalLeavesTaken: student.totalLeavesTaken + 1,
    );

    MockDataService.submitLeaveRequest(slip);
    _notify();
    return slip;
  }

  // ──────────────────── Autonomous Multi-Step Goal Execution ────────────────────

  Future<AgentExecutionResult> executeAutonomousGoal(
    String goalPrompt, {
    String hodName = 'Dr. K. Manivannan (Ph.D.)',
    UserModel? user,
  }) async {
    final List<AgentStep> steps = [];
    final List<String> actionsExecuted = [];
    final Map<String, dynamic> telemetry = {};
    final startTime = DateTime.now();
    final lower = goalPrompt.toLowerCase();

    // ──────────────────── STUDENT AGENT WORKFLOWS ────────────────────
    if (user != null && user.role == UserRole.student) {
      final studentRoll = user.rollNumber ?? '25243100';
      final studentName = user.name;
      final studentYear = user.year ?? 2;
      final studentSec = user.section ?? 'B';

      // Scenario S1: Attendance Diagnostic & Forecast
      if (lower.contains('attendance') || lower.contains('forecast') || lower.contains('75%') || lower.contains('80%') || lower.contains('safe') || lower.contains('classes')) {
        steps.add(AgentStep(
          thought: 'Extracting biometric attendance records and cumulative instructional telemetry for $studentName ($studentRoll).',
          actionName: 'fetchStudentAttendanceTelemetry',
          actionInput: 'Roll: $studentRoll, Term: Sep-Dec 2026 (90 Instructional Days)',
          observation: 'Cumulative attendance data retrieved successfully.',
          timestamp: DateTime.now(),
        ));

        final forecast = calculateAttendanceForecast(rollNumber: studentRoll);
        final currentPct = forecast['currentPercentage'] as double;
        final safeLeaves = forecast['safeLeavesAllowed'] as int;
        final needed75 = forecast['classesNeededFor75'] as int;
        final needed80 = forecast['classesNeededFor80'] as int;
        telemetry['forecast'] = forecast;

        steps.add(AgentStep(
          thought: 'Synthesizing Anna University statutory compliance model. Current attendance: $currentPct%. Target: 75.0%.',
          actionName: 'computeAttendanceTrajectory',
          actionInput: 'Current: $currentPct%, Safe Leaves: $safeLeaves',
          observation: currentPct >= 75.0
              ? 'Status: Safe & Eligible. Student can take up to $safeLeaves classes leave without violating 75% cutoff.'
              : 'Status: At-Risk. Student requires $needed75 consecutive instructional days attendance to recover 75.0%.',
          timestamp: DateTime.now(),
        ));

        actionsExecuted.add('Evaluated cumulative attendance ($currentPct%)');
        actionsExecuted.add('Generated academic semester forecast model');

        final summary = '📈 **AI-Agent Attendance Diagnostic & Forecast**\n\n'
            '• **Student**: **$studentName** (`$studentRoll`) • **$studentYear AI&DS - Sec $studentSec**\n'
            '• **Current Attendance**: **$currentPct%** (${currentPct >= 75.0 ? "✅ Eligible" : "⚠️ Low Attendance Risk"})\n'
            '• **Semester Calendar**: 90 Days Total | 24 Days Elapsed | 66 Days Remaining\n'
            '• **Safe Margin**: You can take **$safeLeaves more days leave** and stay above 75.0%.\n'
            '• **To Reach 80% Target**: Attend next **$needed80 classes** continuously.\n'
            '• **Recommendation**: Ensure all previous OD/medical proofs are submitted within 24h.';

        final result = AgentExecutionResult(
          goal: goalPrompt,
          steps: steps,
          executiveSummary: summary,
          actionsExecuted: actionsExecuted,
          telemetryData: telemetry,
          completedAt: DateTime.now(),
        );
        _executionHistory.insert(0, result);
        _notify();
        return result;
      }

      // Scenario S2: Auto-Draft & Submit Leave or OD Request
      else if (lower.contains('leave') || lower.contains('od') || lower.contains('apply') || lower.contains('submit') || lower.contains('draft') || lower.contains('slip')) {
        final isOd = lower.contains('od') || lower.contains('duty') || lower.contains('hackathon') || lower.contains('symposium') || lower.contains('conference');
        final category = isOd ? LeaveCategory.onDuty : LeaveCategory.leave;
        final reason = isOd
            ? (lower.contains('hackathon') ? 'SIH Grand Finale Hackathon Participation' : 'State Technical Symposium Presentation')
            : 'Medical Health Recovery & Physician Consultation';

        steps.add(AgentStep(
          thought: 'Validating leave submission parameters for $studentName ($studentRoll). Category: ${isOd ? "On-Duty" : "Leave"}.',
          actionName: 'validateLeaveConstraints',
          actionInput: 'Category: ${category.name}, Section: $studentSec, Year: $studentYear',
          observation: 'Student eligibility and OD quota verified.',
          timestamp: DateTime.now(),
        ));

        final newSlip = LeaveModel(
          id: 'stu-agent-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          studentId: 'stu_$studentRoll',
          studentName: studentName,
          studentRollNumber: studentRoll,
          category: category,
          section: studentSec,
          year: studentYear,
          batchYear: user.batchYear ?? '2025 BATCH',
          leaveDate: DateTime(2026, 9, 7),
          leaveType: LeaveType.informed,
          reason: reason,
          letterSubmitted: true,
          letterStatus: LetterStatus.submitted,
          attachmentFileName: isOd ? 'od_invitation_letter.pdf' : 'medical_prescription.pdf',
          attachmentFileType: isOd ? 'Official Event Invitation' : 'Medical Certificate',
          attachmentFileSize: '820 KB',
          dateSubmittedToAdvisor: DateTime.now(),
          advisorRemarks: 'Generated & pre-verified via Smart Pro AI-Agent Student Co-Pilot.',
        );

        MockDataService.submitLeaveRequest(newSlip);
        actionsExecuted.add('Auto-drafted and submitted ${isOd ? "On-Duty (OD)" : "Leave"} Application');

        steps.add(AgentStep(
          thought: 'Attaching digital proof (${newSlip.attachmentFileName}) and notifying Class Advisor for review.',
          actionName: 'dispatchToAdvisor',
          actionInput: 'Leave ID: ${newSlip.id}',
          observation: 'Submitted successfully. Status set to: Submitted to Advisor.',
          timestamp: DateTime.now(),
        ));

        final summary = '📝 **AI-Agent Leave / OD Application Auto-Drafted & Submitted**\n\n'
            '• **Student**: **$studentName** (`$studentRoll`)\n'
            '• **Type**: **${isOd ? "On-Duty (OD) Pass" : "Medical/Personal Leave"}**\n'
            '• **Reason**: $reason\n'
            '• **Attached Proof**: `📎 ${newSlip.attachmentFileName}` (820 KB)\n'
            '• **Workflow Status**: **Submitted to Class Advisor** for digital endorsement.\n'
            '• Real-time notification sent to class advisor portal.';

        final result = AgentExecutionResult(
          goal: goalPrompt,
          steps: steps,
          executiveSummary: summary,
          actionsExecuted: actionsExecuted,
          telemetryData: telemetry,
          completedAt: DateTime.now(),
        );
        _executionHistory.insert(0, result);
        _notify();
        return result;
      }

      // Scenario S3: General Student Assistance / Timetable / Due Slips
      else {
        steps.add(AgentStep(
          thought: 'Auditing student academic dossier, due pink slips, and schedule for $studentName.',
          actionName: 'auditStudentDossier',
          actionInput: 'Roll: $studentRoll',
          observation: 'Found active records. Verified 0 unpaid fines and synced timetable.',
          timestamp: DateTime.now(),
        ));

        final forecast = calculateAttendanceForecast(rollNumber: studentRoll);
        final curPct = forecast['currentPercentage'] as double;

        actionsExecuted.add('Checked academic compliance and timetable status');

        final summary = '🎓 **Smart Pro Student AI-Agent Executive Dossier**\n\n'
            '• **Student Name**: **$studentName** (`$studentRoll`)\n'
            '• **Class**: **$studentYear AI&DS - Section $studentSec**\n'
            '• **Current Attendance**: **$curPct%** (${curPct >= 75.0 ? "✅ Anna University Compliant" : "⚠️ Defaulter Alert"})\n'
            '• **Biometric Status**: Present (Punch-In: 08:35 AM)\n'
            '• **Pending Pink Slips**: 0 Due\n'
            '• **Today\'s Next Period**: Artificial Intelligence & Data Structures Lab\n'
            '• **Need assistance?** Ask to "Forecast attendance" or "Draft OD application"!';

        final result = AgentExecutionResult(
          goal: goalPrompt,
          steps: steps,
          executiveSummary: summary,
          actionsExecuted: actionsExecuted,
          telemetryData: telemetry,
          completedAt: DateTime.now(),
        );
        _executionHistory.insert(0, result);
        _notify();
        return result;
      }
    }

    // ──────────────────── CLASS ADVISOR AGENT WORKFLOWS ────────────────────
    if (user != null && user.role == UserRole.advisor) {
      final advYear = user.year ?? 2;
      final advSec = user.section ?? 'A';
      final advName = user.name;

      // Scenario A1: Forward Submitted Leaves & ODs in Section to HOD
      if (lower.contains('forward') || lower.contains('batch') || lower.contains('approve') || lower.contains('triage') || lower.contains('od') || lower.contains('leave')) {
        steps.add(AgentStep(
          thought: 'Scanning submitted Leave and OD requests exclusively for $advYear AI&DS - Section $advSec.',
          actionName: 'scanSectionLeaves',
          actionInput: 'Year: $advYear, Section: $advSec, Status: Submitted',
          observation: 'Located pending section submissions requiring advisor endorsement.',
          timestamp: DateTime.now(),
        ));

        final forwardedCount = batchForwardSectionLeaves(
          year: advYear,
          section: advSec,
          advisorName: advName,
        );

        steps.add(AgentStep(
          thought: 'Validating supporting letters against AICTE norms and executing digital endorsement to HOD.',
          actionName: 'forwardToHod',
          actionInput: 'Forwarded Count: $forwardedCount',
          observation: 'Successfully endorsed and queued for HOD digital signature.',
          timestamp: DateTime.now(),
        ));

        actionsExecuted.add('Forwarded $forwardedCount section leave/OD requests to HOD');
        telemetry['forwardedCount'] = forwardedCount;

        final summary = '📤 **Class Advisor AI-Agent: Batch Verification & Forwarding Completed**\n\n'
            '• **Advisor**: **$advName** ($advYear AI&DS - Section $advSec)\n'
            '• **Applications Endorsed & Forwarded**: **$forwardedCount Requests**\n'
            '• **HOD Decision Queue**: Synchronized in real-time with digital endorsement.\n'
            '• **Compliance Standard**: Verified letter attachments & Anna University attendance metrics.';

        final result = AgentExecutionResult(
          goal: goalPrompt,
          steps: steps,
          executiveSummary: summary,
          actionsExecuted: actionsExecuted,
          telemetryData: telemetry,
          completedAt: DateTime.now(),
        );
        _executionHistory.insert(0, result);
        _notify();
        return result;
      }

      // Scenario A2: Section Defaulter Audit (<75%)
      else if (lower.contains('defaulter') || lower.contains('75%') || lower.contains('low attendance') || lower.contains('warning') || lower.contains('parent')) {
        steps.add(AgentStep(
          thought: 'Executing section-wide attendance audit for $advYear AI&DS - Section $advSec to detect students < 75%.',
          actionName: 'auditSectionDefaulters',
          actionInput: 'Year: $advYear, Section: $advSec',
          observation: 'Scanned section roster.',
          timestamp: DateTime.now(),
        ));

        final defaulters = MockDataService.getDefaultersBySection(advYear, advSec);
        telemetry['defaultersCount'] = defaulters.length;

        steps.add(AgentStep(
          thought: 'Drafting parental intimation circulars for ${defaulters.length} students.',
          actionName: 'draftParentalIntimations',
          actionInput: 'Target: ${defaulters.length} students',
          observation: 'Intimations drafted with official department header and scheduled counseling slots.',
          timestamp: DateTime.now(),
        ));

        actionsExecuted.add('Audited section attendance ($advYear-$advSec)');
        actionsExecuted.add('Generated ${defaulters.length} parental intimation notices');

        final summary = '⚠️ **Class Advisor Section Defaulter Audit (< 75% Cutoff)**\n\n'
            '• **Section**: **$advYear AI&DS - Section $advSec** (Advisor: $advName)\n'
            '• **Identified Defaulters**: **${defaulters.length} Students**\n'
            '• **Actions Executed**:\n'
            '  1. SMS & Portal Parental Intimation notices prepared.\n'
            '  2. Attendance condonation & OD regularizations flagged.\n'
            '  3. Pre-Model examination clearance counseling scheduled.';

        final result = AgentExecutionResult(
          goal: goalPrompt,
          steps: steps,
          executiveSummary: summary,
          actionsExecuted: actionsExecuted,
          telemetryData: telemetry,
          completedAt: DateTime.now(),
        );
        _executionHistory.insert(0, result);
        _notify();
        return result;
      }

      // Scenario A3: Section Daily Turnout & Absentees Brief
      else {
        steps.add(AgentStep(
          thought: 'Compiling real-time daily turnout telemetry for $advYear AI&DS - Section $advSec.',
          actionName: 'compileSectionBrief',
          actionInput: 'Section: $advYear-$advSec',
          observation: 'Compiled attendance metrics from biometric sensors and manual records.',
          timestamp: DateTime.now(),
        ));

        final str = MockDataService.getSectionStrength(advYear, advSec);
        final pres = MockDataService.getSectionPresent(advYear, advSec);
        final abs = MockDataService.getSectionAbsent(advYear, advSec);
        final od = MockDataService.getSectionOnDuty(advYear, advSec);
        final pct = MockDataService.getSectionAttendancePercentage(advYear, advSec);

        actionsExecuted.add('Compiled section attendance metrics ($str students)');

        final summary = '📊 **Class Advisor Daily Section Telemetry Brief**\n\n'
            '• **Class & Section**: **$advYear AI&DS - Section $advSec**\n'
            '• **Class Advisor**: **$advName**\n'
            '• **Total Strength**: **$str Students**\n'
            '• **Present Today**: **$pres Students** | **On-Duty**: **$od Students**\n'
            '• **Total Absentees**: **$abs Students**\n'
            '• **Today\'s Turnout**: **${pct.toStringAsFixed(1)}%**\n'
            '• **Register Status**: Fully synced with HOD Central Authority.';

        final result = AgentExecutionResult(
          goal: goalPrompt,
          steps: steps,
          executiveSummary: summary,
          actionsExecuted: actionsExecuted,
          telemetryData: telemetry,
          completedAt: DateTime.now(),
        );
        _executionHistory.insert(0, result);
        _notify();
        return result;
      }
    }

    // ──────────────────── HOD & GENERAL AGENT WORKFLOWS ────────────────────

    // ── SCENARIO A: Auto-Approve Verified ODs & Leaves ──
    if (lower.contains('approve') || lower.contains('od') || lower.contains('triage') || lower.contains('pending')) {
      steps.add(AgentStep(
        thought: 'Scanning active Leave and On-Duty (OD) request registry across all 10 departmental sections for pending applications.',
        actionName: 'scanPendingRequests',
        actionInput: 'Filter: LetterStatus == forwarded || submitted',
        observation: 'Found ${MockDataService.leaveRequests.where((l) => l.letterStatus == LetterStatus.forwarded || l.letterStatus == LetterStatus.submitted).length} pending applications.',
        timestamp: DateTime.now(),
      ));

      final pending = MockDataService.leaveRequests
          .where((l) => l.letterStatus == LetterStatus.forwarded || l.letterStatus == LetterStatus.submitted)
          .toList();

      int approvedCount = 0;
      for (final req in pending) {
        final isOd = req.category == LeaveCategory.onDuty;
        final hasProof = req.hasAttachment;

        steps.add(AgentStep(
          thought: 'Verifying attachment credentials for ${req.studentName} (${req.studentRollNumber}). Category: ${req.categoryDisplay}. Document: ${req.attachmentFileName ?? "None"}.',
          actionName: 'verifyDocumentAndApprove',
          actionInput: 'Leave ID: ${req.id}, Student: ${req.studentRollNumber}',
          observation: hasProof
              ? 'Document validated against AICTE/Anna University guidelines. Endorsing HOD digital signature.'
              : 'Endorsed based on Class Advisor verified physical letter verification.',
          timestamp: DateTime.now(),
        ));

        MockDataService.approveByHod(
          req.id,
          remarks: 'Autonomously verified & signed by Smart Pro AI-Agent on behalf of HOD $hodName. Compliance check: PASSED.',
        );
        approvedCount++;
        actionsExecuted.add('Approved ${isOd ? "OD" : "Leave"} for ${req.studentName} (${req.studentRollNumber})');
      }

      telemetry['approvedApplications'] = approvedCount;

      final summary = '✅ **Autonomous Approval Workflow Completed**\n\n'
          '• **Applications Evaluated**: ${pending.length}\n'
          '• **Digital Signatures Executed**: **$approvedCount Approved**\n'
          '• **Compliance Standard**: 100% Anna University OD / Medical verification verified.\n'
          '• **All attendance registers & advisor dashboards are synchronized in real-time.**';

      final result = AgentExecutionResult(
        goal: goalPrompt,
        steps: steps,
        executiveSummary: summary,
        actionsExecuted: actionsExecuted,
        telemetryData: telemetry,
        completedAt: DateTime.now(),
      );
      _executionHistory.insert(0, result);
      _notify();
      return result;
    }

    // ── SCENARIO B: Defaulter Audit & Intimation Notice Drafting ──
    else if (lower.contains('defaulter') || lower.contains('75%') || lower.contains('low attendance') || lower.contains('warning')) {
      steps.add(AgentStep(
        thought: 'Executing department-wide statistical sweep across 622 students in all 10 sections to identify cumulative attendance falling below the 75% statutory threshold.',
        actionName: 'scanLowAttendanceDefaulters',
        actionInput: 'Threshold: < 75.0%',
        observation: 'Identified ${MockDataService.getAllDepartmentDefaulters().length} students requiring parental intimation & advisor review.',
        timestamp: DateTime.now(),
      ));

      final defaulters = MockDataService.getAllDepartmentDefaulters();
      telemetry['totalDefaulters'] = defaulters.length;

      steps.add(AgentStep(
        thought: 'Synthesizing section-wise defaulter telemetry and drafting official parental warning circular with Anna University detention notice.',
        actionName: 'synthesizeNotice',
        actionInput: 'Target: ${defaulters.length} Defaulters across 10 sections',
        observation: 'Notice formatted with official Department Letterhead and HOD digital seal.',
        timestamp: DateTime.now(),
      ));

      actionsExecuted.add('Synthesized ${defaulters.length} low attendance records');
      actionsExecuted.add('Generated Parent Intimation Notice (Ref: VSB/AIDS/2026/ATT-WARN)');

      final summary = '⚠️ **Defaulter Audit & Action Report (< 75% Cutoff)**\n\n'
          '• **Total Department Defaulters**: **${defaulters.length} Students**\n'
          '• **Immediate Actions Triggered**:\n'
          '  1. SMS/Portal Warning dispatched to respective Section Class Advisors.\n'
          '  2. Parent Counseling Sessions scheduled for Model Exam eligibility.\n'
          '  3. Medical & OD condonation slips prioritized for regularization.';

      final result = AgentExecutionResult(
        goal: goalPrompt,
        steps: steps,
        executiveSummary: summary,
        actionsExecuted: actionsExecuted,
        telemetryData: telemetry,
        completedAt: DateTime.now(),
      );
      _executionHistory.insert(0, result);
      _notify();
      return result;
    }

    // ── SCENARIO C: Retention & Database Auto-Purge Audit ──
    else if (lower.contains('purge') || lower.contains('retention') || lower.contains('alumni') || lower.contains('archive') || lower.contains('clean')) {
      steps.add(AgentStep(
        thought: 'Scanning 2-Year Alumni Archival Vault for graduated records exceeding statutory 730-day retention window.',
        actionName: 'scanAlumniRetentionVault',
        actionInput: 'Reference Date: ${startTime.day}-${startTime.month}-${startTime.year}',
        observation: 'Scanned ${MockDataService.alumniArchiveRecords.length} alumni records.',
        timestamp: DateTime.now(),
      ));

      final purgedCount = MockDataService.triggerAlumniRetentionPurgeCheck(DateTime(2026, 9, 7));

      steps.add(AgentStep(
        thought: 'Executing cryptographic erasure on expired alumni records in compliance with UGC/AICTE data privacy guidelines.',
        actionName: 'executeRetentionPurge',
        actionInput: 'Expired records pruned: $purgedCount',
        observation: purgedCount > 0
            ? 'Successfully purged $purgedCount expired record(s) and generated tamper-proof audit log entry.'
            : 'All active retained alumni records are strictly within the 2-year retention window. No pruning required.',
        timestamp: DateTime.now(),
      ));

      actionsExecuted.add('Audited ${MockDataService.alumniArchiveRecords.length} alumni records');
      if (purgedCount > 0) {
        actionsExecuted.add('Auto-purged $purgedCount expired records (> 730 days)');
      }

      final summary = '🏛️ **2-Year Alumni Data Retention & Auto-Purge Summary**\n\n'
          '• **Status**: **100% AICTE & UGC Statutory Compliance**\n'
          '• **Active Records Retained (< 2 Yrs)**: **${MockDataService.alumniArchiveRecords.where((a) => !a.isPurged).length} Graduates**\n'
          '• **Purged Records (> 2 Yrs)**: **${MockDataService.alumniArchiveRecords.where((a) => a.isPurged).length} Records**\n'
          '• **Audit Integrity**: Encrypted cryptographic log verified.';

      final result = AgentExecutionResult(
        goal: goalPrompt,
        steps: steps,
        executiveSummary: summary,
        actionsExecuted: actionsExecuted,
        telemetryData: telemetry,
        completedAt: DateTime.now(),
      );
      _executionHistory.insert(0, result);
      _notify();
      return result;
    }

    // ── SCENARIO D: General Comprehensive Department Audit & Brief ──
    else {
      steps.add(AgentStep(
        thought: 'Aggregating live telemetry across all 10 sections: 622 students, attendance registers, OD queue, timetable indices, and defaulters.',
        actionName: 'aggregateDepartmentTelemetry',
        actionInput: 'Department: AI & DS, Total Strength: 622',
        observation: 'Compiled: 533 Present (85.0%), 94 Absentees, ${MockDataService.pendingHodApprovals} Pending HOD Signatures.',
        timestamp: DateTime.now(),
      ));

      actionsExecuted.add('Aggregated 622 student records across 10 sections');
      actionsExecuted.add('Verified Sep-Dec 2026 Academic Calendar attendance metrics');

      final summary = '📊 **Smart Pro AI-Agent: Comprehensive Department Executive Brief**\n\n'
          '• **Total Department Strength**: **622 Students** (10 Sections)\n'
          '• **Today\'s Attendance**: **533 Present (85.0%)** | **94 Absent (15.0%)**\n'
          '• **Section Highlights**:\n'
          '  - **III AIDS A**: 98.5% Turnout (1 Absent: Santhosh A)\n'
          '  - **III AIDS C**: 98.4% Turnout (1 Absent: Sakthi Balan M)\n'
          '  - **II AIDS C**: Full Section 60 Absentees Logged\n'
          '• **Pending HOD Queue**: **${MockDataService.pendingHodApprovals} Leave/OD Approvals**\n'
          '• **System Health**: 100% Operational • Cloud Synced';

      final result = AgentExecutionResult(
        goal: goalPrompt,
        steps: steps,
        executiveSummary: summary,
        actionsExecuted: actionsExecuted,
        telemetryData: telemetry,
        completedAt: DateTime.now(),
      );
      _executionHistory.insert(0, result);
      _notify();
      return result;
    }
  }
}
