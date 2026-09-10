import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/screens/sign_in_screen.dart';
import 'auth/screens/forgot_password_screen.dart';
import 'dashboard/advisor/screens/advisor_dashboard_screen.dart';
import 'dashboard/advisor/screens/attendance_screen.dart';
import 'dashboard/advisor/screens/leave_management_screen.dart';
import 'dashboard/hod/screens/hod_dashboard_screen.dart';
import 'dashboard/student/screens/student_dashboard_screen.dart';
import 'dashboard/timetable/screens/timetable_screen.dart';
import 'core/services/supabase_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/mock_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService().initialize();
  runApp(const SmartProApp());

  // Sync live Supabase data in background (with error handling)
  try {
    await MockDataService.syncFromSupabase();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Background sync failed: $e');
    }
  }
}

class SmartProApp extends StatelessWidget {
  const SmartProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PinkSlipReport',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          ThemeData.light().textTheme,
        ),
        fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      initialRoute: '/sign-in',
      onGenerateRoute: _generateRoute,
    );
  }

  /// Route guard: Ensures authenticated access to protected routes.
  /// Only /sign-in and /forgot-password are public.
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final authService = AuthService();

    // Public routes (no auth required)
    switch (settings.name) {
      case '/sign-in':
        return MaterialPageRoute(
          builder: (_) => const SignInScreen(),
          settings: settings,
        );
      case '/forgot-password':
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
    }

    // ─── Protected routes: require valid session ───
    if (!authService.isLoggedIn) {
      // Redirect to sign-in if not authenticated or session expired
      return MaterialPageRoute(
        builder: (_) => const SignInScreen(),
        settings: const RouteSettings(name: '/sign-in'),
      );
    }

    // Record activity for session timeout
    authService.recordActivity();
    final userRole = authService.currentUser?.role;

    switch (settings.name) {
      case '/advisor-dashboard':
        if (userRole == UserRole.advisor) {
          return MaterialPageRoute(
            builder: (_) => const AdvisorDashboardScreen(),
            settings: settings,
          );
        }
        break;
      case '/hod-dashboard':
        if (userRole == UserRole.hod) {
          return MaterialPageRoute(
            builder: (_) => const HodDashboardScreen(),
            settings: settings,
          );
        }
        break;
      case '/student-dashboard':
        if (userRole == UserRole.student) {
          return MaterialPageRoute(
            builder: (_) => const StudentDashboardScreen(),
            settings: settings,
          );
        }
        break;
      case '/attendance':
        if (userRole == UserRole.advisor || userRole == UserRole.hod) {
          return MaterialPageRoute(
            builder: (_) => const AttendanceScreen(),
            settings: settings,
          );
        }
        break;
      case '/leave-management':
        if (userRole == UserRole.advisor || userRole == UserRole.hod) {
          return MaterialPageRoute(
            builder: (_) => const LeaveManagementScreen(),
            settings: settings,
          );
        }
        break;
      case '/timetable':
        return MaterialPageRoute(
          builder: (_) => const TimetableScreen(),
          settings: settings,
        );
    }

    // Unauthorized access or unknown route → redirect to sign-in
    return MaterialPageRoute(
      builder: (_) => const SignInScreen(),
      settings: const RouteSettings(name: '/sign-in'),
    );
  }
}
