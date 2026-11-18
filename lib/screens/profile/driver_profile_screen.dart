import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../models/driver_model.dart';
import '../../widgets/obp_button.dart';
import '../../widgets/obp_card.dart';
import '../../widgets/obp_pulse_dot.dart';
import '../../widgets/obp_status_badge.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final driver = appState.driver;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Driver Profile'),
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
              // Driver Identity Spotlight Card
              _buildIdentityCard(driver),
              const SizedBox(height: AppDimensions.md),

              // Key Metrics Row
              _buildMetricsRow(driver),
              const SizedBox(height: AppDimensions.lg),

              // Section 1: Fleet & Vehicle Specifics
              _buildSectionHeader('Fleet & Vehicle Details'),
              const SizedBox(height: AppDimensions.sm),
              _buildVehicleDetailsCard(driver),
              const SizedBox(height: AppDimensions.lg),

              // Section 2: Driver Certifications & Compliance
              _buildSectionHeader('Driver Credentials & SKDS'),
              const SizedBox(height: AppDimensions.sm),
              _buildCredentialsCard(driver),
              const SizedBox(height: AppDimensions.lg),

              // Section 3: App Controls & Operational Support
              _buildSectionHeader('App Preferences & Support'),
              const SizedBox(height: AppDimensions.sm),
              _buildPreferencesCard(context, driver, appState),
              const SizedBox(height: AppDimensions.lg),

              // Log Out Button
              ObpButton(
                label: 'Log Out of Driver Hub',
                icon: Icons.logout_rounded,
                variant: ObpButtonVariant.outline,
                onPressed: () => _showLogoutConfirmDialog(context, appState),
              ),
              const SizedBox(height: AppDimensions.md),

              // App Version Footnote
              Center(
                child: Column(
                  children: [
                    Text(
                      'OBP Driver Hub v2.4.1 (Build 829)',
                      style: AppTypography.caption.copyWith(color: AppColors.textHint),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Ong Brothers Petroleum Fleet Management System',
                      style: AppTypography.caption.copyWith(color: AppColors.textHint, fontSize: 10.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelMd.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildIdentityCard(DriverModel driver) {
    return ObpCard(
      accentColor: AppColors.primaryContainer,
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with Online Beacon
              Stack(
                children: [
                  Container(
                    width: 64.0,
                    height: 64.0,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceBorder, width: 2.0),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'AR',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: ObpPulseDot(color: AppColors.statusSuccess, size: 14.0),
                  ),
                ],
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.name, style: AppTypography.headlineMd),
                    const SizedBox(height: 2.0),
                    Text(
                      '${driver.id} • ${driver.role}',
                      style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6.0),
                    Row(
                      children: [
                        ObpStatusBadge.neutral(label: driver.lorryPlate, icon: Icons.local_shipping_outlined),
                        const SizedBox(width: 6.0),
                        ObpStatusBadge.verified(label: 'Active Shift'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(DriverModel driver) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile('On-Time', '${driver.onTimeRate}%', Icons.timer_outlined, AppColors.tertiary),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildMetricTile('Pumped', '${(driver.totalDieselPumped / 1000).toStringAsFixed(0)}k L', Icons.local_gas_station_outlined, AppColors.secondaryContainer),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildMetricTile('Safety', '${driver.safetyRating} ★', Icons.shield_outlined, AppColors.statusSuccess),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20.0, color: color),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: AppTypography.labelLg.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailsCard(DriverModel driver) {
    return ObpCard(
      child: Column(
        children: [
          _buildInfoRow('Assigned Lorry', driver.lorryPlate, isHighlight: true),
          const Divider(height: 18.0),
          _buildInfoRow('Vehicle Model', driver.lorryModel),
          const Divider(height: 18.0),
          _buildInfoRow('Operating Company', driver.company),
          const Divider(height: 18.0),
          _buildInfoRow('Base Depot', driver.depot),
          const Divider(height: 18.0),
          _buildInfoRow('Fuel Tank Capacity', '450 Liters (Dual Tanks)'),
        ],
      ),
    );
  }

  Widget _buildCredentialsCard(DriverModel driver) {
    return ObpCard(
      child: Column(
        children: [
          _buildInfoRow('GDL License (Class E)', '${driver.gdlLicenseNo} (Exp: ${driver.gdlExpiry})'),
          const Divider(height: 18.0),
          _buildInfoRow('Hazmat Dangerous Goods', '${driver.hazmatCertNo} (Exp: ${driver.hazmatExpiry})'),
          const Divider(height: 18.0),
          _buildInfoRow('Subsidy Card ID', driver.subsidyCardId, isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context, DriverModel driver, AppState appState) {
    return ObpCard(
      child: Column(
        children: [
          // Biometric Switch
          SwitchListTile(
            title: const Text('Biometric Login', style: AppTypography.bodyMd),
            subtitle: const Text('Quick login via FaceID or Fingerprint', style: AppTypography.caption),
            value: driver.biometricEnabled,
            activeColor: AppColors.primaryContainer,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => appState.toggleBiometrics(val),
          ),
          const Divider(height: 14.0),

          // Auto Flash Camera Switch
          SwitchListTile(
            title: const Text('Auto-Flash for OCR', style: AppTypography.bodyMd),
            subtitle: const Text('Enhance odometer detection in night cabins', style: AppTypography.caption),
            value: driver.autoFlashEnabled,
            activeColor: AppColors.primaryContainer,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => appState.toggleAutoFlash(val),
          ),
          const Divider(height: 14.0),

          // Language Selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('App Language', style: AppTypography.bodyMd),
                    Text('Choose interface language', style: AppTypography.caption),
                  ],
                ),
                Row(
                  children: ['EN', 'BM'].map((lang) {
                    final isSel = driver.language == lang;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: ChoiceChip(
                        label: Text(lang),
                        selected: isSel,
                        selectedColor: AppColors.secondaryContainer,
                        labelStyle: TextStyle(
                          color: isSel ? const Color(0xFF231B00) : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => appState.setLanguage(lang),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 14.0),

          // Dispatcher Hotline
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.phone_in_talk_rounded, color: AppColors.secondaryContainer),
            title: const Text('Emergency Dispatch Hotline', style: AppTypography.bodyMd),
            subtitle: const Text('+60 7-251 8899 (24/7 Operations)', style: AppTypography.caption),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14.0, color: AppColors.textMuted),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dialing Dispatch HQ: +60 7-251 8899')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySm),
        Text(
          value,
          style: AppTypography.labelMd.copyWith(
            color: isHighlight ? AppColors.secondaryContainer : AppColors.textPrimary,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: const Text('Log Out of Cabin?', style: AppTypography.headlineMd),
        content: const Text(
          'Your active shift state will be saved. You can log back in with your Driver ID.',
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              appState.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
