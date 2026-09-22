// lib/auth/screens/sign_in_screen.dart  — RESPONSIVE PATCHES
// ─────────────────────────────────────────────────────────────────────────────
// Apply these targeted changes to your existing sign_in_screen.dart.
// Only layout-related lines change; all colors/branding/logic stay the same.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FIX 1 — Header height: replace hardcoded `height: 290` with this widget.
// ══════════════════════════════════════════════════════════════════════════════

class _SignInHeader extends StatelessWidget {
  const _SignInHeader();

  @override
  Widget build(BuildContext context) {
    // BEFORE: SizedBox(height: 290, child: Stack(...))
    // AFTER:  Height is 33 % of screen, clamped so it never goes below
    //         190 px (very short phones) or above 280 px (tall phones).
    return SizedBox(
      height: context.clampedHeight(0.33, 190.0, 280.0),  // ← KEY CHANGE
      child: Stack(
        clipBehavior: Clip.hardEdge,     // prevents cloud icons escaping
        children: [
          // ── your existing gradient/background widget ──
          const _HeaderBackground(),

          // ── cloud icons: position them proportionally ──
          Positioned(
            top: context.clampedHeight(0.33, 190.0, 280.0) * 0.15,
            left: context.screenWidth * 0.05,
            child: const _CloudIcon(size: 40),
          ),
          Positioned(
            top: context.clampedHeight(0.33, 190.0, 280.0) * 0.30,
            right: context.screenWidth * 0.08,
            child: const _CloudIcon(size: 32),
          ),

          // ── branding / logo centered ──
          const Center(child: _HeaderBranding()),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 2 — Sign-in button: replace `height: 52` with min-height constraints.
// ══════════════════════════════════════════════════════════════════════════════

class _SignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const _SignInButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    // BEFORE: SizedBox(height: 52, width: double.infinity, child: ElevatedButton(...))
    // AFTER:  Constraints-based so the button grows with text scale but won't
    //         shrink below 48 px (Material touch-target minimum).
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          // REMOVED: fixedSize: Size.fromHeight(52)
          padding: const EdgeInsets.symmetric(vertical: 14),   // ← breathing room
          minimumSize: const Size(double.infinity, 48),        // ← min touch target
        ),
        child: Text(label),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FIX 3 — Connection-status badge & security footer: prevent overflow.
// ══════════════════════════════════════════════════════════════════════════════

class _StatusBadgeRow extends StatelessWidget {
  final String statusText;
  final String footerText;

  const _StatusBadgeRow({required this.statusText, required this.footerText});

  @override
  Widget build(BuildContext context) {
    // BEFORE: Row(children: [Icon(...), Text(statusText), Spacer(), Text(footerText)])
    // AFTER:  Both text nodes wrapped in Flexible so they ellipsize instead of overflow.
    return Row(
      children: [
        const Icon(Icons.circle, size: 8, color: Colors.green),
        const SizedBox(width: 6),
        Flexible(                                               // ← ADDED
          child: Text(
            statusText,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const Spacer(),
        Flexible(                                               // ← ADDED
          child: Text(
            footerText,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder stubs — these already exist in your codebase; listed here only
// so this snippet compiles in isolation.
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();
  @override Widget build(BuildContext context) => const SizedBox.expand();
}

class _HeaderBranding extends StatelessWidget {
  const _HeaderBranding();
  @override Widget build(BuildContext context) => const SizedBox.shrink();
}

class _CloudIcon extends StatelessWidget {
  final double size;
  const _CloudIcon({required this.size});
  @override Widget build(BuildContext context) => Icon(Icons.cloud, size: size);
}
