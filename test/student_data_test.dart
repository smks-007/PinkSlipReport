import 'package:flutter_test/flutter_test.dart';
import 'package:slipreport/core/data/student_directory_data.dart';
import 'package:slipreport/core/models/student_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Student Roster & Directory Tests', () {
    test('Total students count matches department roster across all 10 sections', () {
      expect(StudentDirectoryData.allStudents.length, 622);

      // Section counts
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
    });

    test('All students have valid IDs, non-empty names, and non-empty roll numbers', () {
      for (final student in StudentDirectoryData.allStudents) {
        expect(student.id, isNotEmpty);
        expect(student.name, isNotEmpty);
        expect(student.rollNumber, isNotEmpty);
        expect(student.department, 'AI&DS');
        expect(student.year, isIn([1, 2, 3, 4]));
        expect(student.section, isIn(['A', 'B', 'C', 'D']));
      }
    });

    test('StudentModel copyWith maintains or updates gender appropriately', () {
      const student = StudentModel(
        id: 'test-1',
        name: 'ABINAYA G',
        rollNumber: '25243001',
        department: 'AI&DS',
        section: 'A',
        year: 2,
        batchYear: '2025 BATCH',
        advisorId: 'adv-iia',
        gender: 'Female',
      );

      expect(student.gender, 'Female');
      final updated = student.copyWith(gender: 'Girl');
      expect(updated.gender, 'Girl');
    });
  });
}
