import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slipreport/main.dart';
import 'package:slipreport/core/data/student_directory_data.dart';
import 'package:slipreport/core/models/leave_model.dart';
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

  testWidgets('App renders PinkSlipReport SignIn with HOD and CR demo logins', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify SignIn screen elements
    expect(find.text('PinkSlipReport'), findsOneWidget);
    expect(find.text('V.S.B. Engineering College • Dept of AI & DS'), findsOneWidget);
    expect(find.text('DR. MANIVANNAN (Overall HOD)'), findsOneWidget);
    expect(find.text('Mrs. Kavitha (I & II Yr HOD)'), findsOneWidget);
    expect(find.text('🏛️ HOD Portal'), findsOneWidget);
    expect(find.text('👨‍🏫 Class Advisor'), findsOneWidget);
    expect(find.text('🎓 Student / CR'), findsOneWidget);
  });
}
