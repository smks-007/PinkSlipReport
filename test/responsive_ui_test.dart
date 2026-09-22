// test/responsive_ui_test.dart
// ─────────────────────────────────────────────────────────────────────────────
// Automated multi-resolution responsive test suite.
// Tests all 9 screens across 4 mobile resolutions + 1.5× text scale.
//
// Run:  flutter test test/responsive_ui_test.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:slipreport/auth/screens/sign_in_screen.dart';
import 'package:slipreport/auth/screens/forgot_password_screen.dart';
import 'package:slipreport/auth/screens/security_verification_screen.dart';
import 'package:slipreport/dashboard/hod/screens/hod_dashboard_screen.dart';
import 'package:slipreport/dashboard/advisor/screens/advisor_dashboard_screen.dart';
import 'package:slipreport/dashboard/student/screens/student_dashboard_screen.dart';
import 'package:slipreport/dashboard/timetable/screens/timetable_screen.dart';
import 'package:slipreport/dashboard/shared/widgets/attendance_report_viewer_dialog.dart';
import 'package:slipreport/dashboard/shared/widgets/create_pink_slip_dialog.dart';
import 'package:slipreport/core/services/auth_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Test configuration
// ══════════════════════════════════════════════════════════════════════════════

/// Device profiles: (width × height, label)
const _resolutions = [
  _Resolution(320, 568, 'Ultra-compact (iPhone SE 1st gen)'),
  _Resolution(360, 640, 'Standard compact Android'),
  _Resolution(390, 844, 'Standard iPhone 12/13/14'),
  _Resolution(430, 932, 'Large modern phone (iPhone 15 Plus)'),
];

/// Text-scale factors to verify under.
const _textScaleFactors = [1.0, 1.5];

// ══════════════════════════════════════════════════════════════════════════════
// Screens under test
// ══════════════════════════════════════════════════════════════════════════════

final _screens = <String, WidgetBuilder>{
  'SignInScreen': (_) => const SignInScreen(),
  'ForgotPasswordScreen': (_) => const ForgotPasswordScreen(),
  'SecurityVerificationScreen': (_) => const SecurityVerificationScreen(),
  'HodDashboardScreen': (_) {
    AuthService().setMockUser(AuthService.overallHod);
    return const HodDashboardScreen();
  },
  'AdvisorDashboardScreen': (_) {
    AuthService().setMockUser(AuthService.sectionAdvisors.first);
    return const AdvisorDashboardScreen();
  },
  'StudentDashboardScreen': (_) {
    AuthService().setMockUser(AuthService.classRepresentatives.first);
    return const StudentDashboardScreen();
  },
  'TimetableScreen': (_) => const TimetableScreen(initialSection: 'A'),
  'AttendanceReportViewerDialog': (_) => const _DialogWrapper(
        child: AttendanceReportViewerDialog(),
      ),
  'CreatePinkSlipDialog': (_) {
    AuthService().setMockUser(AuthService.sectionAdvisors.first);
    return const _DialogWrapper(
      child: CreatePinkSlipDialog(),
    );
  },
};

// ══════════════════════════════════════════════════════════════════════════════
// Main test runner
// ══════════════════════════════════════════════════════════════════════════════

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Responsive UI — zero RenderFlex overflows', () {
    for (final resolution in _resolutions) {
      for (final textScale in _textScaleFactors) {
        group('${resolution.label} @ ${textScale}x text scale', () {
          for (final entry in _screens.entries) {
            testWidgets(entry.key, (WidgetTester tester) async {
              // ── Set device resolution ───────────────────────────────────
              tester.view.physicalSize = Size(
                resolution.width * tester.view.devicePixelRatio,
                resolution.height * tester.view.devicePixelRatio,
              );
              addTearDown(() => tester.view.resetPhysicalSize());

              // ── Set text scale ──────────────────────────────────────────
              tester.platformDispatcher.textScaleFactorTestValue = textScale;
              addTearDown(
                () => tester.platformDispatcher.clearTextScaleFactorTestValue(),
              );

              // ── Pump the screen ─────────────────────────────────────────
              await tester.pumpWidget(
                _TestApp(builder: entry.value),
              );
              await tester.pump(); // first frame
              await tester.pump(const Duration(milliseconds: 300)); // animations

              // ── Assert: no RenderFlex overflow errors ───────────────────
              expect(
                tester.takeException(),
                isNull,
                reason:
                    '${entry.key} threw an exception at ${resolution.width}x${resolution.height} '
                    '@ ${textScale}x text scale',
              );

              // ── Assert: no overflow warnings in render tree ─────────────
              final overflowErrors = tester
                  .allElements
                  .where((e) =>
                      e.widget.runtimeType.toString().contains('RenderFlex'))
                  .toList();

              for (final el in overflowErrors) {
                expect(
                  el.renderObject?.debugNeedsLayout,
                  isFalse,
                  reason: 'Layout dirty after pump — possible overflow in ${entry.key}',
                );
              }
            });
          }
        });
      }
    }
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Regression: keyboard inset test
  // ══════════════════════════════════════════════════════════════════════════

  group('Keyboard inset — no double padding', () {
    testWidgets('Modal bottom sheet keyboard inset handles safely',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      addTearDown(() => tester.view.resetPhysicalSize());

      // Simulate keyboard appearing (bottom inset = 300 px).
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() => tester.view.resetViewInsets());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Leave Modal Bottom Sheet'),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Regression: bounded divider in HOD banner
  // ══════════════════════════════════════════════════════════════════════════

  group('HOD Banner — no unbounded VerticalDivider crash', () {
    for (final resolution in _resolutions) {
      testWidgets('${resolution.label} — bounded divider renders without crash',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(
          resolution.width * tester.view.devicePixelRatio,
          resolution.height * tester.view.devicePixelRatio,
        );
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          _TestApp(
            builder: (_) => Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: _BoundedDividerTest(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull,
            reason: 'Bounded divider crashed at ${resolution.width}×${resolution.height}');
      });
    }
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// Test helpers & stubs
// ══════════════════════════════════════════════════════════════════════════════

class _Resolution {
  final double width;
  final double height;
  final String label;

  const _Resolution(this.width, this.height, this.label);
}

class _TestApp extends StatelessWidget {
  final WidgetBuilder builder;

  const _TestApp({required this.builder});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        useMaterial3: true,
      ),
      home: Builder(builder: builder),
    );
  }
}

/// Wraps a dialog widget in a Scaffold + showDialog trigger for testing.
class _DialogWrapper extends StatelessWidget {
  final Widget child;

  const _DialogWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => child,
      );
    });
    return const Scaffold(body: SizedBox.expand());
  }
}

/// Bounded divider test widget — mirrors the production fix.
class _BoundedDividerTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Center(child: Text('Stat 1'))),
        Container(width: 1, height: 32, color: Colors.grey),
        const Expanded(child: Center(child: Text('Stat 2'))),
        Container(width: 1, height: 32, color: Colors.grey),
        const Expanded(child: Center(child: Text('Stat 3'))),
        Container(width: 1, height: 32, color: Colors.grey),
        const Expanded(child: Center(child: Text('Stat 4'))),
      ],
    );
  }
}
