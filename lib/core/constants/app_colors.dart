import 'package:flutter/material.dart';

/// Design tokens and semantic colors extracted from Stitch specifications & OBP brand guidelines.
abstract final class AppColors {
  // Backgrounds & Surfaces (Deep Slate & Dark Blue-Gray)
  static const Color background = Color(0xFF0B1326); // #0B1326
  static const Color surface = Color(0xFF0B1326);
  static const Color surfaceContainerLowest = Color(0xFF060E20);
  static const Color surfaceContainerLow = Color(0xFF131B2E);
  static const Color surfaceContainer = Color(0xFF171F33);
  static const Color surfaceContainerHigh = Color(0xFF222A3D);
  static const Color surfaceContainerHighest = Color(0xFF2D3449);
  static const Color surfaceCard = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFF334155);

  // Brand Accents
  static const Color primary = Color(0xFFFFB3B1);
  static const Color primaryContainer = Color(0xFFE31837); // Shell Red
  static const Color onPrimary = Color(0xFF680011);
  static const Color onPrimaryContainer = Color(0xFFFFFAF9);

  static const Color secondary = Color(0xFFFFEAAD);
  static const Color secondaryContainer = Color(0xFFF7CA00); // Shell Yellow / Warning
  static const Color onSecondaryContainer = Color(0xFF6A5600);

  static const Color tertiary = Color(0xFF4EDEA3); // Emerald Green / Success
  static const Color tertiaryContainer = Color(0xFF00845A);
  static const Color onTertiary = Color(0xFF003824);

  // Status Colors
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusError = Color(0xFFEF4444);
  static const Color statusInfo = Color(0xFF3B82F6);

  // Typography & Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFDAE2FD);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFF64748B);

  // Dividers & Outlines
  static const Color outline = Color(0xFFAD8886);
  static const Color outlineVariant = Color(0xFF5D3F3E);
  static const Color divider = Color(0xFF283044);
}
