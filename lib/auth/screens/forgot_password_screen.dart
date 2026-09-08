import 'package:flutter/material.dart';

/// Redesigned Smart Pro Credential Recovery Screen
/// Matches the high-tech, modern visual aesthetic of the Smart Pro Portal.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'manivannan.hod@vsb.ac.in');
  int _selectedRoleTab = 0; // 0 = HOD, 1 = Class Advisor
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _onRoleTabChanged(int index) {
    setState(() {
      _selectedRoleTab = index;
      if (index == 0) {
        _emailCtrl.text = 'manivannan.hod@vsb.ac.in';
      } else {
        _emailCtrl.text = 'advisor.2a@vsb.ac.in';
      }
    });
  }

  Future<void> _handleResetRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    _showSuccessBottomSheet();
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF86EFAC), width: 2),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: Color(0xFF16A34A),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reset Link Dispatched!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'A secure hardware token reset link has been delivered to ${_emailCtrl.text}. Please check your official inbox to re-bind your mobile biometric passkey.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacementNamed(context, '/sign-in');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Return to Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Sky Cloud Header ────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 45, bottom: 26, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0284C7),
                    Color(0xFF38BDF8),
                    Color(0xFF7DD3FC),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x440284C7),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Cloud silhouettes
                  Positioned(
                    top: 0,
                    left: -10,
                    child: Icon(
                      Icons.cloud,
                      size: 110,
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: -10,
                    child: Icon(
                      Icons.cloud,
                      size: 95,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pushReplacementNamed(context, '/sign-in'),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            child: const Icon(Icons.account_balance_rounded, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'PinkSlipReport',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 44),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.lock_reset_rounded, color: Colors.white, size: 15),
                            SizedBox(width: 6),
                            Text(
                              'FACULTY CREDENTIAL RECOVERY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Reset Access Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter your registered institutional college email to receive secure recovery & biometric passkey re-enrollment instructions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Recovery Body ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role Selector Tabs
                    _buildRoleTabs(),

                    const SizedBox(height: 20),

                    const Text(
                      'Institutional Email / Faculty ID',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Email Input Field
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'e.g. manivannan.hod@vsb.ac.in',
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0284C7)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFBAE6FD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFBAE6FD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your registered college email';
                        if (!v.contains('@')) return 'Please enter a valid email address';
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Quick Sample Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildSampleEmailChip('manivannan.hod@vsb.ac.in', 'HOD ID'),
                        _buildSampleEmailChip('advisor.2a@vsb.ac.in', 'II-A Advisor'),
                        _buildSampleEmailChip('advisor.3a@vsb.ac.in', 'III-A Advisor'),
                        _buildSampleEmailChip('advisor.4a@vsb.ac.in', 'IV-A Advisor'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Reset Request Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleResetRequest,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          label: Text(
                            _isLoading ? 'Dispatching Recovery Token...' : 'Send Recovery Instructions',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Security Protocol Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.verified_outlined, color: Color(0xFF16A34A), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Security Policy & Data Protection',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'To safeguard 627 AI&DS student records, passkey resets require approval from the Department IT Administrator or institutional 2FA.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF15803D),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Helpdesk Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.support_agent_rounded, color: Color(0xFF0284C7), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Department IT Helpdesk',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'HOD Office • Intercom Ext: 402 / 403',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Return to Login Link
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/sign-in'),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF0284C7)),
                        label: const Text(
                          'Remember password? Back to Sign In',
                          style: TextStyle(
                            color: Color(0xFF0284C7),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onRoleTabChanged(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedRoleTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedRoleTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '🏛️ HOD Portal',
                    style: TextStyle(
                      fontWeight: _selectedRoleTab == 0 ? FontWeight.w800 : FontWeight.w600,
                      color: _selectedRoleTab == 0 ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onRoleTabChanged(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedRoleTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedRoleTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '👨‍🏫 Class Advisor',
                    style: TextStyle(
                      fontWeight: _selectedRoleTab == 1 ? FontWeight.w800 : FontWeight.w600,
                      color: _selectedRoleTab == 1 ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleEmailChip(String email, String label) {
    return InkWell(
      onTap: () => setState(() => _emailCtrl.text = email),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_rounded, size: 12, color: Color(0xFF0284C7)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0369A1),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
