import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/driver_model.dart';
import '../../models/fuel_claim_model.dart';
import '../../models/notification_model.dart';
import '../../models/quota_model.dart';
import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/auth_service.dart';
import '../../services/fuel_claim_service.dart';
import '../../services/notification_service.dart';
import '../../services/vehicle_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final VehicleService _vehicleService = VehicleService();
  final FuelClaimService _claimService = FuelClaimService();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription? _vehicleSubscription;
  StreamSubscription? _claimsSubscription;
  StreamSubscription? _notificationsSubscription;

  bool _isAuthenticated = true; // Enabled for seamless presentation/testing
  int _currentNavigationIndex = 0;

  UserModel _user = UserModel.dummyDriver;
  DriverModel _driver = DriverModel.dummy;
  VehicleModel _assignedVehicle = VehicleModel.dummy;
  QuotaModel _quota = QuotaModel.dummy;

  List<FuelClaimModel> _claims = List.from(FuelClaimModel.dummyList);
  List<NotificationModel> _notifications = List.from(NotificationModel.dummyList);

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  int get currentNavigationIndex => _currentNavigationIndex;
  UserModel get user => _user;
  DriverModel get driver => _driver;
  VehicleModel get assignedVehicle => _assignedVehicle;
  QuotaModel get quota => _quota;
  List<FuelClaimModel> get claims => List.unmodifiable(_claims);
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  AppState() {
    _initListeners();
  }

  void _initListeners() {
    _subscribeToVehicle(_user.assignedVehicleId ?? 'veh_jdt1111');
    _subscribeToClaims(_user.uid);
    _subscribeToNotifications(_user.uid);
  }

  void _subscribeToVehicle(String vehicleId) {
    _vehicleSubscription?.cancel();
    _vehicleSubscription = _vehicleService.getAssignedVehicleStream(vehicleId).listen((veh) {
      _assignedVehicle = veh;
      // Sync quota model with vehicle's monthly limit and usage
      _quota = QuotaModel(
        currentBalance: veh.remainingQuota,
        monthlyLimit: veh.monthlyQuotaLimit,
        subsidizedRate: 2.15,
        marketRate: 3.35,
        resetDaysRemaining: QuotaModel.calcDaysRemaining(),
        resetDate: QuotaModel.formatNextResetDate(),
      );
      notifyListeners();
    });
  }

  void _subscribeToClaims(String driverId) {
    _claimsSubscription?.cancel();
    _claimsSubscription = _claimService.getDriverClaimsStream(driverId).listen((claimsList) {
      _claims = claimsList;
      notifyListeners();
    });
  }

  void _subscribeToNotifications(String driverId) {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _notificationService.getDriverNotificationsStream(driverId).listen((notifs) {
      _notifications = notifs;
      notifyListeners();
    });
  }

  void setNavigationIndex(int index) {
    if (_currentNavigationIndex != index) {
      _currentNavigationIndex = index;
      notifyListeners();
    }
  }

  Future<void> login(String emailOrUsername, String password) async {
    final loggedUser = await _authService.signIn(
      emailOrUsername: emailOrUsername,
      password: password,
    );

    _user = loggedUser;
    _isAuthenticated = true;
    _currentNavigationIndex = 0;

    _driver = DriverModel(
      id: loggedUser.driverId,
      name: loggedUser.displayName,
      role: 'Senior Lorry Driver',
      lorryPlate: _assignedVehicle.plateNumber,
      lorryModel: _assignedVehicle.model,
      depot: _assignedVehicle.depot,
      company: 'Ong Brothers Petroleum Sdn Bhd',
      gdlLicenseNo: 'GDL-8821-E',
      gdlExpiry: '14 May 2027',
      hazmatCertNo: 'HAZ-DG-4401',
      hazmatExpiry: '30 Nov 2026',
      subsidyCardId: 'SKDS-OBP-9921',
      onTimeRate: 99.2,
      totalDieselPumped: 148200,
      safetyRating: 4.9,
    );

    _initListeners();
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.signOut();
    _isAuthenticated = false;
    _currentNavigationIndex = 0;
    _vehicleSubscription?.cancel();
    _claimsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    notifyListeners();
  }

  Future<int> getLastApprovedOdometer({String? vehicleId}) async {
    return await _claimService.getLastApprovedOdometer(
      vehicleId: vehicleId ?? _assignedVehicle.id,
      fallbackOdometer: _assignedVehicle.currentOdometer,
    );
  }

  Future<bool> checkIsDuplicateImageHash(String imageHash) async {
    return await _claimService.checkIsDuplicateImageHash(imageHash);
  }

  Future<void> submitNewClaim({
    required String stationName,
    required double liters,
    required int odometerKm,
    File? odometerFile,
    File? receiptFile,
    double? gpsLatitude,
    double? gpsLongitude,
    String? gpsAddress,
    int? previousOdometer,
    int? distanceTravelled,
    double? kmPerLitre,
    double? ocrConfidence,
    String captureSource = 'live_camera',
    String? imageHash,
    bool isAnomaly = false,
    String? anomalyReason,
  }) async {
    final claim = await _claimService.submitClaim(
      driverId: _user.uid,
      driverName: _user.displayName,
      vehicleId: _assignedVehicle.id,
      vehiclePlate: _assignedVehicle.plateNumber,
      stationName: stationName,
      liters: liters,
      ratePerLiter: _quota.subsidizedRate,
      odometerKm: odometerKm,
      odometerFile: odometerFile,
      receiptFile: receiptFile,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
      gpsAddress: gpsAddress,
      previousOdometer: previousOdometer,
      distanceTravelled: distanceTravelled,
      kmPerLitre: kmPerLitre,
      ocrConfidence: ocrConfidence,
      captureSource: captureSource,
      imageHash: imageHash,
      isAnomaly: isAnomaly,
      anomalyReason: anomalyReason,
    );

    // Optimistic local update
    final newBalance = (_quota.currentBalance - liters).clamp(0.0, _quota.monthlyLimit);
    _quota = QuotaModel(
      currentBalance: newBalance,
      monthlyLimit: _quota.monthlyLimit,
      subsidizedRate: _quota.subsidizedRate,
      marketRate: _quota.marketRate,
      resetDaysRemaining: _quota.resetDaysRemaining,
      resetDate: _quota.resetDate,
    );

    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    await _notificationService.markAsRead(id);
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    await _notificationService.markAllAsRead(_user.uid);
    notifyListeners();
  }

  void toggleBiometrics(bool val) {
    _driver = _driver.copyWith(biometricEnabled: val);
    notifyListeners();
  }

  void toggleAutoFlash(bool val) {
    _driver = _driver.copyWith(autoFlashEnabled: val);
    notifyListeners();
  }

  void setLanguage(String lang) {
    _driver = _driver.copyWith(language: lang);
    notifyListeners();
  }

  @override
  void dispose() {
    _vehicleSubscription?.cancel();
    _claimsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.notifier!;
  }
}
