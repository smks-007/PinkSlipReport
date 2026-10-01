import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_dashboard_data.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';

/// Read-only personal portal, including for class representatives.
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key, this.loadDashboard});

  final Future<StudentDashboardData> Function()? loadDashboard;

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _auth = AuthService();
  Future<StudentDashboardData>? _summary;
  String? _loadedAuthId;

  String? get _studentAuthId =>
      _auth.isLoggedIn &&
          !_auth.isRecoverySession &&
          _auth.currentUser?.role == UserRole.student
      ? _auth.currentUser!.id
      : null;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_authChanged);
    _reload();
  }

  @override
  void dispose() {
    _auth.removeListener(_authChanged);
    super.dispose();
  }

  void _authChanged() {
    if (_studentAuthId != _loadedAuthId) {
      setState(_reload);
    }
  }

  void _reload() {
    _loadedAuthId = _studentAuthId;
    _summary = _loadedAuthId == null ? null : _load(_loadedAuthId!);
  }

  Future<StudentDashboardData> _load(String authId) async {
    final data =
        await (widget.loadDashboard ??
            SupabaseService().fetchMyStudentDashboard)();
    if (data.authId != authId || _studentAuthId != authId) {
      throw StateError('Student session changed.');
    }
    return data;
  }

  Future<void> _signOut() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _studentAuthId == null ? null : () => setState(_reload),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign Out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _studentAuthId == null
          ? const Center(
              child: Text('Please sign in with your student account.'),
            )
          : FutureBuilder<StudentDashboardData>(
              future: _summary,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Your details could not be loaded. Try again or contact your class advisor.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => setState(_reload),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final data = snapshot.requireData;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _attendanceCard(data.attendancePercentage),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My details',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  _detail('Name', data.name),
                                  _detail('Email', data.email),
                                  _detail('Roll number', data.rollNumber),
                                  _detail(
                                    'Register number',
                                    data.registerNumber,
                                  ),
                                  _detail('Class / section', data.section),
                                  _detail('Department', data.department),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _attendanceCard(double? percentage) => Card(
    color: AppColors.primaryPurple,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.pie_chart_outline, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          const Text(
            'My attendance',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            percentage == null
                ? 'Not available'
                : '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            percentage == null
                ? 'No attendance has been recorded yet.'
                : 'Based on recorded attendance through today.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    ),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}
