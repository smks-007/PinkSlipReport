import 'package:flutter/material.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_illustration.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/auth_link_text.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/social_login_button.dart';

/// Sign-In screen — recreates the left-side card from the reference image.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate a network call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // TODO: Replace with actual auth logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login successful!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.pageBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: AuthCard(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Illustration ──────────────────────────
                    const SignInIllustration(height: 150),
                    const SizedBox(height: 16),

                    // ── Heading ──────────────────────────────
                    const Text('Sign In', style: AuthTheme.heading),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter valid user name & password to continue',
                      style: AuthTheme.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // ── Username ──────────────────────────────
                    AuthInputField(
                      hintText: 'User name',
                      prefixIcon: Icons.person_outline_rounded,
                      controller: _usernameCtrl,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please enter your username' : null,
                    ),
                    const SizedBox(height: AuthTheme.fieldSpacing),

                    // ── Password ──────────────────────────────
                    AuthInputField(
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      controller: _passwordCtrl,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
                    ),
                    const SizedBox(height: 8),

                    // ── Forgot Password ──────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forget password',
                          style: AuthTheme.linkText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Login Button ─────────────────────────
                    AuthPrimaryButton(
                      label: 'Login',
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 24),

                    // ── Divider ──────────────────────────────
                    const AuthDivider(),
                    const SizedBox(height: 20),

                    // ── Social Buttons ───────────────────────
                    Row(
                      children: [
                        SocialLoginButton(
                          label: 'Google',
                          icon: Icons.g_mobiledata_rounded,
                          iconColor: AuthTheme.googleRed,
                          onPressed: () {
                            // TODO: Google sign-in
                          },
                        ),
                        const SizedBox(width: 12),
                        SocialLoginButton(
                          label: 'Facebook',
                          icon: Icons.facebook_rounded,
                          iconColor: AuthTheme.facebookBlue,
                          onPressed: () {
                            // TODO: Facebook sign-in
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Sign Up Link ─────────────────────────
                    AuthLinkText(
                      prefix: "Haven't any account? ",
                      linkLabel: 'Sign up',
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/sign-up'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
