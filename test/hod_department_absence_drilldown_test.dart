import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slipreport/core/models/department_absence.dart';
import 'package:slipreport/core/services/auth_service.dart';
import 'package:slipreport/core/services/data_service.dart';
import 'package:slipreport/dashboard/hod/screens/hod_dashboard_screen.dart';

final report = DepartmentAbsenceReport(
  recordedCount: 20,
  absences: const [
    DepartmentAbsence(
      studentId: 1,
      name: 'Arun Kumar',
      rollNumber: '24243117',
      registerNumber: '922524243117',
      section: 'III-AIDS-B',
    ),
    DepartmentAbsence(
      studentId: 2,
      name: 'Bala Devi',
      rollNumber: '25243001',
      registerNumber: '922525243001',
      section: 'II-AIDS-A',
    ),
  ],
);

String trendKey(DateTime date) =>
    'department_trend_${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime selectableTrendDate() =>
    MockDataService.getOverallDepartmentWeeklyTrend().lastWhere(
          (item) => item['isHoliday'] != true,
        )['date']
        as DateTime;

void main() {
  setUp(() => AuthService().setMockUser(AuthService.overallHod));
  tearDown(() => AuthService().setMockUser(null));

  Future<void> open(
    WidgetTester tester,
    Future<DepartmentAbsenceReport> Function(DateTime) loader,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(
      MaterialApp(
        home: HodDashboardScreen(
          key: UniqueKey(),
          loadDepartmentAbsences: loader,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Dept'));
    await tester.pumpAndSettle();
  }

  testWidgets('selected department bar opens the exact day absence list', (
    tester,
  ) async {
    DateTime? selectedDate;
    await open(tester, (date) async {
      selectedDate = date;
      return report;
    });
    final date = selectableTrendDate();
    await tester.tap(find.byKey(ValueKey(trendKey(date))));
    await tester.pumpAndSettle();

    expect(selectedDate, DateTime(date.year, date.month, date.day));
    expect(find.text('Department absences'), findsOneWidget);
    expect(find.text('2 absent students'), findsOneWidget);
    expect(find.text('Arun Kumar'), findsOneWidget);
    expect(find.text('Bala Devi'), findsOneWidget);
    expect(find.text('24243117 • 922524243117'), findsOneWidget);
  });

  testWidgets('absence panel filters by section and student details', (
    tester,
  ) async {
    await open(tester, (_) async => report);
    final date = selectableTrendDate();
    await tester.tap(find.byKey(ValueKey(trendKey(date))));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'III-AIDS-B'));
    await tester.pumpAndSettle();
    expect(find.text('Arun Kumar'), findsOneWidget);
    expect(find.text('Bala Devi'), findsNothing);
    await tester.enterText(find.byType(TextField), '24243117');
    await tester.pumpAndSettle();
    expect(find.text('Arun Kumar'), findsOneWidget);
  });

  testWidgets('section graph opens only the selected section absence list', (
    tester,
  ) async {
    DateTime? selectedDate;
    String? selectedSection;
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(
      MaterialApp(
        home: HodDashboardScreen(
          key: UniqueKey(),
          loadSectionAbsences: (date, sectionId) async {
            selectedDate = date;
            selectedSection = sectionId;
            return report;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final date = selectableTrendDate();
    await tester.tap(find.byKey(ValueKey(trendKey(date))));
    await tester.pumpAndSettle();

    expect(selectedDate, DateTime(date.year, date.month, date.day));
    expect(selectedSection, 'II-AIDS-A');
    expect(find.text('II-AIDS-A absences'), findsOneWidget);
  });

  testWidgets('days with no absence or no records have distinct messages', (
    tester,
  ) async {
    await open(
      tester,
      (_) async =>
          const DepartmentAbsenceReport(recordedCount: 12, absences: []),
    );
    final date = selectableTrendDate();
    await tester.tap(find.byKey(ValueKey(trendKey(date))));
    await tester.pumpAndSettle();
    expect(find.text('No absences recorded for this day.'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await open(
      tester,
      (_) async =>
          const DepartmentAbsenceReport(recordedCount: 0, absences: []),
    );
    await tester.tap(find.byKey(ValueKey(trendKey(date))));
    await tester.pumpAndSettle();
    expect(
      find.text('Attendance has not been recorded for this day.'),
      findsOneWidget,
    );
  });
}
