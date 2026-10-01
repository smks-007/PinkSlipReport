import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await SupabaseService().updatePassword(_password.text);
      if (!mounted) return;
      AuthService().completeRecoverySession();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated. Please sign in again.'),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (_) => false);
    } on AuthException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showError(
          'Could not update the password. Try the recovery link again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Set new password')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Choose a new password',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.length < 8
                      ? 'Use at least 8 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                  validator: (value) =>
                      value != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _update,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Update password'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
