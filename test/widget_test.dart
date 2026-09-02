import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slipreport/main.dart';

void main() {
  testWidgets('App renders PinkSlipReport SignIn and Security Screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify SignIn screen elements
    expect(find.text('PinkSlipReport'), findsOneWidget);
    expect(find.text('AI & DS Department • Sky Cloud Portal'), findsOneWidget);
    expect(find.text('Dr. Manivannan (Overall HOD)'), findsOneWidget);
    expect(find.text('Mrs. Kavitha (1st & 2nd Yr HOD)'), findsOneWidget);
  });
}
