import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:slipreport/main.dart';
import 'package:slipreport/auth/widgets/auth_link_text.dart';

void main() {
  testWidgets('Authentication Flow and Validation Test', (WidgetTester tester) async {
    // Set a larger surface size to ensure all widgets fit on screen
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // ─────────────────────────────────────────────────────────────────
    // 1. SIGN IN SCREEN TESTS
    // ─────────────────────────────────────────────────────────────────
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Enter valid user name & password to continue'), findsOneWidget);
    expect(find.text('Forget password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // Trigger validation on empty fields
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Verify validation errors are shown
    expect(find.text('Please enter your username'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);

    // Navigate to Sign Up screen
    final signUpLink = tester.widget<AuthLinkText>(find.byType(AuthLinkText));
    signUpLink.onTap();
    await tester.pumpAndSettle();

    // ─────────────────────────────────────────────────────────────────
    // 2. SIGN UP SCREEN TESTS
    // ─────────────────────────────────────────────────────────────────
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Use proper information to continue'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    // Trigger validation on empty fields
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    // Verify validation errors
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);

    // Navigate back to Sign In
    final signInLink = tester.widget<AuthLinkText>(find.byType(AuthLinkText));
    signInLink.onTap();
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);

    // ─────────────────────────────────────────────────────────────────
    // 3. FORGOT PASSWORD SCREEN TESTS
    // ─────────────────────────────────────────────────────────────────
    await tester.tap(find.text('Forget password'));
    await tester.pumpAndSettle();

    expect(find.text('Forget Password'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);

    // Trigger validation
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);

    // Enter invalid email
    await tester.enterText(find.byType(TextFormField), 'invalid-email');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);

    // Navigate back to Sign In
    final forgotSignInLink = tester.widget<AuthLinkText>(find.byType(AuthLinkText));
    forgotSignInLink.onTap();
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
  });
}
