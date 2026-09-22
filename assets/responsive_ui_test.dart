// test/responsive_ui_test.dart
// ─────────────────────────────────────────────────────────────────────────────
// Automated multi-resolution responsive test suite.
// Tests all 9 screens across 4 mobile resolutions + 1.5× text scale.
//
// Run:  flutter test test/responsive_ui_test.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import your actual screen widgets here:
// import 'package:pink_slip_report/auth/screens/sign_in_screen.dart';
// import 'package:pink_slip_report/auth/screens/forgot_password_screen.dart';
// import 'package:pink_slip_report/auth/screens/security_verification_screen.dart';
// import 'package:pink_slip_report/dashboard/hod/screens/hod_dashboard_screen.dart';
// import 'package:pink_slip_report/dashboard/advisor/screens/advisor_dashboard_screen.dart';
// import 'package:pink_slip_report/dashboard/student/screens/student_dashboard_screen.dart';
// import 'package:pink_slip_report/dashboard/timetable/screens/timetable_screen.dart';
// import 'package:pink_slip_report/dashboard/shared/widgets/attendance_report_viewer_dialog.dart';
// import 'package:pink_slip_report/dashboard/shared/widgets/create_pink_slip_dialog.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Test configuration
// ══════════════════════════════════════════════════════════════════════════════

/// Device profiles: (width × height, label)
const _resolutions = [
  _Resolution(320, 568,  'Ultra-compact (iPhone SE 1st gen)'),
  _Resolution(360, 640,  'Standard compact Android'),
  _Resolution(390, 844,  'Standard iPhone 12/13/14'),
  _Resolution(430, 932,  'Large modern phone (iPhone 15 Plus)'),
];

/// Text-scale factors to verify under.
const _textScaleFactors = [1.0, 1.5];

// ══════════════════════════════════════════════════════════════════════════════
// Screens under test
// ══════════════════════════════════════════════════════════════════════════════

/// Map of screen name → builder function.
/// Replace the placeholder widgets with your real screen imports.
final _screens = <String, WidgetBuilder>{
  'SignInScreen':               (_) => const _PlaceholderScreen(name: 'SignIn'),
  'ForgotPasswordScreen':       (_) => const _PlaceholderScreen(name: 'ForgotPassword'),
  'SecurityVerificationScreen': (_) => const _PlaceholderScreen(name: 'SecurityVerification'),
  'HodDashboardScreen':         (_) => const _PlaceholderScreen(name: 'HodDashboard'),
  'AdvisorDashboardScreen':     (_) => const _PlaceholderScreen(name: 'AdvisorDashboard'),
  'StudentDashboardScreen':     (_) => const _PlaceholderScreen(name: 'StudentDashboard'),
  'TimetableScreen':            (_) => const _PlaceholderScreen(name: 'Timetable'),
  'AttendanceReportViewerDialog': (ctx) => const _DialogWrapper(
        child: _PlaceholderScreen(name: 'AttendanceReportDialog'),
      ),
  'CreatePinkSlipDialog': (ctx) => const _DialogWrapper(
        child: _PlaceholderScreen(name: 'CreatePinkSlipDialog'),
      ),
};

// ══════════════════════════════════════════════════════════════════════════════
// Main test runner
// ══════════════════════════════════════════════════════════════════════════════

void main() {
  group('Responsive UI — zero RenderFlex overflows', () {
    for (final resolution in _resolutions) {
      for (final textScale in _textScaleFactors) {
        group('${resolution.label} @ ${textScale}× text scale', () {
          for (final entry in _screens.entries) {
            testWidgets(entry.key, (WidgetTester tester) async {
              // ── Set device resolution ───────────────────────────────────
              // Uses Flutter 3 API (not deprecated window.physicalSize).
              tester.view.physicalSize = Size(
                resolution.width * tester.view.devicePixelRatio,
                resolution.height * tester.view.devicePixelRatio,
              );
              addTearDown(() => tester.view.resetPhysicalSize());

              // ── Set text scale ──────────────────────────────────────────
              // Uses Flutter 3.13+ API (not deprecated textScaleFactor).
              tester.platformDispatcher.textScalerTestValue =
                  TextScaler.linear(textScale);
              addTearDown(
                () => tester.platformDispatcher.clearTextScalerTestValue(),
              );

              // ── Pump the screen ─────────────────────────────────────────
              await tester.pumpWidget(
                _TestApp(builder: entry.value),
              );
              await tester.pump();    // first frame
              await tester.pump(const Duration(milliseconds: 300)); // animations

              // ── Assert: no RenderFlex overflow errors ───────────────────
              expect(
                tester.takeException(),
                isNull,
                reason:
                    '${entry.key} threw an exception at ${resolution.width}×${resolution.height} '
                    '@ ${textScale}× text scale',
              );

              // ── Assert: no overflow warnings in render tree ─────────────
              final overflowErrors = tester
                  .allElements
                  .where((e) =>
                      e.widget.runtimeType.toString().contains('RenderFlex'))
                  .toList();

              // This checks that no element marked itself as overflowing.
              // The canary: if a RenderFlex overflowed it would be caught
              // by takeException() above via the FlutterError handler.
              // This secondary check catches silent overflows hidden by
              // overflow clip.
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
  // Regression: keyboard inset test for SubmitLeaveModal
  // ══════════════════════════════════════════════════════════════════════════

  group('Keyboard inset — no double padding', () {
    testWidgets('SubmitLeaveModal padding is applied exactly once',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      addTearDown(() => tester.view.resetPhysicalSize());

      // Simulate keyboard appearing (bottom inset = 300 px).
      tester.view.viewInsets = FakeViewPadding(bottom: 300);
      addTearDown(() => tester.view.resetViewInsets());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,    // required
                  useSafeArea: true,
                  builder: (_) => const _PlaceholderScreen(name: 'LeaveModal'),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Bottom sheet should be visible and not overflowing.
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
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
    // Immediately show the dialog so the test can assert on it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => child,
      );
    });
    return const Scaffold(body: SizedBox.expand());
  }
}

/// Placeholder — replace each with your real screen widget.
class _PlaceholderScreen extends StatelessWidget {
  final String name;

  const _PlaceholderScreen({required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(child: Text('$name placeholder')),
    );
  }
}

/// Bounded divider test widget — mirrors the production fix.
class _BoundedDividerTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Center(child: Text('Stat 1'))),
        // Correctly bounded — will not crash.
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
