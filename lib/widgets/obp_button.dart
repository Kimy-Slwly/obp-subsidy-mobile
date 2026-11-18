import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../core/constants/app_typography.dart';

enum ObpButtonVariant {
  primary,
  secondary,
  accent,
  outline,
}

class ObpButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ObpButtonVariant variant;
  final bool isLoading;
  final double? height;
  final double? width;

  const ObpButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = ObpButtonVariant.primary,
    this.isLoading = false,
    this.height = AppDimensions.buttonHeight,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case ObpButtonVariant.primary:
        bg = AppColors.primaryContainer;
        fg = Colors.white;
        break;
      case ObpButtonVariant.secondary:
        bg = AppColors.surfaceContainerHigh;
        fg = AppColors.textPrimary;
        border = const BorderSide(color: AppColors.surfaceBorder, width: 1.0);
        break;
      case ObpButtonVariant.accent:
        bg = AppColors.secondaryContainer;
        fg = const Color(0xFF231B00);
        break;
      case ObpButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.textPrimary;
        border = const BorderSide(color: AppColors.surfaceBorder, width: 1.2);
        break;
    }

    final isInteractive = onPressed != null && !isLoading;

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: Material(
        color: isInteractive ? bg : bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: InkWell(
          onTap: isInteractive ? onPressed : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.fromBorderSide(border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 22.0,
                    height: 22.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20.0, color: fg),
                        const SizedBox(width: 8.0),
                      ],
                      Text(
                        label,
                        style: AppTypography.labelLg.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
