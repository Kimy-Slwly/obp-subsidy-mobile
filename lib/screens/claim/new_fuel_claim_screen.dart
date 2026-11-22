import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/state/app_state.dart';
import '../../services/image_watermark_service.dart';
import '../../services/location_service.dart';
import '../../services/ocr_service.dart';
import '../../widgets/obp_button.dart';
import '../../widgets/obp_card.dart';
import '../../widgets/obp_status_badge.dart';

class NewFuelClaimScreen extends StatefulWidget {
  const NewFuelClaimScreen({super.key});

  @override
  State<NewFuelClaimScreen> createState() => _NewFuelClaimScreenState();
}

class _NewFuelClaimScreenState extends State<NewFuelClaimScreen> {
  final ImagePicker _picker = ImagePicker();

  // Step 1: Odometer OCR & Anti-Spoofing Audit
  File? _odometerFile;
  final TextEditingController _odometerController = TextEditingController(text: '248930');
  bool _isScanningOdo = false;
  double _ocrConfidence = 0.0;
  bool _odometerScanned = false;
  String _captureSource = 'live_camera';
  String? _imageHash;
  int? _lastApprovedOdometer;

  // Step 2: Location
  bool _isRefreshingGps = false;
  LocationVerificationResult? _locationResult;
  bool _locationVerified = false;
  String _stationName = 'Location Not Verified';
  double? _gpsLat;
  double? _gpsLng;
  String _gpsAddress = 'Tap "Refresh GPS Location" to verify nearby Shell station';

