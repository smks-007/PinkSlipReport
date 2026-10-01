import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slipreport/core/models/student_dashboard_data.dart';
import 'package:slipreport/core/models/user_model.dart';
import 'package:slipreport/core/services/auth_service.dart';
import 'package:slipreport/dashboard/student/screens/student_dashboard_screen.dart';

const student = UserModel(
  id: 'student-a',
  name: 'Metadata name',
  email: 'old@example.com',
  role: UserRole.student,
  department: 'AI&DS',
);

StudentDashboardData summary({
  String authId = 'student-a',
  double? percentage = 75,
}) => StudentDashboardData(
  authId: authId,
  name: 'Official Student',
  email: 'student@example.com',
  rollNumber: '24243117',
  registerNumber: '922524243117',
  section: 'III-AIDS-B',
  department: 'Artificial Intelligence and Data Science',
  attendancePercentage: percentage,
);

void main() {
  setUp(() => AuthService().setMockUser(student));
  tearDown(() => AuthService().setMockUser(null));

  Future<void> open(
    WidgetTester tester,
    Future<StudentDashboardData> Function() load,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: StudentDashboardScreen(loadDashboard: load)),
    );
    await tester.pumpAndSettle();
  }

  for (final representative in [false, true]) {
    testWidgets('personal summary only; representative=$representative', (
      tester,
    ) async {
      AuthService().setMockUser(
        student.copyWith(isClassRepresentative: representative),
      );
      await open(tester, () async => summary());
      expect(find.text('75.0%'), findsOneWidget);
      expect(find.text('Official Student'), findsOneWidget);
      expect(find.text('student@example.com'), findsOneWidget);
      expect(find.text('24243117'), findsOneWidget);
      expect(find.text('922524243117'), findsOneWidget);
      expect(find.text('III-AIDS-B'), findsOneWidget);
      expect(find.text('Metadata name'), findsNothing);
      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.textContaining('Submit'), findsNothing);
      expect(find.textContaining('Roster'), findsNothing);
      expect(find.textContaining('Leaves'), findsNothing);
      expect(find.textContaining('Pink Slip'), findsNothing);
    });
  }

  testWidgets('missing attendance is unavailable, not an invented percentage', (
    tester,
  ) async {
    await open(tester, () async => summary(percentage: null));
    expect(find.text('Not available'), findsOneWidget);
    expect(find.text('100.0%'), findsNothing);
    expect(find.text('0.0%'), findsNothing);
  });

  testWidgets('denies a different student response', (tester) async {
    await open(tester, () async => summary(authId: 'student-b'));
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Official Student'), findsNothing);
  });

  testWidgets('failed load retries without falling back to class data', (
    tester,
  ) async {
    var attempts = 0;
    await open(tester, () async {
      if (++attempts == 1) throw StateError('offline');
      return summary();
    });
    expect(find.text('75.0%'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('75.0%'), findsOneWidget);
  });

  testWidgets('sign-out clears displayed details', (tester) async {
    await open(tester, () async => summary());
    AuthService().setMockUser(null);
    await tester.pumpAndSettle();
    expect(find.text('Official Student'), findsNothing);
    expect(
      find.text('Please sign in with your student account.'),
      findsOneWidget,
    );
  });

  testWidgets('late response after sign-out is never shown', (tester) async {
    final pending = Completer<StudentDashboardData>();
    await tester.pumpWidget(
      MaterialApp(
        home: StudentDashboardScreen(loadDashboard: () => pending.future),
      ),
    );
    await tester.pump();
    AuthService().setMockUser(null);
    pending.complete(summary());
    await tester.pumpAndSettle();
    expect(find.text('Official Student'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-out or faculty accounts never fetch student data', (
    tester,
  ) async {
    var calls = 0;
    for (final user in [null, AuthService.overallHod]) {
      AuthService().setMockUser(user);
      await open(tester, () async {
        calls++;
        return summary();
      });
      expect(find.text('Official Student'), findsNothing);
    }
    expect(calls, 0);
  });

  testWidgets('personal summary fits a compact screen and enlarged text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, () async => summary());
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
