import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';

class ObpCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Border? border;

  const ObpCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.md),
    this.accentColor,
    this.backgroundColor = AppColors.surfaceCard,
    this.onTap,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppDimensions.radiusLg);

    Widget content = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: border ?? Border.all(color: AppColors.surfaceBorder, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            if (accentColor != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3.5,
                child: Container(color: accentColor),
              ),
            Padding(
              padding: accentColor != null
                  ? EdgeInsets.only(
                      top: (padding as EdgeInsets).top + 2.0,
                      bottom: (padding as EdgeInsets).bottom,
                      left: (padding as EdgeInsets).left,
                      right: (padding as EdgeInsets).right,
                    )
                  : padding,
              child: child,
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return content;
  }
}
