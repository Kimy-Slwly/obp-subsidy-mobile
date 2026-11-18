import 'package:flutter/material.dart';
import '../../models/driver_model.dart';
import '../../models/fuel_claim_model.dart';
import '../../models/notification_model.dart';
import '../../models/quota_model.dart';

class AppState extends ChangeNotifier {
  bool _isAuthenticated = true; // Default logged in for smooth exploration, can toggle
  int _currentNavigationIndex = 0;

  DriverModel _driver = DriverModel.dummy;
  QuotaModel _quota = QuotaModel.dummy;
  List<FuelClaimModel> _claims = List.from(FuelClaimModel.dummyList);
  List<NotificationModel> _notifications = List.from(NotificationModel.dummyList);

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  int get currentNavigationIndex => _currentNavigationIndex;
  DriverModel get driver => _driver;
  QuotaModel get quota => _quota;
  List<FuelClaimModel> get claims => List.unmodifiable(_claims);
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  // Actions
  void setNavigationIndex(int index) {
    if (_currentNavigationIndex != index) {
      _currentNavigationIndex = index;
      notifyListeners();
    }
  }

  void login(String driverId, String password) {
    _isAuthenticated = true;
    _currentNavigationIndex = 0;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _currentNavigationIndex = 0;
    notifyListeners();
  }

  void submitNewClaim({
    required String stationName,
    required double liters,
    required int odometerKm,
  }) {
    final newClaim = FuelClaimModel(
      id: 'CLM-${40922 + _claims.length}',
      stationName: stationName,
      date: 'Just now',
      liters: liters,
      ratePerLiter: _quota.subsidizedRate,
      odometerKm: odometerKm,
      status: ClaimStatus.pending,
      locationVerified: true,
      receiptUploaded: true,
      odometerVerified: true,
      lorryPlate: _driver.lorryPlate,
    );

    _claims.insert(0, newClaim);

    // Update quota balance
    final newBalance = (_quota.currentBalance - liters).clamp(0.0, _quota.monthlyLimit);
    _quota = QuotaModel(
      currentBalance: newBalance,
      monthlyLimit: _quota.monthlyLimit,
      subsidizedRate: _quota.subsidizedRate,
      marketRate: _quota.marketRate,
      resetDaysRemaining: _quota.resetDaysRemaining,
      resetDate: _quota.resetDate,
    );

    // Add a notification
    _notifications.insert(
      0,
      NotificationModel(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Claim Submitted: ${newClaim.id}',
        message: '${liters.toStringAsFixed(1)} L at $stationName is pending manager verification.',
        timestamp: 'Just now',
        category: NotificationCategory.quota,
        priority: NotificationPriority.normal,
        isRead: false,
      ),
    );

    notifyListeners();
  }

  void markAllNotificationsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
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
}

/// InheritedWidget provider for easy access without external dependencies
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
