import 'package:flutter/material.dart';
import 'auth/screens/sign_in_screen.dart';
import 'auth/screens/sign_up_screen.dart';
import 'auth/screens/forgot_password_screen.dart';
import 'auth/screens/security_verification_screen.dart';
import 'dashboard/advisor/screens/advisor_dashboard_screen.dart';
import 'dashboard/advisor/screens/attendance_screen.dart';
import 'dashboard/advisor/screens/leave_management_screen.dart';
import 'dashboard/hod/screens/hod_dashboard_screen.dart';
import 'dashboard/timetable/screens/timetable_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PinkSlipReport',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF047857),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      initialRoute: '/sign-in',
      routes: {
        '/sign-in': (_) => const SignInScreen(),
        '/security-verification': (_) => const SecurityVerificationScreen(),
        '/sign-up': (_) => const SignUpScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/advisor-dashboard': (_) => const AdvisorDashboardScreen(),
        '/hod-dashboard': (_) => const HodDashboardScreen(),
        '/attendance': (_) => const AttendanceScreen(),
        '/leave-management': (_) => const LeaveManagementScreen(),
        '/timetable': (_) => const TimetableScreen(),
      },
    );
  }
}
