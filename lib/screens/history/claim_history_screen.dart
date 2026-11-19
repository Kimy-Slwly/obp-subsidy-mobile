import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/state/app_state.dart';
import '../../models/fuel_claim_model.dart';
import '../../widgets/obp_button.dart';
import '../../widgets/obp_card.dart';
import '../../widgets/obp_status_badge.dart';

class MonthFilterOption {
  final String label;
  final int? year;
  final int? month;

  const MonthFilterOption({
    required this.label,
    this.year,
    this.month,
  });

  bool get isAll => year == null || month == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthFilterOption &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => label.hashCode ^ year.hashCode ^ month.hashCode;
}

class ClaimHistoryScreen extends StatefulWidget {
  const ClaimHistoryScreen({super.key});

  @override
  State<ClaimHistoryScreen> createState() => _ClaimHistoryScreenState();
}

class _ClaimHistoryScreenState extends State<ClaimHistoryScreen> {
  late final List<MonthFilterOption> _monthOptions;
  late MonthFilterOption _selectedMonth;
  ClaimStatus? _selectedStatus; // null means "All Statuses"

  @override
  void initState() {
    super.initState();
    _initMonthOptions();
  }

  void _initMonthOptions() {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final now = DateTime.now();
    _monthOptions = [
      const MonthFilterOption(label: 'All'),
    ];

    // Generate last 4 months dynamically starting from the current month
    for (int i = 0; i < 4; i++) {
      int y = now.year;
      int m = now.month - i;
      while (m <= 0) {
        m += 12;
        y -= 1;
      }
      _monthOptions.add(MonthFilterOption(
        label: '${monthNames[m - 1]} $y',
        year: y,
        month: m,
      ));
    }

    // Default to the current month (index 1)
    _selectedMonth = _monthOptions[1];
  }

