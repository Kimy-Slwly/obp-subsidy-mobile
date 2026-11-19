import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../services/auth_service.dart';
import '../../widgets/obp_button.dart';
import '../../widgets/obp_card.dart';
import '../../widgets/obp_pulse_dot.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'DRV-8821');
  final _passwordController = TextEditingController(text: '••••••••');
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final appState = AppStateScope.of(context);
      await appState.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
    } on UnauthorizedRoleException catch (e) {
      if (!mounted) return;
      _showRoleDeniedDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: AppColors.statusError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRoleDeniedDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        icon: Container(
          width: 52.0,
          height: 52.0,
          decoration: BoxDecoration(
            color: AppColors.statusError.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.block_rounded, color: AppColors.statusError, size: 30.0),
        ),
        title: const Text('Driver Cabin Access Only', style: AppTypography.headlineMd),
        content: Text(
          message,
          style: AppTypography.bodyMd,
          textAlign: TextAlign.center,
        ),
        actions: [
          ObpButton(
            label: 'Understood',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenMargin,
              vertical: AppDimensions.md,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand Header with official OBP logo slot
                  _buildBrandHeader(),
                  const SizedBox(height: AppDimensions.md),

                  // Operational Status Tag
                  _buildStatusTag(),
                  const SizedBox(height: AppDimensions.lg),

                  // Main Login Card (Username, Password, Login button only - NO assign lorry)
                  _buildLoginCard(),
                  const SizedBox(height: AppDimensions.lg),

                  // Dispatcher Support Footnote
                  _buildSupportFootnote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        // Official OBP Logo slot (assets/images/obp_logo.png or assets/obp.png)
        Container(
          constraints: const BoxConstraints(maxWidth: 260.0),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: Image.asset(
              'assets/images/obp_logo.png',
              height: 56.0,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/obp.png',
                height: 56.0,
                fit: BoxFit.contain,
                errorBuilder: (context, error2, stackTrace2) => Container(
                  height: 56.0,
                  alignment: Alignment.center,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping_rounded, color: AppColors.primaryContainer),
                        SizedBox(width: 8.0),
                        Text(
                          'OBP LOGISTICS',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryContainer,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        const Text(
          'OBP Driver Hub',
          style: AppTypography.headlineLg,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Targeted Fuel Subsidy & Fleet Access',
          style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ObpPulseDot(color: AppColors.tertiary, size: 8.0),
          SizedBox(width: 8.0),
          Text(
            'Fleet Portal Online • Night Mode Active',
            style: AppTypography.labelSm,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return ObpCard(
      accentColor: AppColors.primaryContainer,
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username / Email Label
            const Text('Email or Driver ID', style: AppTypography.labelMd),
            const SizedBox(height: AppDimensions.sm),
            TextFormField(
              controller: _usernameController,
              keyboardType: TextInputType.emailAddress,
              style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. DRV-8821 or driver@obp.com.my',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your Driver ID or Email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.md),

            // Password Label
            const Text('Password', style: AppTypography.labelMd),
            const SizedBox(height: AppDimensions.sm),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.lg),

            // Submit Button
            ObpButton(
              label: 'Login to Cabin',
              icon: Icons.login_rounded,
              isLoading: _isLoading,
              onPressed: _handleLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportFootnote() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.headset_mic_outlined, size: 16.0, color: AppColors.textMuted),
            const SizedBox(width: 6.0),
            Text(
              'Dispatch HQ: ',
              style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
            ),
            Text(
              '+60 7-251 8899',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.secondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Text(
          'Protected under SKDS 2.0 Ministry Compliance Engine',
          style: AppTypography.caption.copyWith(color: AppColors.textHint),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
