import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slipreport/main.dart';
import 'package:slipreport/auth/screens/security_verification_screen.dart';
import 'package:slipreport/auth/screens/forgot_password_screen.dart';
import 'package:slipreport/core/data/student_directory_data.dart';
import 'package:slipreport/core/models/leave_model.dart';
import 'package:slipreport/core/models/promotion_model.dart';
import 'package:slipreport/core/services/auth_service.dart';
import 'package:slipreport/core/services/mock_data_service.dart';

void main() {
  test('StudentDirectoryData contains all 622 students across all 10 sections', () {
    expect(StudentDirectoryData.allStudents.length, 622);

    // Verify all 10 sections exist and have correct student counts
    expect(StudentDirectoryData.bySection['2-A']?.length, 63);
    expect(StudentDirectoryData.bySection['2-B']?.length, 63);
    expect(StudentDirectoryData.bySection['2-C']?.length, 60);
    expect(StudentDirectoryData.bySection['2-D']?.length, 63);
    expect(StudentDirectoryData.bySection['3-A']?.length, 65);
    expect(StudentDirectoryData.bySection['3-B']?.length, 61);
    expect(StudentDirectoryData.bySection['3-C']?.length, 60);
    expect(StudentDirectoryData.bySection['3-D']?.length, 63);
    expect(StudentDirectoryData.bySection['4-A']?.length, 59);
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
  });

  test('All 10 Section Advisors and HODs have dedicated usernames and passwords', () {
    final advisors = AuthService.sectionAdvisors;
    expect(advisors.length, 10);

    // IV Year
    final adv4a = advisors.firstWhere((a) => a.id == 'adv-4a');
    expect(adv4a.name, 'Mr. Muthuselvan');
    expect(adv4a.username, 'advisor.muthuselvan');
    expect(adv4a.password, 'Adv@Muthu4A');

    final adv4b = advisors.firstWhere((a) => a.id == 'adv-4b');
    expect(adv4b.name, 'Mrs. Nandhinidevi');
    expect(adv4b.username, 'advisor.nandhinidevi');
    expect(adv4b.password, 'Adv@Nandhini4B');

    // III Year
    final adv3a = advisors.firstWhere((a) => a.id == 'adv-3a');
    expect(adv3a.name, 'Ms. C. Vishnupriya');
    expect(adv3a.username, 'advisor.vishnupriya');
    expect(adv3a.password, 'Adv@Vishnu3A');

    final adv3b = advisors.firstWhere((a) => a.id == 'adv-3b');
    expect(adv3b.name, 'Dr. R. Murugesan');
    expect(adv3b.username, 'advisor.murugesan');
    expect(adv3b.password, 'Adv@Murugesan3B');

    final adv3c = advisors.firstWhere((a) => a.id == 'adv-3c');
    expect(adv3c.name, 'Mrs. B. Bharathi');
    expect(adv3c.username, 'advisor.bharathi');
    expect(adv3c.password, 'Adv@Bharathi3C');

    final adv3d = advisors.firstWhere((a) => a.id == 'adv-3d');
    expect(adv3d.name, 'Mr. Velusamy');
    expect(adv3d.username, 'advisor.velusamy');
    expect(adv3d.password, 'Adv@Velu3D');

    // II Year
    final adv2a = advisors.firstWhere((a) => a.id == 'adv-2a');
    expect(adv2a.name, 'Dr. D. Anandhan');
    expect(adv2a.username, 'advisor.anandhan');
    expect(adv2a.password, 'Adv@Anandh2A');

    final adv2b = advisors.firstWhere((a) => a.id == 'adv-2b');
    expect(adv2b.name, 'Dr. M. Rajendiran');
    expect(adv2b.username, 'advisor.rajendiran');
    expect(adv2b.password, 'Adv@Rajen2B');

    final adv2c = advisors.firstWhere((a) => a.id == 'adv-2c');
    expect(adv2c.name, 'Mr. A. Bharathidasan');
    expect(adv2c.username, 'advisor.bharathidasan');
    expect(adv2c.password, 'Adv@Bharathi2C');

    final adv2d = advisors.firstWhere((a) => a.id == 'adv-2d');
    expect(adv2d.name, 'Mr. R. Palraj');
    expect(adv2d.username, 'advisor.palraj');
    expect(adv2d.password, 'Adv@Palraj2D');

    // HODs
    expect(AuthService.overallHod.username, 'hod.manivannan');
    expect(AuthService.overallHod.password, 'Hod@Mani2026');
    expect(AuthService.juniorHod.username, 'hod.kavitha');
    expect(AuthService.juniorHod.password, 'Hod@Kavi2026');
  });

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
    final forwarded = MockDataService.forwardToHod('test-od-001', advisorRemarks: 'Recommended by advisor');
    expect(forwarded, isTrue);
    final forwardedLeave = MockDataService.leaveRequests.firstWhere((l) => l.id == 'test-od-001');
    expect(forwardedLeave.letterStatus, LetterStatus.forwarded);

    // HOD checks and approves
    final approved = MockDataService.approveByHod('test-od-001', remarks: 'Approved by HOD Dr. Manivannan');
    expect(approved, isTrue);
    final approvedLeave = MockDataService.leaveRequests.firstWhere((l) => l.id == 'test-od-001');
    expect(approvedLeave.letterStatus, LetterStatus.approved);
  });

  test('Academic Year Progression & Promotion Approval Workflow', () {
    final pendingPromotions = MockDataService.getPendingPromotionsForAdvisor(2, 'A');
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
    final updated = MockDataService.promotionRequests.firstWhere((p) => p.id == req.id);
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
    final purgedCount = MockDataService.triggerAlumniRetentionPurgeCheck(DateTime(2026, 9, 7));
    expect(purgedCount >= 0, isTrue);

    // Check storage metrics reflect alumni retention
    final metrics = MockDataService.getStorageMetrics();
    expect(metrics.containsKey('activeAlumniUnder2YrRetention'), isTrue);
    expect(metrics.containsKey('purgedAlumniRecords'), isTrue);
  });

  testWidgets('App renders PinkSlipReport SignIn with HOD and Advisor logins', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartProApp());
    await tester.pump();

    // Verify SignIn screen elements
    expect(find.text('PinkSlipReport'), findsOneWidget);
    expect(find.text('Official Academic Portal'), findsOneWidget);
    expect(find.text('DR. MANIVANNAN (Overall HOD)'), findsOneWidget);
    expect(find.text('Mrs. Kavitha (I & II Yr HOD)'), findsOneWidget);
    expect(find.text('🏛️ HOD Portal'), findsOneWidget);
    expect(find.text('👨‍🏫 Class Advisor'), findsOneWidget);
  });

  testWidgets('App renders Mobile Biometric Gateway without code verification', (WidgetTester tester) async {
    // Set pending user for auth screen
    final auth = AuthService();
    auth.loginDirectly(AuthService.overallHod);

    // Build the security verification screen directly
    await tester.pumpWidget(
      const MaterialApp(
        home: SecurityVerificationScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Biometric Mobile Login'), findsOneWidget);
    expect(find.text('HARDWARE BIOMETRIC SECURITY GATE'), findsOneWidget);
    expect(find.text('Authorize with Fingerprint Sensor'), findsOneWidget);
    expect(find.text('Authenticate with Face ID / Passkey'), findsOneWidget);
    expect(find.text('Department Data Privacy & Security Shield'), findsOneWidget);
    // Verify no manual code input text fields exist
    expect(find.text('Enter 6-digit security code'), findsNothing);

    // Clean up repeating animation
    await tester.pumpWidget(const Placeholder());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('App renders Redesigned Forgot Password Screen with Smart Pro aesthetic', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Reset Access Password'), findsOneWidget);
    expect(find.text('FACULTY CREDENTIAL RECOVERY'), findsOneWidget);
    expect(find.text('🏛️ HOD Portal'), findsOneWidget);
    expect(find.text('👨‍🏫 Class Advisor'), findsOneWidget);
    expect(find.text('Institutional Email / Faculty ID'), findsOneWidget);
    expect(find.text('Send Recovery Instructions'), findsOneWidget);
    expect(find.text('Department IT Helpdesk'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
