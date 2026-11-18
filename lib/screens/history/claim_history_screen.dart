import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/state/app_state.dart';
import '../../models/fuel_claim_model.dart';
import '../../widgets/obp_card.dart';
import '../../widgets/obp_status_badge.dart';

class ClaimHistoryScreen extends StatefulWidget {
  const ClaimHistoryScreen({super.key});

  @override
  State<ClaimHistoryScreen> createState() => _ClaimHistoryScreenState();
}

class _ClaimHistoryScreenState extends State<ClaimHistoryScreen> {
  int _selectedMonthIndex = 0;
  final List<String> _months = const ['October 2026', 'September', 'August'];

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final claims = appState.claims;

    // Calculate totals
    final totalLiters = claims.fold<double>(0.0, (acc, c) => acc + c.liters);
    final totalSpend = claims.fold<double>(0.0, (acc, c) => acc + c.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Claim History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter Claims',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter settings: showing all fuel stations.')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenMargin,
            vertical: AppDimensions.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Operational Fleet Header & Quick Stats
              _buildStatsSummary(totalLiters, totalSpend, claims.length),
              const SizedBox(height: AppDimensions.md),

              // Filter & Timeframe Segment
              _buildMonthSelector(),
              const SizedBox(height: AppDimensions.md),

              // Claims List Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('All Logged Claims', style: AppTypography.headlineMd),
                  Text(
                    '${claims.length} records',
                    style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),

              // Claims List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: claims.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: AppDimensions.sm),
                itemBuilder: (ctx, i) {
                  final claim = claims[i];
                  return _buildClaimItemCard(claim);
                },
              ),
              const SizedBox(height: AppDimensions.lg),

              // End of list audit notice
              _buildAuditNotice(),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(double totalLiters, double totalSpend, int count) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Volume', style: AppTypography.labelSm),
                    const SizedBox(height: 2.0),
                    Text(
                      '${totalLiters.toStringAsFixed(1)} L',
                      style: AppTypography.headlineLg.copyWith(
                        color: AppColors.secondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1.0, height: 38.0, color: AppColors.divider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Value', style: AppTypography.labelSm),
                      const SizedBox(height: 2.0),
                      Text(
                        'RM ${totalSpend.toStringAsFixed(2)}',
                        style: AppTypography.headlineLg.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SKDS Subsidized Diesel (Euro 5 B10)',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
                Text(
                  '$count Logged',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.statusSuccess,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return SizedBox(
      height: 38.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8.0),
        itemBuilder: (ctx, i) {
          final isSelected = i == _selectedMonthIndex;
          return Material(
            color: isSelected ? AppColors.secondaryContainer : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(9999.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(9999.0),
              onTap: () => setState(() => _selectedMonthIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999.0),
                  border: Border.all(
                    color: isSelected ? AppColors.secondaryContainer : AppColors.surfaceBorder,
                  ),
                ),
                child: Row(
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.calendar_month_rounded, size: 14.0, color: Color(0xFF231B00)),
                      const SizedBox(width: 6.0),
                    ],
                    Text(
                      _months[i],
                      style: AppTypography.labelSm.copyWith(
                        color: isSelected ? const Color(0xFF231B00) : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClaimItemCard(FuelClaimModel claim) {
    return ObpCard(
      onTap: () => _showClaimDetailsDialog(claim),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  claim.stationName,
                  style: AppTypography.labelMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              ObpStatusBadge.fromClaimStatus(claim.status),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            claim.date,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.sm),
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Volume Pumped', style: AppTypography.caption),
                    Text(
                      '${claim.liters.toStringAsFixed(1)} L',
                      style: AppTypography.labelMd.copyWith(color: AppColors.secondaryContainer),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total (Subsidized)', style: AppTypography.caption),
                    Text(
                      'RM ${claim.totalAmount.toStringAsFixed(2)}',
                      style: AppTypography.labelMd,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Odometer', style: AppTypography.caption),
                    Text(
                      '${claim.odometerKm} KM',
                      style: AppTypography.labelMd,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6.0),
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 12.0, color: AppColors.statusSuccess),
              const SizedBox(width: 4.0),
              Text(
                'GPS Geofence Match • Receipt Uploaded',
                style: AppTypography.caption.copyWith(color: AppColors.textHint, fontSize: 10.0),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, size: 16.0, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }

  void _showClaimDetailsDialog(FuelClaimModel claim) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(claim.id, style: AppTypography.headlineMd),
            ObpStatusBadge.fromClaimStatus(claim.status),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Station: ${claim.stationName}', style: AppTypography.bodyMd),
            const SizedBox(height: 4.0),
            Text('Date: ${claim.date}', style: AppTypography.bodySm),
            const SizedBox(height: 4.0),
            Text('Lorry Plate: ${claim.lorryPlate}', style: AppTypography.bodySm),
            const Divider(height: 24.0, color: AppColors.divider),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pumped:', style: AppTypography.bodySm),
                Text('${claim.liters.toStringAsFixed(1)} L @ RM${claim.ratePerLiter.toStringAsFixed(2)}', style: AppTypography.labelMd),
              ],
            ),
            const SizedBox(height: 4.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Subsidized:', style: AppTypography.bodySm),
                Text('RM ${claim.totalAmount.toStringAsFixed(2)}', style: AppTypography.headlineMd.copyWith(color: AppColors.secondaryContainer)),
              ],
            ),
            const SizedBox(height: 4.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Odometer Logged:', style: AppTypography.bodySm),
                Text('${claim.odometerKm} KM', style: AppTypography.labelMd),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditNotice() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_done_outlined, size: 14.0, color: AppColors.textHint),
          const SizedBox(width: 6.0),
          Text(
            'All claims cryptographically logged to OBP Fleet Audit Cloud.',
            style: AppTypography.caption.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