  void _showFilterBottomSheet() {
    ClaimStatus? tempStatus = _selectedStatus;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenMargin,
                  vertical: AppDimensions.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBorder,
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filter by Status', style: AppTypography.headlineMd),
                        if (tempStatus != null)
                          TextButton(
                            onPressed: () {
                              setModalState(() => tempStatus = null);
                            },
                            child: Text(
                              'Reset',
                              style: AppTypography.labelSm.copyWith(color: AppColors.statusError),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      'Showing claims for ${_selectedMonth.label}. Filter by approval state:',
                      style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    _buildStatusFilterOption(
                      title: 'All Statuses',
                      subtitle: 'Show approved, pending, and rejected claims',
                      icon: Icons.all_inclusive_rounded,
                      color: AppColors.textPrimary,
                      isSelected: tempStatus == null,
                      onTap: () => setModalState(() => tempStatus = null),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    _buildStatusFilterOption(
                      title: 'Approved',
                      subtitle: 'Approved & credited to subsidized diesel balance',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.statusSuccess,
                      isSelected: tempStatus == ClaimStatus.approved,
                      onTap: () => setModalState(() => tempStatus = ClaimStatus.approved),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    _buildStatusFilterOption(
                      title: 'Pending Review',
                      subtitle: 'Waiting for manager verification on web dashboard',
                      icon: Icons.schedule_rounded,
                      color: AppColors.secondaryContainer,
                      isSelected: tempStatus == ClaimStatus.pending,
                      onTap: () => setModalState(() => tempStatus = ClaimStatus.pending),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    _buildStatusFilterOption(
                      title: 'Rejected',
                      subtitle: 'Requires receipt re-upload or clarification',
                      icon: Icons.cancel_rounded,
                      color: AppColors.statusError,
                      isSelected: tempStatus == ClaimStatus.rejected,
                      onTap: () => setModalState(() => tempStatus = ClaimStatus.rejected),
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    ObpButton(
                      label: 'Apply Filter',
                      icon: Icons.done_rounded,
                      onPressed: () {
                        setState(() {
                          _selectedStatus = tempStatus;
                        });
                        Navigator.of(ctx).pop();
                      },
                    ),
                    const SizedBox(height: AppDimensions.sm),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusFilterOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? AppColors.surfaceContainerHigh : AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isSelected ? AppColors.secondaryContainer : AppColors.surfaceBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20.0),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: AppColors.secondaryContainer, size: 20.0)
              else
                Container(
                  width: 20.0,
                  height: 20.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final allClaims = appState.claims;

    // Apply Real Filtering Logic (Month + Status)
    final filteredClaims = allClaims.where((c) {
      if (!_selectedMonth.isAll) {
        if (c.createdAt.year != _selectedMonth.year ||
            c.createdAt.month != _selectedMonth.month) {
          return false;
        }
      }

      if (_selectedStatus != null) {
        if (c.status != _selectedStatus) {
          return false;
        }
      }

      return true;
    }).toList();

    // Calculate totals based on filtered claims
    final totalLiters = filteredClaims.fold<double>(0.0, (acc, c) => acc + c.liters);
    final totalSpend = filteredClaims.fold<double>(0.0, (acc, c) => acc + c.totalAmount);

    // Section title
    final String sectionTitle;
    if (_selectedMonth.isAll) {
      sectionTitle = _selectedStatus == null
          ? 'All Logged Claims'
          : 'All ${_selectedStatus!.label} Claims';
    } else {
      sectionTitle = _selectedStatus == null
          ? '${_selectedMonth.label} Claims'
          : '${_selectedMonth.label} • ${_selectedStatus!.label}';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Claim History'),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  _selectedStatus != null ? Icons.filter_alt_rounded : Icons.tune_rounded,
                  color: _selectedStatus != null ? AppColors.secondaryContainer : AppColors.textPrimary,
                ),
                tooltip: 'Filter Claims by Status',
                onPressed: _showFilterBottomSheet,
              ),
              if (_selectedStatus != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8.0,
                    height: 8.0,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Operational Fleet Header & Quick Stats (Recalculated for filtered claims)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
                child: _buildStatsSummary(totalLiters, totalSpend, filteredClaims.length),
              ),
              const SizedBox(height: AppDimensions.md),

              // Filter & Timeframe Dynamic Month Chips (Edge-to-Edge scrolling)
              _buildMonthSelector(),
              const SizedBox(height: AppDimensions.md),

              // Claims List Title & Dynamic Counter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sectionTitle,
                        style: AppTypography.headlineMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      '${filteredClaims.length} ${filteredClaims.length == 1 ? "record" : "records"}',
                      style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.sm),

              // Claims List or Clean Empty State
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
                child: filteredClaims.isNotEmpty
                    ? ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredClaims.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: AppDimensions.sm),
                        itemBuilder: (ctx, i) {
                          final claim = filteredClaims[i];
                          return _buildClaimItemCard(claim);
                        },
                      )
                    : _buildEmptyState(),
              ),

              const SizedBox(height: AppDimensions.lg),

              // End of list audit notice
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
                child: _buildAuditNotice(),
              ),
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
              children: [
                Expanded(
                  child: Text(
                    'SKDS Subsidized Diesel (Euro 5 B10)',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  '$count ${count == 1 ? "Claim" : "Claims"} ${_selectedMonth.isAll ? "Total" : "in ${_selectedMonth.label}"}',
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
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          primary: false,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
          clipBehavior: Clip.none,
          itemCount: _monthOptions.length,
          separatorBuilder: (ctx, i) => const SizedBox(width: 8.0),
          itemBuilder: (ctx, i) {
            final opt = _monthOptions[i];
            final isSelected = opt == _selectedMonth;

            return Builder(
              builder: (chipContext) {
                return Material(
                  color: isSelected ? AppColors.secondaryContainer : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(9999.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9999.0),
                    onTap: () {
                      setState(() => _selectedMonth = opt);
                      Scrollable.ensureVisible(
                        chipContext,
                        duration: const Duration(milliseconds: 250),
                        alignment: 0.5,
                        curve: Curves.easeInOut,
                      );
                    },
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.calendar_month_rounded, size: 14.0, color: Color(0xFF231B00)),
                            const SizedBox(width: 6.0),
                          ],
                          Text(
                            opt.label,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final monthText = _selectedMonth.isAll ? 'all recorded history' : _selectedMonth.label;
    final filterDesc = _selectedStatus == null
        ? 'No fuel claims found for $monthText.'
        : 'No ${_selectedStatus!.label.toLowerCase()} claims found for $monthText.';

    return ObpCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60.0,
              height: 60.0,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 30.0,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              'No Fuel Claims Found',
              style: AppTypography.headlineMd.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6.0),
            Text(
              filterDesc,
              style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (!_selectedMonth.isAll || _selectedStatus != null) ...[
              const SizedBox(height: AppDimensions.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear_all_rounded, size: 16.0),
                label: const Text('Reset All Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondaryContainer,
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                onPressed: () {
                  setState(() {
                    _selectedMonth = _monthOptions[0]; // Reset to "All"
                    _selectedStatus = null;
                  });
                },
              ),
            ],
          ],
        ),
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
            claim.formattedDate,
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
            Text(claim.claimId, style: AppTypography.headlineMd),
            ObpStatusBadge.fromClaimStatus(claim.status),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Station: ${claim.stationName}', style: AppTypography.bodyMd),
              const SizedBox(height: 4.0),
              Text('Date: ${claim.formattedDate}', style: AppTypography.bodySm),
              const SizedBox(height: 4.0),
              Text('Assigned Lorry: ${claim.vehiclePlate}', style: AppTypography.bodySm),
              const Divider(height: 24.0, color: AppColors.divider),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Volume Pumped:', style: AppTypography.bodySm),
                  Text('${claim.liters.toStringAsFixed(1)} L @ RM${claim.ratePerLiter.toStringAsFixed(2)}', style: AppTypography.labelMd),
                ],
              ),
              const SizedBox(height: 4.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Subsidy:', style: AppTypography.bodySm),
                  Text('RM ${claim.totalAmount.toStringAsFixed(2)}', style: AppTypography.headlineMd.copyWith(color: AppColors.secondaryContainer)),
                ],
              ),
              const SizedBox(height: 4.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Odometer Verified:', style: AppTypography.bodySm),
                  Text('${claim.odometerKm} KM', style: AppTypography.labelMd),
                ],
              ),
              if (claim.gpsAddress != null) ...[
                const SizedBox(height: 4.0),
                Text('GPS: ${claim.gpsAddress}', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ],
              if (claim.managerFeedback != null && claim.managerFeedback!.isNotEmpty) ...[
                const Divider(height: 24.0, color: AppColors.divider),
                Text('Manager Feedback:', style: AppTypography.labelSm.copyWith(color: AppColors.secondaryContainer)),
                const SizedBox(height: 2.0),
                Text(claim.managerFeedback!, style: AppTypography.bodySm),
              ],
            ],
          ),
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
            'All claims cryptographically synced with Firebase Cloud.',
            style: AppTypography.caption.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
