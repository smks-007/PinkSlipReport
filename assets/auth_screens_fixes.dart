// lib/auth/screens/  — Forgot Password + Security Verification PATCHES
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FIX 4 — forgot_password_screen.dart
// Header: replace rigid SizedBox(width: 44) spacers with Expanded branding.
// Badge: make 'FACULTY CREDENTIAL RECOVERY' text responsive + ellipsis.
// ══════════════════════════════════════════════════════════════════════════════

class ForgotPasswordHeader extends StatelessWidget {
  final VoidCallback onBack;

  const ForgotPasswordHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button — fixed, always 44 px
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: onBack,
          ),
        ),

        // BEFORE: SizedBox(width: 44) [spacer] + Text(title) + SizedBox(width: 44) [spacer]
        // AFTER:  Expanded wraps branding so it centers naturally regardless of width.
        Expanded(                                               // ← KEY CHANGE
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CREDENTIAL RECOVERY',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(
                    compact: 13.0,
                    normal: 15.0,
                  ),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,               // ← ADDED
                maxLines: 1,                                   // ← ADDED
              ),
              const SizedBox(height: 4),
              _FacultyBadge(),
            ],
          ),
        ),

        // Mirror spacer on right so branding stays truly centered.
        const SizedBox(width: 44),
      ],
    );
  }
}

class _FacultyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // BEFORE: Container(child: Text('FACULTY CREDENTIAL RECOVERY'))
    // AFTER:  Flexible + responsive font + ellipsis
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.isCompact ? 8 : 12,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.shade200),
      ),
      child: Text(
        'FACULTY CREDENTIAL RECOVERY',
        style: TextStyle(
          fontSize: context.responsiveFontSize(   // ← CHANGED from hardcoded 11
            compact: 9.5,
            normal: 11.0,
          ),
          letterSpacing: 0.5,
        ),
        overflow: TextOverflow.ellipsis,          // ← ADDED
        maxLines: 1,                              // ← ADDED
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 5 — security_verification_screen.dart
// Wrap body in SafeArea + SingleChildScrollView to prevent PIN pad clipping
// on 320×568 devices, and make PIN pad spacing responsive.
// ══════════════════════════════════════════════════════════════════════════════

class SecurityVerificationScreen extends StatefulWidget {
  const SecurityVerificationScreen({super.key});

  @override
  State<SecurityVerificationScreen> createState() =>
      _SecurityVerificationScreenState();
}

class _SecurityVerificationScreenState
    extends State<SecurityVerificationScreen> {
  final List<int?> _pin = [null, null, null, null, null, null];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BEFORE: body: Column(children: [...])
      // AFTER:  SafeArea + SingleChildScrollView so PIN pad is reachable
      //         when the phone is very short (568 px) with a notch.
      body: SafeArea(                                          // ← ADDED
        child: SingleChildScrollView(                         // ← ADDED
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            // Ensures the column fills the viewport but can scroll beyond it.
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).top -
                  MediaQuery.paddingOf(context).bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildPinDots(context),
                  _buildNumericPad(context),
                  _buildSubmitButton(context),
                  SizedBox(height: context.responsiveVerticalSpacing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.responsiveHorizontalPadding),
      child: const Text('Enter your PIN',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPinDots(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.responsiveVerticalSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          6,
          (i) => Container(
            // BEFORE: margin: EdgeInsets.all(8)  — clips on 568 px height
            // AFTER:  responsive margin
            margin: EdgeInsets.symmetric(
              horizontal: context.isCompact ? 5 : 8,           // ← CHANGED
            ),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _pin[i] != null ? Colors.pink : Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericPad(BuildContext context) {
    // BEFORE: GridView with hardcoded childAspectRatio and fixed spacing
    // AFTER:  Explicit Row/Column grid with responsive spacing
    final spacing = context.isCompact ? 8.0 : 12.0;           // ← KEY CHANGE
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.screenWidth * 0.12,
      ),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) => _PinKey(label: key)).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveHorizontalPadding,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('VERIFY'),
        ),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  const _PinKey({required this.label});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: label.isEmpty
          ? const SizedBox.shrink()
          : TextButton(
              onPressed: () {},
              child: Text(label, style: const TextStyle(fontSize: 22)),
            ),
    );
  }
}
