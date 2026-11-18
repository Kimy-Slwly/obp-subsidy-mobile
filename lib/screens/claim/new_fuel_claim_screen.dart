import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/state/app_state.dart';
import '../../widgets/obp_button.dart';
import '../../widgets/obp_card.dart';
import '../../widgets/obp_status_badge.dart';

class NewFuelClaimScreen extends StatefulWidget {
  const NewFuelClaimScreen({super.key});

  @override
  State<NewFuelClaimScreen> createState() => _NewFuelClaimScreenState();
}

class _NewFuelClaimScreenState extends State<NewFuelClaimScreen> {
  bool _odometerScanned = true;
  String _odometerReading = '248,930';
  bool _locationVerified = true;
  String _stationName = 'Shell Rawang R&R (Northbound)';
  bool _receiptUploaded = true;
  double _litersClaimed = 280.5;
  bool _isSubmitting = false;

  void _handleSubmit() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final appState = AppStateScope.of(context);
    final odoClean = int.tryParse(_odometerReading.replaceAll(',', '')) ?? 248930;

    appState.submitNewClaim(
      stationName: _stationName,
      liters: _litersClaimed,
      odometerKm: odoClean,
    );

    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        icon: Container(
          width: 56.0,
          height: 56.0,
          decoration: const BoxDecoration(
            color: Color(0x2210B981),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 36.0),
        ),
        title: const Text('Claim Submitted', style: AppTypography.headlineMd),
        content: Text(
          'Your claim for ${_litersClaimed.toStringAsFixed(1)} L at $_stationName has been cryptographically logged and submitted to the fleet manager.',
          style: AppTypography.bodyMd,
          textAlign: TextAlign.center,
        ),
        actions: [
          ObpButton(
            label: 'Back to Cabin',
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final driver = appState.driver;
    final quota = appState.quota;
    final totalAmount = _litersClaimed * quota.subsidizedRate;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Fuel Claim'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
              // Active Shift Context Bar
              _buildContextBar(driver, quota),
              const SizedBox(height: AppDimensions.md),

              // Step 1: Odometer OCR Card
              _buildOdometerStep(),
              const SizedBox(height: AppDimensions.md),

              // Step 2: GPS Verification Card
              _buildGpsStep(),
              const SizedBox(height: AppDimensions.md),

              // Step 3: Receipt Upload Card
              _buildReceiptStep(quota, totalAmount),
              const SizedBox(height: AppDimensions.lg),

              // Total Calculation Summary Card
              _buildSummaryCard(totalAmount),
              const SizedBox(height: AppDimensions.lg),

              // Submit Button & Legal Disclaimer
              ObpButton(
                label: 'Submit Claim to Manager',
                icon: Icons.lock_outline_rounded,
                isLoading: _isSubmitting,
                onPressed: (_odometerScanned && _locationVerified && _receiptUploaded)
                    ? _handleSubmit
                    : null,
              ),
              const SizedBox(height: AppDimensions.md),
              _buildLegalDisclaimer(),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextBar(dynamic driver, dynamic quota) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 16.0, color: AppColors.secondaryContainer),
              const SizedBox(width: 6.0),
              Text(
                'Lorry: ${driver.lorryPlate}',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            'Avail Quota: ${quota.currentBalance.toStringAsFixed(0)} L',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.secondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOdometerStep() {
    return ObpCard(
      accentColor: _odometerScanned ? AppColors.statusSuccess : AppColors.surfaceBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1. Scan Dashboard Odometer', style: AppTypography.labelMd),
              if (_odometerScanned)
                ObpStatusBadge.verified(label: '99.4% Match')
              else
                ObpStatusBadge.warning(label: 'Pending'),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'Align dashboard digits inside optical frame',
            style: AppTypography.bodySm.copyWith(fontSize: 12.0),
          ),
          const SizedBox(height: AppDimensions.md),

          // Scan Box Container
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: _odometerScanned ? AppColors.statusSuccess.withValues(alpha: 0.3) : AppColors.surfaceBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Icon(
                    _odometerScanned ? Icons.check_circle_outline_rounded : Icons.camera_alt_outlined,
                    color: _odometerScanned ? AppColors.statusSuccess : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Detected Reading', style: AppTypography.labelSm),
                      Text(
                        '$_odometerReading KM',
                        style: AppTypography.headlineMd.copyWith(
                          color: AppColors.textPrimary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16.0),
                  label: const Text('Rescan'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryContainer,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Simulated camera OCR rescan complete.')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsStep() {
    return ObpCard(
      accentColor: _locationVerified ? AppColors.statusSuccess : AppColors.surfaceBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2. Verify Petrol Station Location', style: AppTypography.labelMd),
              if (_locationVerified)
                ObpStatusBadge.verified(label: 'Inside Geofence')
              else
                ObpStatusBadge.warning(label: 'Checking'),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'GPS coordinates matched against authorized Shell stations',
            style: AppTypography.bodySm.copyWith(fontSize: 12.0),
          ),
          const SizedBox(height: AppDimensions.md),

          // Station Location Box
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: _locationVerified ? AppColors.statusSuccess.withValues(alpha: 0.3) : AppColors.surfaceBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stationName,
                        style: AppTypography.labelMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '3.3214° N, 101.5781° E • 18m from pump #4',
                        style: AppTypography.caption.copyWith(color: AppColors.statusSuccess),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptStep(dynamic quota, double totalAmount) {
    return ObpCard(
      accentColor: _receiptUploaded ? AppColors.statusSuccess : AppColors.surfaceBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('3. Snap Shell Receipt', style: AppTypography.labelMd),
              if (_receiptUploaded)
                ObpStatusBadge.verified(label: 'Receipt Captured')
              else
                ObpStatusBadge.warning(label: 'Required'),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'Ensure volume, pump number and tax invoice number are visible',
            style: AppTypography.bodySm.copyWith(fontSize: 12.0),
          ),
          const SizedBox(height: AppDimensions.md),

          // Receipt Preview Box
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: _receiptUploaded ? AppColors.statusSuccess.withValues(alpha: 0.3) : AppColors.surfaceBorder,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.secondaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Invoice #SH-992140', style: AppTypography.labelSm),
                          Text(
                            '${_litersClaimed.toStringAsFixed(1)} Liters Pumped',
                            style: AppTypography.labelMd,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
                      onPressed: () {
                        // Allow driver to adjust pumped liters
                        _showLitersEditDialog();
                      },
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

  void _showLitersEditDialog() {
    final controller = TextEditingController(text: _litersClaimed.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Edit Pumped Liters', style: AppTypography.headlineMd),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Liters (L)'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              final parsed = double.tryParse(controller.text);
              if (parsed != null && parsed > 0) {
                setState(() => _litersClaimed = parsed);
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double totalAmount) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Claim Volume:', style: AppTypography.bodySm),
              Text(
                '${_litersClaimed.toStringAsFixed(1)} L',
                style: AppTypography.labelMd.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subsidized Rate (SKDS):', style: AppTypography.bodySm),
              Text(
                'RM 2.15 / L',
                style: AppTypography.labelMd.copyWith(color: AppColors.statusSuccess),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: AppColors.divider),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Subsidy Value:', style: AppTypography.labelMd),
              Text(
                'RM ${totalAmount.toStringAsFixed(2)}',
                style: AppTypography.headlineMd.copyWith(
                  color: AppColors.secondaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 14.0, color: AppColors.textHint),
          const SizedBox(width: 6.0),
          Expanded(
            child: Text(
              'False claims subject to immediate SKDS suspension and disciplinary action under Section 15 Fleet Regulations.',
              style: AppTypography.caption.copyWith(color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}