  // Step 3: Receipt Photo & Pump Details
  File? _receiptFile;
  bool _receiptUploaded = true;
  final TextEditingController _litersController = TextEditingController(text: '280.5');

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyGpsLocation();
      _loadLastApprovedOdometer();
    });
  }

  Future<void> _loadLastApprovedOdometer() async {
    try {
      final appState = AppStateScope.of(context);
      final odo = await appState.getLastApprovedOdometer();
      if (mounted) {
        setState(() => _lastApprovedOdometer = odo);
      }
    } catch (e) {
      debugPrint('[NewFuelClaimScreen] Error preloading approved odometer: $e');
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _litersController.dispose();
    super.dispose();
  }

  Future<void> _captureOdometer(ImageSource source, {bool isDevTest = false}) async {
    if (_isScanningOdo || _isRefreshingGps) return;

    // Strict security check: In release builds, only live camera is allowed
    if (!kDebugMode && source != ImageSource.camera) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security Notice: Only live camera capture is permitted for odometer verification.'),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Optimized to prevent high heap and ANR
        maxWidth: 1280,   // Resized for fast ML Kit processing
      );

      if (picked == null) return;

      setState(() {
        _isScanningOdo = true;
        _captureSource = isDevTest ? 'dev_gallery_test' : 'live_camera';
      });

      final originalFile = File(picked.path);

      // 1. Execute on-device ML Kit OCR
      final ocrResult = await OcrService.extractOdometerMileage(picked.path);

      // 2. Automatically burn tamper-evident watermark and compute SHA-256 hash
      final appState = AppStateScope.of(context);
      final vehiclePlate = appState.assignedVehicle.plateNumber;

      final watermarkRes = await ImageWatermarkService.applyWatermark(
        originalImage: originalFile,
        plateNumber: vehiclePlate,
        latitude: _gpsLat,
        longitude: _gpsLng,
        timestamp: DateTime.now(),
      );

      // 3. Pre-check for duplicate image hash in Firestore
      final isDuplicate = await appState.checkIsDuplicateImageHash(watermarkRes.imageHash);
      if (isDuplicate) {
        if (!mounted) return;
        setState(() {
          _isScanningOdo = false;
        });
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              side: const BorderSide(color: AppColors.statusError),
            ),
            icon: const Icon(Icons.security_update_warning_rounded, color: AppColors.statusError, size: 40.0),
            title: const Text('Duplicate Photo Rejected', style: AppTypography.headlineMd),
            content: const Text(
              'Anti-spoofing alert: This exact dashboard photo has already been submitted in a prior claim. Live dashboard photo capture is strictly required.',
              style: AppTypography.bodyMd,
            ),
            actions: [
              ObpButton(
                label: 'Understood',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _odometerFile = watermarkRes.watermarkedFile;
        _imageHash = watermarkRes.imageHash;

        if (ocrResult.isSuccess && ocrResult.mileageKm != null) {
          _odometerController.text = ocrResult.mileageKm.toString();
          _ocrConfidence = ocrResult.confidence;
          _odometerScanned = true;
        } else {
          _odometerScanned = true;
          _ocrConfidence = ocrResult.confidence;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dashboard image watermarked. Please verify the mileage reading below.'),
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera capture error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isScanningOdo = false);
      }
    }
  }

  Future<void> _verifyGpsLocation() async {
    if (_isRefreshingGps || _isScanningOdo) return;

    setState(() => _isRefreshingGps = true);

    try {
      final res = await LocationService.getCurrentVerification();
      if (!mounted) return;

      setState(() {
        _locationResult = res;
        _stationName = res.stationName;
        _gpsLat = res.latitude;
        _gpsLng = res.longitude;
        _gpsAddress = res.address;
        _locationVerified = res.isInsideGeofence;
      });

      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.isInsideGeofence
                ? 'Geofence Match: ${res.stationName} (${res.distanceMeters.toStringAsFixed(0)}m away)'
                : 'Notice: Outside Shell station perimeter. Address: ${res.address}'),
            backgroundColor: res.isInsideGeofence ? AppColors.statusSuccess : AppColors.statusWarning,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.statusMessage ?? 'GPS lock unavailable. Please check location permissions.'),
            backgroundColor: AppColors.statusWarning,
          ),
        );
      }
    } catch (e) {
      debugPrint('[NewFuelClaimScreen] Error refreshing GPS: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GPS verification error: $e'),
          backgroundColor: AppColors.statusError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshingGps = false);
      }
    }
  }

  Future<void> _captureReceipt(ImageSource source) async {
    if (_isRefreshingGps || _isScanningOdo) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );

      if (picked == null) return;

      setState(() {
        _receiptFile = File(picked.path);
        _receiptUploaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting receipt: $e')),
      );
    }
  }

  Future<void> _handleSubmit() async {
    final odoKm = int.tryParse(_odometerController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (odoKm == null || odoKm <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid odometer reading.')),
      );
      return;
    }

    final liters = double.tryParse(_litersController.text.trim()) ?? 0.0;
    if (liters <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid pumped liters.')),
      );
      return;
    }

    final appState = AppStateScope.of(context);

    // 1. Fetch latest approved odometer reading for sequential validation
    final int lastApprovedOdometer = await appState.getLastApprovedOdometer();

    // Hard block: newOdometer <= lastApprovedOdometer
    if (odoKm <= lastApprovedOdometer) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            side: const BorderSide(color: AppColors.statusError),
          ),
          icon: const Icon(Icons.block_rounded, color: AppColors.statusError, size: 40.0),
          title: const Text('Invalid Odometer Reading', style: AppTypography.headlineMd),
          content: Text(
            'Odometer reading ($odoKm km) cannot be lower than or equal to the last approved reading of $lastApprovedOdometer km.\n\nPlease scan or enter the true current dashboard reading.',
            style: AppTypography.bodyMd,
          ),
          actions: [
            ObpButton(
              label: 'Re-enter Reading',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Sequential calculations: distance travelled and fuel efficiency
    final int distanceTravelled = odoKm - lastApprovedOdometer;
    final double kmPerLitre = liters > 0 ? (distanceTravelled / liters) : 0.0;

    // 3. Anomaly Evaluation
    final List<String> anomalyReasons = [];

    if (distanceTravelled > 1500) {
      anomalyReasons.add('Distance travelled ($distanceTravelled km) exceeds single-refill 1,500 km limit');
    }

    if (kmPerLitre < 2.0) {
      anomalyReasons.add('Fuel efficiency (${kmPerLitre.toStringAsFixed(2)} KM/L) is abnormally low (< 2.0 KM/L)');
    } else if (kmPerLitre > 8.0) {
      anomalyReasons.add('Fuel efficiency (${kmPerLitre.toStringAsFixed(2)} KM/L) is abnormally high (> 8.0 KM/L for heavy lorry)');
    }

    if (_ocrConfidence < 0.80) {
      anomalyReasons.add('Odometer OCR confidence (${(_ocrConfidence * 100).toStringAsFixed(1)}%) is below 80% threshold');
    }

    final bool isAnomaly = anomalyReasons.isNotEmpty;
    final String? anomalyReason = isAnomaly ? anomalyReasons.join(' • ') : null;

    // 4. Duplicate Image Hash check
    if (_imageHash != null) {
      final isDuplicate = await appState.checkIsDuplicateImageHash(_imageHash!);
      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission blocked: Duplicate odometer image already exists in database.'),
            backgroundColor: AppColors.statusError,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      await appState.submitNewClaim(
        stationName: _stationName,
        liters: liters,
        odometerKm: odoKm,
        odometerFile: _odometerFile,
        receiptFile: _receiptFile,
        gpsLatitude: _gpsLat,
        gpsLongitude: _gpsLng,
        gpsAddress: _gpsAddress,
        previousOdometer: lastApprovedOdometer,
        distanceTravelled: distanceTravelled,
        kmPerLitre: kmPerLitre,
        ocrConfidence: _ocrConfidence,
        captureSource: _captureSource,
        imageHash: _imageHash,
        isAnomaly: isAnomaly,
        anomalyReason: anomalyReason,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            side: BorderSide(color: isAnomaly ? AppColors.statusWarning : AppColors.surfaceBorder),
          ),
          icon: Container(
            width: 56.0,
            height: 56.0,
            decoration: BoxDecoration(
              color: isAnomaly ? const Color(0x22F59E0B) : const Color(0x2210B981),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAnomaly ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: isAnomaly ? AppColors.statusWarning : AppColors.statusSuccess,
              size: 36.0,
            ),
          ),
          title: Text(isAnomaly ? 'Claim Submitted (Under Audit)' : 'Claim Logged & Stored', style: AppTypography.headlineMd),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your claim for ${liters.toStringAsFixed(1)} L at $_stationName ($odoKm km) has been secured with tamper-proof watermark and submitted to Cloud Firestore.',
                style: AppTypography.bodyMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.sm),
              if (isAnomaly) ...[
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: AppColors.statusWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: AppColors.statusWarning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Audit Flag Raised:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0, color: AppColors.statusWarning),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        anomalyReason ?? '',
                        style: AppTypography.caption.copyWith(color: AppColors.statusWarning),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
              ],
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  isAnomaly
                      ? 'Flagged for Special Logistics Audit in Web Dashboard'
                      : 'Pending Logistics Manager Review in Web Dashboard',
                  style: AppTypography.caption.copyWith(
                    color: isAnomaly ? AppColors.statusWarning : AppColors.secondaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit claim: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final vehicle = appState.assignedVehicle;
    final quota = appState.quota;

    final parsedLiters = double.tryParse(_litersController.text.trim()) ?? 280.5;
    final totalAmount = parsedLiters * quota.subsidizedRate;

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
              _buildContextBar(vehicle, quota),
              const SizedBox(height: AppDimensions.md),

              // Step 1: Odometer OCR Card
              _buildOdometerStep(),
              const SizedBox(height: AppDimensions.md),

              // Step 2: GPS Verification Card
              _buildGpsStep(),
              const SizedBox(height: AppDimensions.md),

              // Step 3: Receipt Upload Card
              _buildReceiptStep(),
              const SizedBox(height: AppDimensions.lg),

              // Total Calculation Summary Card
              _buildSummaryCard(parsedLiters, totalAmount),
              const SizedBox(height: AppDimensions.lg),

              // Submit Button & Legal Disclaimer
              ObpButton(
                label: 'Submit Claim to Manager',
                icon: Icons.cloud_upload_rounded,
                isLoading: _isSubmitting,
                onPressed: (_isSubmitting || _isRefreshingGps || _isScanningOdo) ? null : _handleSubmit,
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

  Widget _buildContextBar(dynamic vehicle, dynamic quota) {
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
                'Lorry: ${vehicle.plateNumber}',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            'Remaining: ${vehicle.remainingQuota.toStringAsFixed(0)} L',
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
              if (_isScanningOdo)
                const SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.secondaryContainer),
                )
              else if (_odometerScanned && _odometerFile != null)
                ObpStatusBadge.verified(label: '${(_ocrConfidence * 100).toStringAsFixed(1)}% OCR')
              else
                ObpStatusBadge.warning(label: 'Pending Scan'),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'Capture dashboard meter with camera. On-device ML Kit OCR will extract digits.',
            style: AppTypography.bodySm.copyWith(fontSize: 12.0),
          ),
          const SizedBox(height: AppDimensions.md),

          // Scan Box Container & Fallback Editable Field
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: _odometerScanned ? AppColors.statusSuccess.withValues(alpha: 0.3) : AppColors.surfaceBorder,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_odometerFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        child: Image.file(_odometerFile!, width: 48.0, height: 48.0, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 48.0,
                        height: 48.0,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: const Icon(Icons.camera_alt_outlined, color: AppColors.textMuted),
                      ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Odometer Reading (KM)', style: AppTypography.caption),
                          TextFormField(
                            controller: _odometerController,
                            keyboardType: TextInputType.number,
                            style: AppTypography.headlineMd.copyWith(
                              color: AppColors.textPrimary,
                              letterSpacing: 1.0,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4.0),
                              hintText: 'e.g. 248930',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_camera_rounded, size: 16.0),
                        label: const Text('Live Camera', maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40.0),
                          foregroundColor: AppColors.textPrimary,
                        ),
                        onPressed: (_isScanningOdo || _isRefreshingGps)
                            ? null
                            : () => _captureOdometer(ImageSource.camera),
                      ),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(width: 8.0),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.developer_mode, size: 14.0),
                        label: const Text('Dev: Test Image', maxLines: 1),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(120.0, 40.0),
                          foregroundColor: AppColors.secondaryContainer,
                          side: const BorderSide(color: AppColors.secondaryContainer),
                        ),
                        onPressed: (_isScanningOdo || _isRefreshingGps)
                            ? null
                            : () => _captureOdometer(ImageSource.gallery, isDevTest: true),
                      ),
                    ],
                  ],
                ),
                if (_lastApprovedOdometer != null) ...[
                  const SizedBox(height: 6.0),
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 13.0, color: AppColors.textMuted),
                      const SizedBox(width: 4.0),
                      Text(
                        'Last approved: $_lastApprovedOdometer km',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
                if (_imageHash != null) ...[
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 13.0, color: AppColors.secondaryContainer),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          'Watermarked SHA-256: ${_imageHash!.substring(0, 16)}...',
                          style: AppTypography.caption.copyWith(color: AppColors.secondaryContainer),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
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
              if (_isRefreshingGps)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14.0,
                      height: 14.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.secondaryContainer),
                    ),
                    SizedBox(width: 6.0),
                    Text('Acquiring...', style: AppTypography.caption),
                  ],
                )
              else if (_locationVerified)
                ObpStatusBadge.verified(label: 'Geofence Match')
              else
                ObpStatusBadge.warning(label: _locationResult == null ? 'Not Verified' : 'Unverified'),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'Live GPS check verified against nearby Shell petrol stations',
            style: AppTypography.bodySm.copyWith(fontSize: 12.0),
          ),
          const SizedBox(height: AppDimensions.md),

          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: _locationVerified
                            ? AppColors.statusSuccess.withValues(alpha: 0.15)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: _locationVerified ? AppColors.statusSuccess : AppColors.primaryContainer,
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
                          if (_gpsLat != null && _gpsLng != null && (_gpsLat != 0.0 || _gpsLng != 0.0))
                            Text(
                              '${_gpsLat!.toStringAsFixed(5)}° N, ${_gpsLng!.toStringAsFixed(5)}° E${_locationVerified && _locationResult != null ? ' • ${_locationResult!.distanceMeters.toStringAsFixed(0)}m' : ''}',
                              style: AppTypography.caption.copyWith(
                                color: _locationVerified ? AppColors.statusSuccess : AppColors.statusWarning,
                              ),
                            )
                          else
                            Text(
                              'GPS fix not yet acquired',
                              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                            ),
                          Text(
                            _gpsAddress,
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.sm),
                OutlinedButton.icon(
                  icon: _isRefreshingGps
                      ? const SizedBox(
                          width: 14.0,
                          height: 14.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.secondaryContainer),
                        )
                      : const Icon(Icons.my_location_rounded, size: 16.0),
                  label: Text(_isRefreshingGps ? 'Scanning Nearby Stations...' : 'Refresh GPS Location'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40.0),
                    foregroundColor: AppColors.secondaryContainer,
                  ),
                  onPressed: (_isRefreshingGps || _isScanningOdo) ? null : _verifyGpsLocation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptStep() {
    return ObpCard(
      accentColor: _receiptUploaded ? AppColors.statusSuccess : AppColors.surfaceBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('3. Snap Shell Card Receipt', style: AppTypography.labelMd),
              if (_receiptUploaded)
                ObpStatusBadge.verified(label: 'Photo Attached')
              else
                ObpStatusBadge.warning(label: 'Required'),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'Take a clear photo of the printed Shell Card receipt showing volume and pump #',
            style: AppTypography.bodySm.copyWith(fontSize: 12.0),
          ),
          const SizedBox(height: AppDimensions.md),

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
                    if (_receiptFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        child: Image.file(_receiptFile!, width: 48.0, height: 48.0, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 48.0,
                        height: 48.0,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: AppColors.secondaryContainer),
                      ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pumped Diesel Volume (L)', style: AppTypography.caption),
                          TextFormField(
                            controller: _litersController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: AppTypography.headlineMd.copyWith(
                              color: AppColors.textPrimary,
                              letterSpacing: 1.0,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4.0),
                              hintText: 'e.g. 280.5',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_camera_rounded, size: 16.0),
                        label: const Text('Capture Receipt'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40.0),
                          foregroundColor: AppColors.textPrimary,
                        ),
                        onPressed: (_isScanningOdo || _isRefreshingGps)
                            ? null
                            : () => _captureReceipt(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined, size: 16.0),
                      label: const Text('Upload'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(90.0, 40.0),
                        foregroundColor: AppColors.textMuted,
                      ),
                      onPressed: (_isScanningOdo || _isRefreshingGps)
                          ? null
                          : () => _captureReceipt(ImageSource.gallery),
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

  Widget _buildSummaryCard(double liters, double totalAmount) {
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
              const Expanded(
                child: Text('Claim Volume:', style: AppTypography.bodySm),
              ),
              const SizedBox(width: 8.0),
              Text(
                '${liters.toStringAsFixed(1)} Liters',
                style: AppTypography.labelMd.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Subsidized Rate (SKDS 2.0):', style: AppTypography.bodySm),
              ),
              const SizedBox(width: 8.0),
              Text(
                'RM 2.15 / Liter',
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
              const Expanded(
                child: Text('Calculated Subsidy Cost:', style: AppTypography.labelMd),
              ),
              const SizedBox(width: 8.0),
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
              'Submitted claims are synchronized with Firebase and inspected on the Manager Web Dashboard (obp-fleet-hub).',
              style: AppTypography.caption.copyWith(color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}
