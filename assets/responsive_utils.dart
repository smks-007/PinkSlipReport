// lib/core/utils/responsive_utils.dart
// ─────────────────────────────────────────────────────────────────────────────
// Centralized responsive helpers — zero-overhead BuildContext extension.
// Import this file anywhere you need screen-aware sizing/padding.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  // ── Screen dimensions ──────────────────────────────────────────────────────
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // ── Breakpoint booleans ────────────────────────────────────────────────────
  /// < 340 px  — ancient/very small phones (Galaxy Fold closed, etc.)
  bool get isUltraCompact => screenWidth < 340;

  /// < 360 px  — compact phones (iPhone SE 1st gen, older Androids)
  bool get isCompact => screenWidth < 360;

  /// < 400 px  — medium phones (iPhone 12 mini, Pixel 4a)
  bool get isMedium => screenWidth < 400;

  /// >= 400 px — standard/large modern phones
  bool get isLarge => screenWidth >= 400;

  // ── Adaptive spacing helpers ───────────────────────────────────────────────
  /// Horizontal screen padding that shrinks on narrow viewports.
  double get responsiveHorizontalPadding =>
      isUltraCompact ? 10.0 : isCompact ? 12.0 : isMedium ? 16.0 : 20.0;

  /// Adaptive vertical spacing for PIN pads, button rows, etc.
  double get responsiveVerticalSpacing =>
      isCompact ? 8.0 : isMedium ? 12.0 : 16.0;

  /// Tab / chip horizontal padding for segmented controls.
  double get tabHorizontalPadding => isCompact ? 6.0 : isMedium ? 8.0 : 10.0;

  // ── Keyboard / safe-area insets ────────────────────────────────────────────
  /// Current keyboard height (0 when keyboard is hidden).
  double get bottomInset => MediaQuery.viewInsetsOf(this).bottom;

  /// Bottom safe-area padding (notch / home bar).
  double get bottomSafeArea => MediaQuery.paddingOf(this).bottom;

  // ── Clamped proportional sizing ────────────────────────────────────────────
  /// Returns [fraction] of screen height, clamped between [min] and [max].
  ///
  /// Example: `context.clampedHeight(0.33, 190, 280)` on a 568 px screen → 187.4 → clamped to 190.
  double clampedHeight(double fraction, double min, double max) =>
      (screenHeight * fraction).clamp(min, max);

  /// Returns [fraction] of screen width, clamped between [min] and [max].
  double clampedWidth(double fraction, double min, double max) =>
      (screenWidth * fraction).clamp(min, max);

  // ── Dialog constraints ─────────────────────────────────────────────────────
  /// Safe dialog constraints: max 88 % of screen height, 95 % of screen width.
  /// Pass [maxWidth] to cap on tablets/wide phones.
  BoxConstraints dialogConstraints({double maxWidth = 580}) => BoxConstraints(
        maxHeight: screenHeight * 0.88,
        maxWidth: maxWidth.clamp(0.0, screenWidth * 0.95),
      );

  // ── Responsive font sizes ──────────────────────────────────────────────────
  /// Picks between [compact] and [normal] font size based on breakpoint.
  double responsiveFontSize({
    required double compact,
    required double normal,
    double? large,
  }) {
    if (isCompact) return compact;
    if (large != null && isLarge) return large;
    return normal;
  }

  // ── Layout decision helpers ────────────────────────────────────────────────
  /// Whether to use a 2-column grid instead of a 4-item row.
  /// Triggers at < 360 px — e.g. the HOD executive stats banner.
  bool get useGridLayout => screenWidth < 360;
}
