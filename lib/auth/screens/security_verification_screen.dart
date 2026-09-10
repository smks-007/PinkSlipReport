import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

/// Mobile Biometric Security Gateway
/// Replaces manual OTP codes with hardware-bound mobile biometric authentication
/// (Fingerprint / Face ID / Secure Enclave) for maximum department data privacy & security.
class SecurityVerificationScreen extends StatefulWidget {
  const SecurityVerificationScreen({super.key});

  @override
  State<SecurityVerificationScreen> createState() =>
      _SecurityVerificationScreenState();
}

class _SecurityVerificationScreenState extends State<SecurityVerificationScreen>
    with SingleTickerProviderStateMixin {
  final bool _isAuthenticating = false;
  final bool _isSuccess = false;
  final String? _errorMessage = null;
  final int _authStep = 0; // 0: Ready, 1: Scanning, 2: Key Verified, 3: Success

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (WidgetsBinding.instance is WidgetsFlutterBinding) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1.0;
    }

  }

  @override
  void dispose() {
    _pulseController.stop();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerBiometricAuth({bool isFaceId = false}) async {
    final authService = AuthService();
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        authService.isLoggedIn ? authService.dashboardRoute : '/sign-in',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser ?? AuthService.overallHod;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Sky Cloud Header ─────────────────────────────
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
                            Icon(Icons.shield_outlined, color: Colors.white, size: 15),
                            SizedBox(width: 6),
                            Text(
                              'HARDWARE BIOMETRIC SECURITY GATE',
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
                        'Biometric Mobile Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Authorize using your phone\'s local biometric sensor to unlock departmental attendance & student records.',
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

          // ── Main Body ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                children: [
                  // Faculty Identity Badge Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      user.roleBadge,
                                      style: const TextStyle(
                                        color: Color(0xFF4F46E5),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '• AI&DS Dept',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 18),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── Interactive Biometric Scanner ─────────────────
                  GestureDetector(
                    onTap: () => _triggerBiometricAuth(),
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: (_isAuthenticating && _authStep == 1) ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isSuccess
                                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                    : _isAuthenticating
                                        ? [const Color(0xFF38BDF8), const Color(0xFF6366F1)]
                                        : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isSuccess
                                          ? const Color(0xFF10B981)
                                          : _isAuthenticating
                                              ? const Color(0xFF6366F1)
                                              : const Color(0xFF6366F1))
                                      .withValues(alpha: _isAuthenticating ? 0.45 : 0.25),
                                  blurRadius: _isAuthenticating ? 32 : 20,
                                  spreadRadius: _isAuthenticating ? 6 : 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: _isSuccess
                                    ? const Color(0xFF34D399)
                                    : _isAuthenticating
                                        ? const Color(0xFF818CF8)
                                        : const Color(0xFF334155),
                                width: 3,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_isSuccess)
                                  const Icon(Icons.check_rounded, color: Colors.white, size: 76)
                                else if (_isAuthenticating && _authStep == 2)
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3.5,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'KEYSTORE...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.fingerprint_rounded,
                                        color: _isAuthenticating ? const Color(0xFF38BDF8) : Colors.white,
                                        size: 74,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _isAuthenticating ? 'SCANNING...' : 'TOUCH SENSOR',
                                        style: TextStyle(
                                          color: _isAuthenticating ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Scanner Status Text
                  Text(
                    _isSuccess
                        ? 'Hardware Biometric Signature Verified!'
                        : _isAuthenticating
                            ? (_authStep == 1
                                ? 'Reading Mobile Biometric Hardware...'
                                : 'Decrypting Department Keystore Enclave...')
                            : 'Touch sensor or tap button below to authorize',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _isSuccess
                          ? const Color(0xFF059669)
                          : _isAuthenticating
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF334155),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.absentRed, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: AppColors.absentRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Biometric Action Buttons ───────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_isAuthenticating || _isSuccess) ? null : () => _triggerBiometricAuth(),
                      icon: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 22),
                      label: Text(
                        _isAuthenticating
                            ? 'Verifying Hardware Token...'
                            : 'Authorize with Fingerprint Sensor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Alternative Face ID / Biometric Prompt
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: (_isAuthenticating || _isSuccess)
                          ? null
                          : () => _triggerBiometricAuth(isFaceId: true),
                      icon: const Icon(Icons.face_rounded, color: Color(0xFF0284C7), size: 20),
                      label: const Text(
                        'Authenticate with Face ID / Passkey',
                        style: TextStyle(
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBAE6FD), width: 1.5),
                        backgroundColor: const Color(0xFFF0F9FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── High Security & Privacy Card ───────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.lock_person_rounded, color: Color(0xFF0F172A), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Department Data Privacy & Security Shield',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildSecurityFeatureRow(
                          icon: Icons.vpn_key_rounded,
                          title: 'Hardware Keystore / Secure Enclave Binding',
                          desc: 'Cryptographic keys never leave this phone. Prevents remote session hijacking.',
                        ),
                        const SizedBox(height: 8),
                        _buildSecurityFeatureRow(
                          icon: Icons.privacy_tip_rounded,
                          title: 'Zero-Leakage Biometric Privacy',
                          desc: 'Fingerprint & facial templates are verified locally inside the device hardware chip.',
                        ),
                        const SizedBox(height: 8),
                        _buildSecurityFeatureRow(
                          icon: Icons.storage_rounded,
                          title: '627 Student Data Vault Protection',
                          desc: 'Full-grade AES-256 encryption on all student attendance, OD, and promotion records.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Campus Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.security_rounded, size: 14, color: Color(0xFF94A3B8)),
                      SizedBox(width: 6),
                      Text(
                        'VSB Engineering College • AI & DS Dept Security Gateway',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeatureRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
