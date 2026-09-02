import 'package:flutter/material.dart';

/// Centralized color palette for PinkSlipReport.
/// Sky Blue & Cloud Storm theme with vibrant electric cyan accents.
class AppColors {
  AppColors._();

  // ──────────────────── Primary Sky Blue Palette ────────────────────
  static const Color primaryPurple = Color(0xFF0284C7); // Sky Blue 600
  static const Color primaryPurpleLight = Color(0xFF38BDF8); // Sky Blue 400
  static const Color primaryPurpleDark = Color(0xFF0369A1); // Sky Blue 700
  static const Color primaryPurpleDeep = Color(0xFF0C4A6E); // Sky Blue 900
  static const Color purpleAccent = Color(0xFF7DD3FC); // Sky Blue 300
  static const Color purpleSurface = Color(0xFFE0F2FE); // Sky Blue 100

  // ──────────────────── Gradients ────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0369A1), Color(0xFF38BDF8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient stormGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0284C7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient welcomeCardGradient = LinearGradient(
    colors: [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ──────────────────── Background & Surface ────────────────────
  static const Color pageBackground = Color(0xFFF0F9FF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8FAFC);

  // ──────────────────── Text Colors ────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPurple = Color(0xFFFFFFFF);

  // ──────────────────── Input Field ────────────────────
  static const Color inputBackground = Color(0xFFF0F9FF);
  static const Color inputBorder = Color(0xFFBAE6FD);
  static const Color inputFocusBorder = Color(0xFF0284C7);

  // ──────────────────── Status Colors ────────────────────
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusPendingBg = Color(0xFFFEF3C7);
  static const Color statusApproved = Color(0xFF10B981);
  static const Color statusApprovedBg = Color(0xFFD1FAE5);
  static const Color statusRejected = Color(0xFFEF4444);
  static const Color statusRejectedBg = Color(0xFFFEE2E2);
  static const Color statusForwarded = Color(0xFF0284C7);
  static const Color statusForwardedBg = Color(0xFFE0F2FE);

  // ──────────────────── Dashboard Stats ────────────────────
  static const Color attendanceBlue = Color(0xFF0284C7);
  static const Color absentRed = Color(0xFFEF4444);
  static const Color pendingOrange = Color(0xFFF59E0B);
  static const Color readyGreen = Color(0xFF10B981);

  // ──────────────────── Misc & Storm ────────────────────
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A0284C7);
  static const Color lightningColor = Color(0xFFFDE047);
  static const Color thunderGlow = Color(0xFF67E8F9);

  // ──────────────────── JARVIS Chatbot ────────────────────
  static const Color jarvisPrimary = Color(0xFF0284C7);
  static const Color jarvisAccent = Color(0xFF38BDF8);
  static const Color jarvisBubble = Color(0xFFE0F2FE);
  static const Color userBubble = Color(0xFF0284C7);
}
