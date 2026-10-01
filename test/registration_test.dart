import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slipreport/auth/screens/sign_up_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final confirmation in [true, false]) {
    testWidgets('registration routes to sign-in, confirmation=$confirmation', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SignUpScreen(
            register:
                ({required fullName, required email, required password}) async {
                  calls++;
                  expect(fullName, 'Student Example');
                  expect(email, 'student@example.com');
                  expect(password, 'test-password');
                  return confirmation;
                },
          ),
          routes: {
            '/sign-in': (_) =>
                const Scaffold(body: Text('Sign-in destination')),
          },
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Student Example',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'student@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'test-password');
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Sign-in destination'), findsOneWidget);
      expect(
        find.textContaining(
          confirmation ? 'Check your email' : 'Registration complete',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('failed registration stays on form and displays the error', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: SignUpScreen(
          register:
              ({required fullName, required email, required password}) async {
                throw const AuthException('Signups are disabled');
              },
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'Student');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'student@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'test-password');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(find.text('Signups are disabled'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
