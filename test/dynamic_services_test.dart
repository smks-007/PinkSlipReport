import 'package:flutter_test/flutter_test.dart';
import 'package:slipreport/core/services/data_service.dart';
import 'package:slipreport/core/services/ai_agent_service.dart';
import 'package:slipreport/core/services/timetable_data_service.dart';
import 'package:slipreport/core/data/student_directory_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Services & Data Resilience Tests', () {
    test('MockDataService.getDepartmentOnDuty returns valid non-negative integer', () {
      final odCount = MockDataService.getDepartmentOnDuty();
      expect(odCount, greaterThanOrEqualTo(0));
      expect(MockDataService.onDutyToday, equals(odCount));
    });

    test('AiAgentService calculateAttendanceForecast computes dynamic calendar days', () {
      final testStudent = StudentDirectoryData.allStudents.first;
      final forecast = AiAgentService().calculateAttendanceForecast(rollNumber: testStudent.rollNumber);

      expect(forecast['totalTermDays'], greaterThan(0));
      expect(forecast['elapsedDays'], greaterThan(0));
      expect(forecast['remainingDays'], greaterThanOrEqualTo(0));
      expect(forecast['currentPercentage'], greaterThanOrEqualTo(0.0));
      expect(forecast['currentPercentage'], lessThanOrEqualTo(100.0));
      expect(forecast['status'], isIn(['ELIGIBLE', 'CRITICAL DEFICIT']));
    });

    test('MockDataService getStudentAttendancePercentage returns valid percentage', () {
      final testStudent = StudentDirectoryData.allStudents.first;
      final pct = MockDataService.getStudentAttendancePercentage(testStudent);

      expect(pct, greaterThanOrEqualTo(0.0));
      expect(pct, lessThanOrEqualTo(100.0));
    });

    test('TimetableDataService fetchTimetableFromDb falls back cleanly when offline', () async {
      final timetable = await TimetableDataService.fetchTimetableFromDb('A');
      expect(timetable.section, equals('A'));
      expect(timetable.subjects, isNotEmpty);
      expect(timetable.schedule, isNotEmpty);
      expect(timetable.schedule.containsKey('Monday'), isTrue);
    });
  });
}
