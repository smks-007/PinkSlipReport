import 'package:flutter/material.dart';

/// Centralized responsive extensions on [BuildContext] for the PinkSlipReport app.
///
/// Provides fluid sizing, compact device detection, dynamic height clamping,
/// safe dialog constraints, and typography scaling without third-party dependencies.
extension ResponsiveContext on BuildContext {
  /// The current screen size using high-performance MediaQuery.sizeOf.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Current device screen width.
  double get screenWidth => screenSize.width;

  /// Current device screen height.
  double get screenHeight => screenSize.height;

  /// Ultra-compact devices (e.g. screen width < 340 px, such as older smartwatches/foldables).
  bool get isUltraCompact => screenWidth < 340;

  /// Compact devices (e.g. screen width < 360 px, such as iPhone SE 1st gen).
  bool get isCompact => screenWidth < 360;

  /// Medium compact devices (e.g. screen width < 400 px, budget Androids, iPhone mini).
  bool get isMedium => screenWidth < 400;

  /// Responsive horizontal page padding: 12 on compact, 16 on medium, 20 on standard/large.
  double get responsiveHorizontalPadding =>
      isCompact ? 12.0 : (isMedium ? 16.0 : 20.0);

  /// Current bottom inset (e.g., virtual keyboard height).
  double get bottomInset => MediaQuery.viewInsetsOf(this).bottom;

  /// Dynamically clamps a height based on a fraction of the screen height.
  double clampedHeight(double fraction, double min, double max) =>
      (screenHeight * fraction).clamp(min, max);

  /// Safe responsive dialog constraints preventing vertical clipping on short devices.
  BoxConstraints dialogConstraints({double maxWidth = 580, double? maxHeight}) => BoxConstraints(
        maxHeight: maxHeight != null
            ? maxHeight.clamp(0.0, screenHeight * 0.88)
            : screenHeight * 0.88,
        maxWidth: maxWidth.clamp(0.0, screenWidth * 0.95),
      );

  /// Returns a responsive font size based on whether the device is compact.
  double responsiveFontSize({required double compact, required double normal}) =>
      isCompact ? compact : normal;
}
