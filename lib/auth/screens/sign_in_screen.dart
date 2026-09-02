import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'muthulakshmi.aids@vsb.ac.in');
  final _passwordCtrl = TextEditingController(text: 'password123');
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isStorming = false;
  double _lightningOpacity = 0.0;

  late AnimationController _cloudAnimController;
  late AnimationController _lightningAnimController;

  @override
  void initState() {
    super.initState();
    _cloudAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _lightningAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _lightningAnimController.addListener(() {
      final v = _lightningAnimController.value;
      if ((v > 0.12 && v < 0.22) || (v > 0.32 && v < 0.45) || (v > 0.60 && v < 0.72)) {
        setState(() => _lightningOpacity = 0.95);
      } else {
        setState(() => _lightningOpacity = 0.0);
      }
    });
  }

  @override
  void dispose() {
    _cloudAnimController.dispose();
    _lightningAnimController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = AuthService();
    if (authService.isLockedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Security Lock active. Please wait ${authService.remainingLockoutSeconds}s.'),
          backgroundColor: AppColors.absentRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isStorming = true;
    });

    _lightningAnimController.forward(from: 0.0);

    final success = await authService.preAuthenticate(
      _emailCtrl.text,
      _passwordCtrl.text,
    );

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isStorming = false;
    });

    if (success) {
      Navigator.pushNamed(context, '/security-verification');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildSkyCloudHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        const Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryPurple),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your email' : null,
                        ),
                        const SizedBox(height: 18),
                        const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryPurple),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Password too short' : null,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                            child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF38BDF8)]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.bolt_rounded, color: Color(0xFFFDE047)),
                                        SizedBox(width: 8),
                                        Text('Entering with Thunder...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    )
                                  : const Text('Login with Thunder ⚡', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Quick Demo Access Accounts:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _roleChip('Dr. Manivannan (Overall HOD)', 'manivannan.hod@vsb.ac.in'),
                            _roleChip('Mrs. Kavitha (1st & 2nd Yr HOD)', 'kavitha.hod@vsb.ac.in'),
                            _roleChip('Advisor: Mrs. S. Muthulakshmi', 'muthulakshmi.aids@vsb.ac.in'),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isStorming && _lightningOpacity > 0.0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.white.withValues(alpha: _lightningOpacity),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkyCloudHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        gradient: _isStorming ? AppColors.stormGradient : AppColors.headerGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(44),
          bottomRight: Radius.circular(44),
        ),
        boxShadow: [
          BoxShadow(
            color: (_isStorming ? const Color(0xFF0F172A) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _cloudAnimController,
            builder: (ctx, child) {
              return Positioned(
                top: 20,
                left: -100 + (_cloudAnimController.value * (MediaQuery.of(context).size.width + 200)),
                child: Opacity(
                  opacity: 0.35,
                  child: const Icon(Icons.cloud_rounded, size: 140, color: Colors.white),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _cloudAnimController,
            builder: (ctx, child) {
              return Positioned(
                top: 110,
                right: -80 + (_cloudAnimController.value * (MediaQuery.of(context).size.width + 160)),
                child: Opacity(
                  opacity: 0.25,
                  child: const Icon(Icons.cloud_queue_rounded, size: 110, color: Colors.white),
                ),
              );
            },
          ),
          if (_isStorming)
            Positioned(
              top: 50,
              left: MediaQuery.of(context).size.width * 0.45,
              child: const Icon(Icons.flash_on_rounded, size: 100, color: Color(0xFFFDE047)),
            ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Icon(
                      _isStorming ? Icons.thunderstorm_rounded : Icons.cloud_done_rounded,
                      size: 34,
                      color: _isStorming ? const Color(0xFFFDE047) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('PinkSlipReport', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                  const SizedBox(height: 4),
                  const Text('AI & DS Department • Sky Cloud Portal', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    _isStorming ? '⚡ Thunder Storm Logging In...' : 'Welcome Back!',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String label, String email) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryPurple)),
      backgroundColor: const Color(0xFFE0F2FE),
      side: const BorderSide(color: Color(0xFFBAE6FD)),
      onPressed: () {
        _emailCtrl.text = email;
        _passwordCtrl.text = 'password123';
      },
    );
  }
}
