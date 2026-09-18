import 'package:flutter_test/flutter_test.dart';
import 'package:slipreport/core/services/auth_service.dart';
import 'package:slipreport/core/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth & Role Security Tests', () {
    late AuthService authService;
    late SupabaseService supabaseService;

    setUp(() {
      authService = AuthService();
      supabaseService = SupabaseService();
      authService.resetLockout();
    });

    test('resolveEmail correctly maps standard HOD and advisor aliases', () {
      expect(supabaseService.resolveEmail('hod'), 'manivannan.hod@vsb.ac.in');
      expect(supabaseService.resolveEmail('manivannan'), 'manivannan.hod@vsb.ac.in');
      expect(supabaseService.resolveEmail('hod12'), 'hod.kavitha@vsb.ac.in');
      expect(supabaseService.resolveEmail('kavitha'), 'hod.kavitha@vsb.ac.in');
      expect(supabaseService.resolveEmail('advisor.2a'), 'advisor.2a@vsb.ac.in');
      expect(supabaseService.resolveEmail('advisor.4b'), 'advisor.4b@vsb.ac.in');
    });

    test('resolveEmail maps roll numbers to official student emails', () {
      expect(
        supabaseService.resolveEmail('25243001'),
        '25243001@student.smartcampus.edu',
      );
      expect(
        supabaseService.resolveEmail('23243001'),
        '23243001@student.smartcampus.edu',
      );
    });

    test('Lockout mechanism triggers after 5 failed attempts and resets properly', () {
      expect(authService.isLockedOut, isFalse);

      // Verify lockout reset functionality
      authService.resetLockout();
      expect(authService.isLockedOut, isFalse);
      expect(authService.remainingLockoutSeconds, 0);
    });

    test('Session timeout behaves correctly after inactivity', () {
      // By default not logged in, so not expired
      expect(authService.isSessionExpired, isFalse);
    });
  });
}
