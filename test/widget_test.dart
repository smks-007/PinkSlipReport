import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slipreport/main.dart';
import 'package:slipreport/auth/screens/security_verification_screen.dart';
import 'package:slipreport/auth/screens/forgot_password_screen.dart';
import 'package:slipreport/core/data/student_directory_data.dart';
import 'package:slipreport/core/models/student_model.dart';
import 'package:slipreport/core/models/leave_model.dart';
import 'package:slipreport/core/models/promotion_model.dart';
import 'package:slipreport/core/services/auth_service.dart';
import 'package:slipreport/core/services/mock_data_service.dart';
import 'package:slipreport/chatbot/widgets/jarvis_fab.dart';
import 'package:slipreport/dashboard/shared/widgets/role_ai_agent_sheet.dart';
import 'package:slipreport/dashboard/student/screens/student_dashboard_screen.dart';
import 'package:slipreport/dashboard/advisor/screens/advisor_dashboard_screen.dart';
import 'package:slipreport/dashboard/hod/screens/hod_dashboard_screen.dart';
import 'package:slipreport/core/services/ai_agent_service.dart';

void main() {
  test('StudentDirectoryData contains all students across all 10 sections', () {
    expect(StudentDirectoryData.allStudents.length, 627);

    // Verify all 10 sections exist and have correct student counts
    expect(StudentDirectoryData.bySection['2-A']?.length, 63);
    expect(StudentDirectoryData.bySection['2-B']?.length, 63);
    expect(StudentDirectoryData.bySection['2-C']?.length, 60);
    expect(StudentDirectoryData.bySection['2-D']?.length, 66);
    expect(StudentDirectoryData.bySection['3-A']?.length, 65);
    expect(StudentDirectoryData.bySection['3-B']?.length, 61);
    expect(StudentDirectoryData.bySection['3-C']?.length, 61);
    expect(StudentDirectoryData.bySection['3-D']?.length, 63);
    expect(StudentDirectoryData.bySection['4-A']?.length, 60);
    expect(StudentDirectoryData.bySection['4-B']?.length, 65);

    // Verify key students across years
    final s1 = StudentDirectoryData.byRollNumber['25243001'];
    expect(s1?.name, 'ABINAYA G');
    expect(s1?.batchYear, '2025 BATCH');
    expect(s1?.section, 'A');

    final s2 = StudentDirectoryData.byRollNumber['25243100'];
    expect(s2?.name, 'LITHESH HARI R');
    expect(s2?.batchYear, '2025 BATCH');
    expect(s2?.section, 'B');

    final s3 = StudentDirectoryData.byRollNumber['24243007'];
    expect(s3?.name, 'AKASH I');
    expect(s3?.batchYear, '2024 BATCH');
    expect(s3?.section, 'A');

    final s4 = StudentDirectoryData.byRollNumber['23243034'];
    expect(s4?.name, 'S. HARINI');
    expect(s4?.batchYear, '2023 BATCH');
    expect(s4?.section, 'B');
    // Verify today's attendance metrics
    expect(MockDataService.presentToday, 533);
    expect(MockDataService.absentToday, 94);
    expect(MockDataService.todaysAbsentRollNumbers.length, 94);
  });

  test('AuthService has exactly 20 Class Representatives (1 Boy & 1 Girl for each of 10 sections)', () {
    expect(AuthService.classRepresentatives.length, 20);

    for (int yr in [2, 3, 4]) {
      final sections = (yr == 4) ? ['A', 'B'] : ['A', 'B', 'C', 'D'];
      for (final sec in sections) {
        final crs = AuthService.classRepresentatives
            .where((c) => c.year == yr && c.section == sec)
            .toList();
        expect(crs.length, 2, reason: 'Expected 2 CRs for Year $yr Sec $sec');
        expect(crs.any((c) => c.gender == 'Boy'), isTrue);
        expect(crs.any((c) => c.gender == 'Girl'), isTrue);
      }
    }
  });

  test('Leave & On-Duty File Attachment and Multi-Tier Approval Workflow', () {
    final initialCount = MockDataService.leaveRequests.length;

    // Student/CR submits a new OD request with file attachment
    final newOd = LeaveModel(
      id: 'test-od-001',
      studentId: 'stu_098',
      studentName: 'LITHEH HARI R',
      studentRollNumber: '25243100',
      category: LeaveCategory.onDuty,
      section: 'B',
      year: 2,
      batchYear: '2025 BATCH',
      leaveDate: DateTime.now(),
      leaveType: LeaveType.informed,
      reason: 'IEEE AI Conference Presentation',
      letterSubmitted: true,
      letterStatus: LetterStatus.submitted,
      attachmentFileName: 'ieee_conference_invitation.pdf',
      attachmentFileType: 'Conference Invitation',
      attachmentFileSize: '1.5 MB',
    );

    MockDataService.submitLeaveRequest(newOd);
    expect(MockDataService.leaveRequests.length, initialCount + 1);
    expect(MockDataService.leaveRequests.first.hasAttachment, isTrue);

    // Class Advisor reviews and forwards to HOD
    final forwarded = MockDataService.forwardToHod(
      'test-od-001',
      advisorRemarks: 'Recommended by advisor',
    );
    expect(forwarded, isTrue);

    final forwardedLeave = MockDataService.leaveRequests.firstWhere(
      (l) => l.id == 'test-od-001',
    );
    expect(forwardedLeave.letterStatus, LetterStatus.forwarded);

    // HOD checks and approves
    final approved = MockDataService.approveByHod(
      'test-od-001',
      remarks: 'Approved by HOD Dr. Manivannan',
    );
    expect(approved, isTrue);

    final approvedLeave = MockDataService.leaveRequests.firstWhere(
      (l) => l.id == 'test-od-001',
    );
    expect(approvedLeave.letterStatus, LetterStatus.approved);
  });

  testWidgets(
    'App renders PinkSlipReport SignIn with secure credential inputs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const SmartProApp());
      await tester.pump();

      // Verify SignIn screen elements
      expect(find.text('PinkSlipReport'), findsOneWidget);
      expect(
        find.text('V.S.B. Engineering College • Dept of AI & DS'),
        findsOneWidget,
      );
      expect(find.text('Official Academic Portal'), findsOneWidget);
      expect(
        find.text('Official Username, Email, or Roll Number'),
        findsOneWidget,
      );
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    },
  );

  test(
    'All 10 Section Advisors and HODs have dedicated usernames and emails',
    () {
      final advisors = AuthService.sectionAdvisors;
      expect(advisors.length, 10);

      // IV Year
      final adv4a = advisors.firstWhere((a) => a.id == 'adv-4a');
      expect(adv4a.name, 'Mr. Muthuselvan');
      expect(adv4a.username, 'advisor.muthuselvan');
      expect(adv4a.email, 'advisor.4a@vsb.ac.in');

      final adv4b = advisors.firstWhere((a) => a.id == 'adv-4b');
      expect(adv4b.name, 'Mrs. Nandhinidevi');
      expect(adv4b.username, 'advisor.nandhinidevi');
      expect(adv4b.email, 'advisor.4b@vsb.ac.in');

      // III Year
      final adv3a = advisors.firstWhere((a) => a.id == 'adv-3a');
      expect(adv3a.name, 'Ms. C. Vishnupriya');
      expect(adv3a.username, 'advisor.vishnupriya');
      expect(adv3a.email, 'advisor.3a@vsb.ac.in');

      final adv3b = advisors.firstWhere((a) => a.id == 'adv-3b');
      expect(adv3b.name, 'Dr. R. Murugesan');
      expect(adv3b.username, 'advisor.murugesan');
      expect(adv3b.email, 'advisor.3b@vsb.ac.in');

      final adv3c = advisors.firstWhere((a) => a.id == 'adv-3c');
      expect(adv3c.name, 'Mrs. B. Bharathi');
      expect(adv3c.username, 'advisor.bharathi');
      expect(adv3c.email, 'advisor.3c@vsb.ac.in');

      final adv3d = advisors.firstWhere((a) => a.id == 'adv-3d');
      expect(adv3d.name, 'Mr. Velusamy');
      expect(adv3d.username, 'advisor.velusamy');
      expect(adv3d.email, 'advisor.3d@vsb.ac.in');

      // II Year
      final adv2a = advisors.firstWhere((a) => a.id == 'adv-2a');
      expect(adv2a.name, 'Dr. D. Anandhan');
      expect(adv2a.username, 'advisor.anandhan');
      expect(adv2a.email, 'advisor.2a@vsb.ac.in');

      final adv2b = advisors.firstWhere((a) => a.id == 'adv-2b');
      expect(adv2b.name, 'Dr. M. Rajendiran');
      expect(adv2b.username, 'advisor.rajendiran');
      expect(adv2b.email, 'advisor.2b@vsb.ac.in');

      final adv2c = advisors.firstWhere((a) => a.id == 'adv-2c');
      expect(adv2c.name, 'Mr. A. Bharathidasan');
      expect(adv2c.username, 'advisor.bharathidasan');
      expect(adv2c.email, 'advisor.2c@vsb.ac.in');

      final adv2d = advisors.firstWhere((a) => a.id == 'adv-2d');
      expect(adv2d.name, 'Mr. R. Palraj');
      expect(adv2d.username, 'advisor.palraj');
      expect(adv2d.email, 'advisor.2d@vsb.ac.in');

      // HODs
      expect(AuthService.overallHod.username, 'hod.manivannan');
      expect(AuthService.overallHod.email, 'manivannan.hod@vsb.ac.in');
      expect(AuthService.juniorHod.username, 'hod.kavitha');
      expect(AuthService.juniorHod.email, 'kavitha.hod@vsb.ac.in');
    },
  );

  test('Leave & On-Duty File Attachment and Multi-Tier Approval Workflow', () {
    final initialCount = MockDataService.leaveRequests.length;

    // Submit new OD request
    final newOd = LeaveModel(
      id: 'test-od-001',
      studentId: 'stu_098',
      studentName: 'LITHESH HARI R',
      studentRollNumber: '25243100',
      category: LeaveCategory.onDuty,
      section: 'B',
      year: 2,
      batchYear: '2025 BATCH',
      leaveDate: DateTime(2026, 9, 7),
      leaveType: LeaveType.informed,
      reason: 'IEEE AI Conference Presentation',
      letterSubmitted: true,
      letterStatus: LetterStatus.submitted,
      attachmentFileName: 'ieee_conference_invitation.pdf',
      attachmentFileType: 'Conference Invitation',
      attachmentFileSize: '1.5 MB',
    );

    MockDataService.submitLeaveRequest(newOd);
    expect(MockDataService.leaveRequests.length, initialCount + 1);
    expect(MockDataService.leaveRequests.first.hasAttachment, isTrue);

    // Class Advisor reviews and forwards to HOD
    final forwarded = MockDataService.forwardToHod(
      'test-od-001',
      advisorRemarks: 'Recommended by advisor',
    );
    expect(forwarded, isTrue);
    final forwardedLeave = MockDataService.leaveRequests.firstWhere(
      (l) => l.id == 'test-od-001',
    );
    expect(forwardedLeave.letterStatus, LetterStatus.forwarded);

    // HOD checks and approves
    final approved = MockDataService.approveByHod(
      'test-od-001',
      remarks: 'Approved by HOD Dr. Manivannan',
    );
    expect(approved, isTrue);
    final approvedLeave = MockDataService.leaveRequests.firstWhere(
      (l) => l.id == 'test-od-001',
    );
    expect(approvedLeave.letterStatus, LetterStatus.approved);
  });

  test('Academic Year Progression & Promotion Approval Workflow', () {
    final pendingPromotions = MockDataService.getPendingPromotionsForAdvisor(
      2,
      'A',
    );
    expect(pendingPromotions.isNotEmpty, isTrue);

    final req = pendingPromotions.first;
    expect(req.fromYear, 2);
    expect(req.toYear, 3);
    expect(req.semesterCompleted, 4);
    expect(req.graceTransitionDays >= 7, isTrue);

    // Advisor forwards promotion
    final forwarded = MockDataService.advisorForwardPromotion(
      req.id,
      advisorName: 'Dr. D. Anandhan',
      remarks: 'All 62 students cleared 4th Sem practicals and minimum attendance criteria.',
    );
    expect(forwarded, isTrue);

    // HOD approves promotion
    final approved = MockDataService.hodApprovePromotion(
      req.id,
      hodName: 'Dr. Manivannan',
      remarks: 'Approved by HOD. Batch successfully promoted to III Year.',
    );
    expect(approved, isTrue);

    // Verify updated promotion status
    final updated = MockDataService.promotionRequests.firstWhere(
      (p) => p.id == req.id,
    );
    expect(updated.status, equals(PromotionApprovalStatus.approvedByHod));
  });

  test('2-Year Alumni Data Retention Policy & Automated Purge Engine', () {
    final archives = MockDataService.alumniArchiveRecords;
    expect(archives.isNotEmpty, isTrue);

    // Active records within 2-year retention window
    final active = archives.where((a) => !a.isPurged).toList();
    expect(active.isNotEmpty, isTrue);

    // Check expiry logic relative to active reference date
    final rec2024 = archives.firstWhere((a) => a.batchYear == '2024 BATCH');
    expect(rec2024.isExpired(DateTime(2026, 9, 7)), isTrue);
    expect(rec2024.isPurged, isTrue);

    // Run automated purge check
    final purgedCount = MockDataService.triggerAlumniRetentionPurgeCheck(
      DateTime(2026, 9, 7),
    );
    expect(purgedCount >= 0, isTrue);

    // Check storage metrics reflect alumni retention
    final metrics = MockDataService.getStorageMetrics();
    expect(metrics.containsKey('activeAlumniUnder2YrRetention'), isTrue);
    expect(metrics.containsKey('purgedAlumniRecords'), isTrue);
  });

  testWidgets(
    'App renders PinkSlipReport SignIn with encrypted security badge',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SmartProApp());
      await tester.pump();

      // Verify SignIn screen elements
      expect(find.text('PinkSlipReport'), findsOneWidget);
      expect(find.text('Official Academic Portal'), findsOneWidget);
      expect(
        find.text('Official Username, Email, or Roll Number'),
        findsOneWidget,
      );
      expect(find.text('Sign In'), findsOneWidget);
      expect(
        find.text('Secured by Supabase Auth • AES-256 Encrypted'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'App renders Mobile Biometric Gateway without code verification',
    (WidgetTester tester) async {
      // Set pending user for auth screen
      final auth = AuthService();
      auth.loginDirectly(AuthService.overallHod);

      // Build the security verification screen directly
      await tester.pumpWidget(
        const MaterialApp(home: SecurityVerificationScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Biometric Mobile Login'), findsOneWidget);
      expect(find.text('HARDWARE BIOMETRIC SECURITY GATE'), findsOneWidget);
      expect(find.text('Authorize with Fingerprint Sensor'), findsOneWidget);
      expect(find.text('Authenticate with Face ID / Passkey'), findsOneWidget);
      expect(
        find.text('Department Data Privacy & Security Shield'),
        findsOneWidget,
      );
      // Verify no manual code input text fields exist
      expect(find.text('Enter 6-digit security code'), findsNothing);

      // Clean up repeating animation
      await tester.pumpWidget(const Placeholder());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'App renders Redesigned Forgot Password Screen with Smart Pro aesthetic',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));
      await tester.pump();

      expect(find.text('Reset Access Password'), findsOneWidget);
      expect(find.text('FACULTY CREDENTIAL RECOVERY'), findsOneWidget);
      expect(find.text('🏛️ HOD Portal'), findsOneWidget);
      expect(find.text('👨‍🏫 Class Advisor'), findsOneWidget);
      expect(find.text('Institutional Email / Faculty ID'), findsOneWidget);
      expect(find.text('Send Recovery Instructions'), findsOneWidget);
      expect(find.text('Department IT Helpdesk'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    },
  );

  test('AiAgentService autonomous reasoning, student deep lookup, and pink slip issuance', () async {
    final aiAgent = AiAgentService();

    // 1. Deep student profile retrieval
    final profile = aiAgent.getStudentDeepProfile('25243001');
    expect(profile, isNotNull);
    final student = profile!['student'] as StudentModel;
    expect(student.name, 'ABINAYA G');
    expect(profile['isPresentToday'], isTrue);
    expect(profile['advisorName'], 'Dr. D. Anandhan');
    expect(profile['cumulativePercentage'], isNotNull);

    // 2. Directory search by query
    final found = aiAgent.findStudent('ARUL DEEPIKA');
    expect(found, isNotNull);
    expect(found?.rollNumber, '25243011');

    // 3. Pink slip issuance
    final slip = aiAgent.issuePinkSlip(
      rollNumber: '25243001',
      reason: 'Smart India Hackathon Finalist Round',
      date: DateTime(2026, 9, 7),
      issuedBy: 'Dr. K. Manivannan',
      category: LeaveCategory.onDuty,
    );
    expect(slip.studentRollNumber, '25243001');
    expect(slip.letterStatus, LetterStatus.approved);
    expect(slip.category, LeaveCategory.onDuty);

    // 4. Autonomous AI Agent Goal Execution
    final result = await aiAgent.executeAutonomousGoal(
      'Run a defaulter notification sweep across all 10 sections',
    );
    expect(result.steps.isNotEmpty, isTrue);
    expect(result.steps.every((s) => s.isSuccess), isTrue);
    expect(result.executiveSummary.contains('Defaulter Audit'), isTrue);
  });

  test('HOD Pink Slip Central and student attendance verification', () {
    // 533 Present vs 94 Absent checks
    expect(MockDataService.isStudentPresent('25243001'), isTrue); // Present
    expect(
      MockDataService.isStudentAbsent('25243006'),
      isTrue,
    ); // Absent (Akhil M)
    expect(MockDataService.isStudentPresent('25243006'), isFalse);

    // HOD single and batch approval
    final initialPending = MockDataService.leaveRequests
        .where(
          (l) =>
              l.letterStatus == LetterStatus.forwarded ||
              l.letterStatus == LetterStatus.submitted,
        )
        .length;
    expect(initialPending >= 0, isTrue);

    final req = MockDataService.leaveRequests.first;
    MockDataService.approveByHod(req.id, remarks: 'Verified by HOD');
    final updatedReq = MockDataService.leaveRequests.firstWhere(
      (l) => l.id == req.id,
    );
    expect(updatedReq.letterStatus, LetterStatus.approved);
    expect(updatedReq.hodRemarks, 'Verified by HOD');
  });

  test('Student AI-Agent autonomous reasoning: forecast, safe leaves, and auto-draft', () async {
    final aiAgent = AiAgentService();
    final studentUser =
        AuthService.classRepresentatives[2]; // Lithesh Hari R (25243100)

    // 1. Attendance forecast tool
    final forecast = aiAgent.calculateAttendanceForecast(
      rollNumber: '25243100',
    );
    expect(forecast.containsKey('currentPercentage'), isTrue);
    expect(forecast.containsKey('safeLeavesAllowed'), isTrue);
    expect(forecast.containsKey('classesNeededFor75'), isTrue);
    expect(forecast['totalTermDays'], 90);

    // 2. Student attendance forecast goal
    final resForecast = await aiAgent.executeAutonomousGoal(
      'Forecast my attendance and check safe leaves allowed',
      user: studentUser,
    );
    expect(resForecast.steps.isNotEmpty, isTrue);
    expect(
      resForecast.executiveSummary.contains('Attendance Diagnostic'),
      isTrue,
    );

    // 3. Student auto-draft OD goal
    final resDraft = await aiAgent.executeAutonomousGoal(
      'Draft and submit an On-Duty OD application for SIH Hackathon',
      user: studentUser,
    );
    expect(resDraft.steps.isNotEmpty, isTrue);
    expect(
      resDraft.actionsExecuted.any((a) => a.contains('Auto-drafted')),
      isTrue,
    );
  });

  test('Class Advisor AI-Agent autonomous reasoning: batch forward ODs, defaulters audit, and section brief', () async {
    final aiAgent = AiAgentService();
    final advisorUser =
        AuthService.sectionAdvisors.first; // Dr. D. Anandhan (II-A)

    // 1. Batch forward ODs goal
    final resForward = await aiAgent.executeAutonomousGoal(
      'Batch forward all submitted OD requests in my section to HOD',
      user: advisorUser,
    );
    expect(resForward.steps.isNotEmpty, isTrue);
    expect(
      resForward.executiveSummary.contains('Batch Verification & Forwarding'),
      isTrue,
    );

    // 2. Section defaulter audit goal
    final resDefaulters = await aiAgent.executeAutonomousGoal(
      'Scan my section for defaulters less than 75%',
      user: advisorUser,
    );
    expect(resDefaulters.steps.isNotEmpty, isTrue);
    expect(
      resDefaulters.executiveSummary.contains('Section Defaulter Audit'),
      isTrue,
    );

    // 3. Section daily turnout brief goal
    final resBrief = await aiAgent.executeAutonomousGoal(
      'Compile section daily turnout and absentees brief',
      user: advisorUser,
    );
    expect(resBrief.steps.isNotEmpty, isTrue);
    expect(
      resBrief.executiveSummary.contains('Daily Section Telemetry Brief'),
      isTrue,
    );
  });

  testWidgets(
    'RoleAiAgentSheet renders correctly for Student and Advisor roles',
    (WidgetTester tester) async {
      final studentUser = AuthService.classRepresentatives[2];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoleAiAgentSheet(user: studentUser)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student AI-Agent Co-Pilot'), findsOneWidget);
      expect(find.text('75% Attendance Forecast'), findsOneWidget);
      expect(find.text('Auto-Draft OD Application'), findsOneWidget);

      final advisorUser = AuthService.sectionAdvisors.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoleAiAgentSheet(user: advisorUser)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Advisor AI-Agent Co-Pilot'), findsOneWidget);
      expect(find.text('Batch Forward ODs to HOD'), findsOneWidget);
      expect(find.text('Section Defaulter Audit'), findsOneWidget);
    },
  );

  testWidgets(
    'Jarvis FAB is restricted to HOD and opens dual-tab Chatbot & AI-Agent interface',
    (WidgetTester tester) async {
      // Log in as HOD
      AuthService().loginDirectly(AuthService.overallHod);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(floatingActionButton: JarvisFAB())),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI-Agent Co-Pilot'), findsOneWidget);

      // Tap FAB to open Jarvis drawer
      await tester.tap(find.byType(JarvisFAB));
      await tester.pumpAndSettle();

      expect(find.text('Smart Pro AI Intelligence'), findsOneWidget);
      expect(find.text('Jarvis Chatbot'), findsOneWidget);
      expect(find.text('⚡ Autonomous AI-Agent'), findsOneWidget);
    },
  );

  testWidgets(
    'Student Dashboard renders cleanly with Submit Leave FAB and NO AI-Agent or Chatbot',
    (WidgetTester tester) async {
      // Log in as student
      AuthService().loginDirectly(AuthService.classRepresentatives[2]);

      await tester.pumpWidget(
        const MaterialApp(home: StudentDashboardScreen()),
      );
      await tester.pumpAndSettle();

      // Verify student actions
      expect(find.text('Submit Leave / OD'), findsOneWidget);
      expect(find.text('Class Roster (63)'), findsOneWidget);

      // Verify AI-Agent and Chatbot are completely absent from student dashboard
      expect(find.text('⚡ Launch AI-Agent Co-Pilot'), findsNothing);
      expect(find.byType(JarvisFAB), findsNothing);
      expect(find.text('Jarvis Chatbot'), findsNothing);
      expect(find.text('AI-Agent Co-Pilot'), findsNothing);
    },
  );

  testWidgets(
    'Advisor Dashboard Pink Slip Forwarder, Proof Scanner, and Multi-Section Review Workflow',
    (WidgetTester tester) async {
      // Log in as Advisor Dr. Anandhan (II-A)
      final advisorUser = AuthService.sectionAdvisors.first;
      AuthService().loginDirectly(advisorUser);

      // Test advisor rejection and forward helper methods
      final leave = MockDataService.leaveRequests.first;
      final rejectSuccess = MockDataService.rejectByAdvisor(
        leave.id,
        remarks: 'Incomplete medical prescription attached.',
      );
      expect(rejectSuccess, isTrue);

      final rejectedLeave = MockDataService.leaveRequests.firstWhere(
        (l) => l.id == leave.id,
      );
      expect(rejectedLeave.letterStatus, equals(LetterStatus.rejected));
      expect(
        rejectedLeave.advisorRemarks,
        contains('Incomplete medical prescription attached.'),
      );

      // Test attendance helper methods
      expect(MockDataService.isStudentPresent('25243001'), isTrue);
      expect(MockDataService.isStudentAbsent('25243006'), isTrue);

      // Build Advisor Dashboard Screen
      await tester.pumpWidget(
        const MaterialApp(home: AdvisorDashboardScreen()),
      );
      await tester.pumpAndSettle();

      // Verify Quick Actions Pink Slip Banner
      expect(
        find.text('🎫 Forward Absentee / Issue Pink Slip'),
        findsOneWidget,
      );
      expect(find.text('Pink Slip'), findsWidgets);
      expect(find.text('Pink Slip & OD Management'), findsOneWidget);
      expect(find.text('My Class (Yr 2-A)'), findsOneWidget);
      expect(find.text('All 10 Sections (627)'), findsOneWidget);

      // Verify Class Roster section
      expect(find.textContaining('Class Roster (Yr 2-A)'), findsOneWidget);
    },
  );

  testWidgets(
    'HOD Executive Segmented Dashboard, Quick Actions Bar, and Tab Switching Workflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Log in as Overall HOD
      AuthService().loginDirectly(AuthService.overallHod);

      await tester.pumpWidget(const MaterialApp(home: HodDashboardScreen()));
      await tester.pumpAndSettle();

      // Verify Executive Summary Banner
      expect(find.text('Total Enrolled'), findsOneWidget);
      expect(find.text('Present Today'), findsOneWidget);
      expect(find.text('Absentees'), findsOneWidget);
      expect(find.text('Pending Slips'), findsOneWidget);

      // Verify Executive Segmented Navigation Tabs
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Sections'), findsOneWidget);
      expect(find.text('Approvals'), findsOneWidget);
      expect(find.text('Promotion'), findsOneWidget);

      // Verify Tab 0: Quick Actions Bar
      expect(find.text('⚡ Executive Quick Actions'), findsOneWidget);
      expect(find.text('Issue Pink Slip'), findsOneWidget);
      expect(find.text('Broadcast Notice'), findsOneWidget);
      expect(find.text('Parent Intimation'), findsNothing);
      expect(find.text('Daily Muster Roll'), findsNothing);

      // Switch to Tab 1: Sections
      await tester.tap(find.byKey(const ValueKey('hod_tab_1')));
      await tester.pumpAndSettle();
      expect(
        find.text('Browse All 10 Sections (627 Students)'),
        findsOneWidget,
      );

      // Switch to Tab 2: Approvals
      await tester.tap(find.byKey(const ValueKey('hod_tab_2')));
      await tester.pumpAndSettle();
      expect(find.text('Pink Slip & Digital Approval Central'), findsOneWidget);

      // Switch to Tab 3: Promotion
      await tester.tap(find.byKey(const ValueKey('hod_tab_3')));
      await tester.pumpAndSettle();
      expect(
        find.text('Academic Year Progression & Promotion Queue'),
        findsOneWidget,
      );
      expect(
        find.text('Alumni Data Retention & Auto-Purge Manager'),
        findsOneWidget,
      );
    },
  );

  test('Class Advisor creates Pink Slip and synchronizes attendance (Mark Present & Absent)', () {
    final student = StudentDirectoryData.allStudents.firstWhere(
      (s) => s.rollNumber == '25243100',
    );
    final testDate = DateTime(2026, 9, 5);

    // 1. Advisor creates a Pink Slip marking student ABSENT
    final absentSlip = MockDataService.createAdvisorPinkSlip(
      student: student,
      date: testDate,
      markPresent: false,
      category: LeaveCategory.leave,
      reason: 'Medical Leave - Viral Fever',
      advisorName: 'Dr. M. Rajendiran',
      advisorId: 'adv-2b',
      year: 2,
      section: 'B',
    );

    expect(absentSlip.studentRollNumber, '25243100');
    expect(absentSlip.letterStatus, LetterStatus.forwarded);
    expect(MockDataService.leaveRequests.first.id, absentSlip.id);

    // Verify Attendance record updated to Absent
    final recordsAbsent = MockDataService.getAttendanceForDate(
      testDate,
      year: 2,
      section: 'B',
    );
    final studentRecordAbsent = recordsAbsent.firstWhere(
      (r) => r.studentId == student.id,
    );
    expect(studentRecordAbsent.isPresent, isFalse);
    expect(studentRecordAbsent.source, 'pink_slip_absent');

    // 2. Advisor creates a Pink Slip marking student PRESENT (On-Duty Clearance)
    final presentSlip = MockDataService.createAdvisorPinkSlip(
      student: student,
      date: testDate,
      markPresent: true,
      category: LeaveCategory.onDuty,
      reason: 'On-Duty: Anna University Symposium Clearance',
      advisorName: 'Dr. M. Rajendiran',
      advisorId: 'adv-2b',
      year: 2,
      section: 'B',
    );

    expect(presentSlip.category, LeaveCategory.onDuty);
    expect(presentSlip.letterStatus, LetterStatus.approved);

    // Verify Attendance record updated to Present
    final recordsPresent = MockDataService.getAttendanceForDate(
      testDate,
      year: 2,
      section: 'B',
    );
    final studentRecordPresent = recordsPresent.firstWhere(
      (r) => r.studentId == student.id,
    );
    expect(studentRecordPresent.isPresent, isTrue);
    expect(studentRecordPresent.source, 'pink_slip_od');
  });
}
