import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static const TextStyle numericDisplay = TextStyle(
    fontSize: 36.0,
    height: 44.0 / 36.0,
    letterSpacing: 0.02,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineXl = TextStyle(
    fontSize: 32.0,
    height: 40.0 / 32.0,
    letterSpacing: -0.02,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLg = TextStyle(
    fontSize: 24.0,
    height: 32.0 / 24.0,
    letterSpacing: -0.01,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMd = TextStyle(
    fontSize: 20.0,
    height: 28.0 / 20.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelLg = TextStyle(
    fontSize: 16.0,
    height: 22.0 / 16.0,
    letterSpacing: 0.01,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 14.0,
    height: 18.0 / 14.0,
    letterSpacing: 0.02,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 12.0,
    height: 16.0 / 12.0,
    letterSpacing: 0.04,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 18.0,
    height: 26.0 / 18.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 16.0,
    height: 24.0 / 16.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 14.0,
    height: 20.0 / 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.0,
    height: 14.0 / 11.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );
}
