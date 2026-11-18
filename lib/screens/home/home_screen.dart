import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../widgets/obp_button.dart';
import '../../widgets/obp_card.dart';
import '../../widgets/obp_pulse_dot.dart';
import '../../widgets/obp_status_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final driver = appState.driver;
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
                // Top Header: Greeting, Meta & Bell
                _buildHeader(context, appState, driver),
                const SizedBox(height: AppDimensions.lg),

                // Primary Fuel Quota Card (SKDS 2.0)
                _buildQuotaCard(quota),
                const SizedBox(height: AppDimensions.md),

                // Quick Fuel Claim CTA Banner
                _buildQuickClaimBanner(context),
                const SizedBox(height: AppDimensions.md),

                // Operational Diagnostics / Field Snapshot
                _buildFieldDiagnostics(context),
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

  Widget _buildHeader(BuildContext context, AppState appState, dynamic driver) {
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
                  Text(
                    'Shift Active • ${driver.depot}',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.statusSuccess,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Text(
                'Hello, ${driver.name.split(' ').first}',
                style: AppTypography.headlineLg,
              ),
              const SizedBox(height: 2.0),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
                    ),
                    child: Text(
                      driver.lorryPlate,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.secondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      driver.lorryModel,
                      style: AppTypography.bodySm.copyWith(fontSize: 12.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            // Notifications Icon with badge
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
            // Profile Avatar Quick Tap
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

  Widget _buildQuotaCard(dynamic quota) {
    final percentRemaining = (quota.percentageRemaining / 100.0).clamp(0.0, 1.0);

    return ObpCard(
      accentColor: AppColors.secondaryContainer,
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const Text(
                    'SKDS 2.0 Diesel Quota',
                    style: AppTypography.labelMd,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(9999.0),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  'Resets in ${quota.resetDaysRemaining}d',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11.0,
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
                quota.currentBalance.toStringAsFixed(0),
                style: AppTypography.numericDisplay.copyWith(
                  color: AppColors.secondaryContainer,
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                '/ ${quota.monthlyLimit.toStringAsFixed(0)} Liters',
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

          // Subsidized Rate vs Market Rate breakdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_outlined, size: 14.0, color: AppColors.statusSuccess),
                    const SizedBox(width: 4.0),
                    Text(
                      'Subsidized RM${quota.subsidizedRate.toStringAsFixed(2)}/L',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Market: RM${quota.marketRate.toStringAsFixed(2)}/L',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
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
                        'Scan Odometer • GPS Check • Snap Receipt',
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

  Widget _buildFieldDiagnostics(BuildContext context) {
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
                const Text(
                  '248,650 KM',
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
