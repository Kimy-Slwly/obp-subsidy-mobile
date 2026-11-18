import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../models/fuel_claim_model.dart';

class ObpStatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const ObpStatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory ObpStatusBadge.fromClaimStatus(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.approved:
        return const ObpStatusBadge(
          label: 'Approved',
          backgroundColor: Color(0x2210B981),
          textColor: AppColors.statusSuccess,
          icon: Icons.check_circle_rounded,
        );
      case ClaimStatus.pending:
        return const ObpStatusBadge(
          label: 'Pending',
          backgroundColor: Color(0x22F59E0B),
          textColor: AppColors.statusWarning,
          icon: Icons.schedule_rounded,
        );
      case ClaimStatus.rejected:
        return const ObpStatusBadge(
          label: 'Rejected',
          backgroundColor: Color(0x22EF4444),
          textColor: AppColors.statusError,
          icon: Icons.cancel_rounded,
        );
    }
  }

  factory ObpStatusBadge.verified({String label = 'Verified'}) {
    return ObpStatusBadge(
      label: label,
      backgroundColor: const Color(0x2210B981),
      textColor: AppColors.statusSuccess,
      icon: Icons.verified_rounded,
    );
  }

  factory ObpStatusBadge.warning({required String label}) {
    return ObpStatusBadge(
      label: label,
      backgroundColor: const Color(0x22F59E0B),
      textColor: AppColors.statusWarning,
      icon: Icons.warning_amber_rounded,
    );
  }

  factory ObpStatusBadge.neutral({required String label, IconData? icon}) {
    return ObpStatusBadge(
      label: label,
      backgroundColor: AppColors.surfaceContainerHigh,
      textColor: AppColors.textSecondary,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9999.0),
        border: Border.all(
          color: textColor.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14.0, color: textColor),
            const SizedBox(width: 4.0),
          ],
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
