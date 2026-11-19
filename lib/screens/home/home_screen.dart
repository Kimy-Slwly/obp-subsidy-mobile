import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../widgets/obp_card.dart';
import '../../widgets/obp_pulse_dot.dart';
import '../../widgets/obp_status_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final user = appState.user;
    final vehicle = appState.assignedVehicle;
    final quota = appState.quota;
    final latestClaim = appState.claims.isNotEmpty ? appState.claims.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryContainer,
          backgroundColor: AppColors.surfaceCard,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenMargin,
              vertical: AppDimensions.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Greeting, Shift Status & Bell
                _buildHeader(context, appState, user, vehicle),
                const SizedBox(height: AppDimensions.md),

                // Assigned Lorry Specification Card (Read-only from Firestore)
                _buildAssignedVehicleCard(vehicle),
                const SizedBox(height: AppDimensions.md),

                // Primary SKDS Quota Gauge Card
                _buildQuotaCard(vehicle, quota),
                const SizedBox(height: AppDimensions.md),

                // Quick Fuel Claim CTA Banner
                _buildQuickClaimBanner(context),
                const SizedBox(height: AppDimensions.md),

                // Operational Diagnostics / Field Snapshot
                _buildFieldDiagnostics(context, vehicle),
                const SizedBox(height: AppDimensions.lg),

                // Recent Claim Activity Row
                _buildRecentActivity(context, latestClaim, appState),
                const SizedBox(height: AppDimensions.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppState appState,
    dynamic user,
    dynamic vehicle,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ObpPulseDot(color: AppColors.statusSuccess, size: 8.0),
                  const SizedBox(width: 6.0),
                  Flexible(
                    child: Text(
                      'Shift Active • ${vehicle.depot}',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.statusSuccess,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Text(
                'Hello, ${user.displayName.split(' ').first}',
                style: AppTypography.headlineLg,
              ),
              const SizedBox(height: 2.0),
              Text(
                'Driver ID: ${user.driverId} • Ong Brothers Petroleum',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Row(
          children: [
            // Notifications Icon with live unread badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      side: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
                ),
                if (appState.unreadNotificationCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16.0, minHeight: 16.0),
                      alignment: Alignment.center,
                      child: Text(
                        '${appState.unreadNotificationCount}',
                        style: const TextStyle(
                          fontSize: 9.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8.0),
            // Driver Avatar Quick Tap
            GestureDetector(
              onTap: () => appState.setNavigationIndex(3),
              child: Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'AR',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignedVehicleCard(dynamic vehicle) {
    return ObpCard(
      accentColor: AppColors.primaryContainer,
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: AppColors.secondaryContainer, size: 20.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Assigned Delivery Lorry',
                  style: AppTypography.labelMd.copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              ObpStatusBadge.verified(
                label: vehicle.status.toString().toUpperCase(),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.plateNumber,
                        style: AppTypography.headlineMd.copyWith(
                          color: AppColors.secondaryContainer,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        vehicle.model,
                        style: AppTypography.bodySm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Odometer Meter',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '${vehicle.currentOdometer} KM',
                      style: AppTypography.labelMd.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaCard(dynamic vehicle, dynamic quota) {
    final remaining = vehicle.remainingQuota;
    final limit = vehicle.monthlyQuotaLimit;
    final used = vehicle.currentQuotaUsage;
    final percentRemaining = (remaining / limit).clamp(0.0, 1.0);

    return ObpCard(
      accentColor: AppColors.secondaryContainer,
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: AppColors.secondaryContainer,
                  size: 18.0,
                ),
              ),
              const SizedBox(width: 8.0),
              const Expanded(
                child: Text(
                  'SKDS 2.0 Diesel Allowance',
                  style: AppTypography.labelMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(9999.0),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  'Pool 5,400 L / 4 Lorries',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),

          // Big Meter Number
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                remaining.toStringAsFixed(0),
                style: AppTypography.numericDisplay.copyWith(
                  color: AppColors.secondaryContainer,
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                '/ ${limit.toStringAsFixed(0)} L',
                style: AppTypography.headlineMd.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${(percentRemaining * 100).toStringAsFixed(0)}% Left',
                style: AppTypography.labelMd.copyWith(
                  color: percentRemaining < 0.25 ? AppColors.statusError : AppColors.statusSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(9999.0),
            child: SizedBox(
              height: 10.0,
              child: LinearProgressIndicator(
                value: percentRemaining,
                backgroundColor: AppColors.surfaceContainerLowest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentRemaining < 0.25
                      ? AppColors.statusError
                      : AppColors.secondaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Usage & Subsidized Rate Breakdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Used this month: ${used.toStringAsFixed(1)} L',
                    style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_outlined, size: 14.0, color: AppColors.statusSuccess),
                    const SizedBox(width: 4.0),
                    Text(
                      'Subsidized RM${quota.subsidizedRate.toStringAsFixed(2)}/L',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.statusSuccess,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickClaimBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0E23), AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.25),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.newClaim),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 32.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit Fuel Claim',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.0),
                      Text(
                        'OCR Odometer • GPS Geofence • Shell Receipt',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Color(0xFFFFDAD8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18.0,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldDiagnostics(BuildContext context, dynamic vehicle) {
    return Row(
      children: [
        // Nearest Shell Station
        Expanded(
          child: ObpCard(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Icon(Icons.near_me_rounded, color: AppColors.tertiary, size: 16.0),
                    ),
                    const ObpPulseDot(color: AppColors.tertiary, size: 6.0),
                  ],
                ),
                const SizedBox(height: AppDimensions.sm),
                const Text('Nearest Pump', style: AppTypography.labelSm),
                const SizedBox(height: 2.0),
                const Text(
                  'Shell Pasir Gudang',
                  style: AppTypography.labelMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2.0),
                Text(
                  '1.2 km • Geofence Ready',
                  style: AppTypography.caption.copyWith(color: AppColors.statusSuccess),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.md),

        // Last Odometer
        Expanded(
          child: ObpCard(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Icon(Icons.speed_rounded, color: AppColors.secondaryContainer, size: 16.0),
                    ),
                    Text(
                      'Verified',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.statusSuccess,
                        fontSize: 10.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.sm),
                const Text('Last Odometer', style: AppTypography.labelSm),
                const SizedBox(height: 2.0),
                Text(
                  '${vehicle.currentOdometer} KM',
                  style: AppTypography.labelMd,
                ),
                const SizedBox(height: 2.0),
                Text(
                  'OCR Match 99.8%',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, dynamic latestClaim, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Fleet Activity', style: AppTypography.headlineMd),
            TextButton(
              onPressed: () => appState.setNavigationIndex(1),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.secondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2.0),
                  const Icon(Icons.arrow_forward_rounded, size: 14.0, color: AppColors.secondaryContainer),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.xs),
        if (latestClaim != null)
          ObpCard(
            onTap: () => appState.setNavigationIndex(1),
            child: Row(
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.textPrimary,
                    size: 22.0,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestClaim.stationName,
                        style: AppTypography.labelMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${latestClaim.liters.toStringAsFixed(1)} L • RM ${latestClaim.totalAmount.toStringAsFixed(2)}',
                        style: AppTypography.bodySm,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                ObpStatusBadge.fromClaimStatus(latestClaim.status),
              ],
            ),
          )
        else
          ObpCard(
            child: Center(
              child: Text(
                'No claims submitted yet today',
                style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
      ],
    );
  }
}
