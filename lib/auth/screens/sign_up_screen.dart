import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_illustration.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/auth_link_text.dart';
import '../widgets/auth_primary_button.dart';

/// Sign-Up screen — recreates the center card from the reference image.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.register});

  final Future<bool> Function({
    required String fullName,
    required String email,
    required String password,
  })?
  register;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final needsConfirmation =
          await (widget.register ?? SupabaseService().registerStudent)(
            fullName: _nameCtrl.text,
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );
      if (!mounted) return;
      _passwordCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            needsConfirmation
                ? 'Check your email for confirmation instructions, then sign in. If you already have an account, sign in or reset your password.'
                : 'Registration complete. Sign in to continue.',
          ),
        ),
      );
      Navigator.pushReplacementNamed(context, '/sign-in');
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not register. Please check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    const SignUpIllustration(height: 150),
                    const SizedBox(height: 16),

                    // ── Heading ──────────────────────────────
                    const Text('Sign Up', style: AuthTheme.heading),
                    const SizedBox(height: 8),
                    const Text(
                      'Use proper information to continue',
                      style: AuthTheme.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // ── Full Name ─────────────────────────────
                    AuthInputField(
                      hintText: 'Full name',
                      prefixIcon: Icons.person_outline_rounded,
                      controller: _nameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: AuthTheme.fieldSpacing),

                    // ── Email ─────────────────────────────────
                    AuthInputField(
                      hintText: 'Email address',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailCtrl,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AuthTheme.fieldSpacing),

                    // ── Password ──────────────────────────────
                    AuthInputField(
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      controller: _passwordCtrl,
                      textInputAction: TextInputAction.done,
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Password must be at least 8 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Terms & Privacy ───────────────────────
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AuthTheme.bodyText.copyWith(fontSize: 13),
                        children: [
                          const TextSpan(
                            text: 'By signing up, you are agree to our ',
                          ),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: AuthTheme.linkText.copyWith(fontSize: 13),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // TODO: Open Terms
                              },
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: AuthTheme.linkText.copyWith(fontSize: 13),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // TODO: Open Privacy Policy
                              },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Create Account Button ────────────────
                    AuthPrimaryButton(
                      label: 'Create Account',
                      isLoading: _isLoading,
                      onPressed: _handleSignUp,
                    ),
                    const SizedBox(height: 28),

                    // ── Sign In Link ─────────────────────────
                    AuthLinkText(
                      prefix: 'Already have an Account? ',
                      linkLabel: 'Sign in',
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/sign-in'),
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
