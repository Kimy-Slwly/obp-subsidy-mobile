import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'route_transitions.dart';
import '../../screens/login/login_screen.dart';
import '../../screens/shell/main_shell_screen.dart';
import '../../screens/claim/new_fuel_claim_screen.dart';
import '../../screens/history/claim_history_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/profile/driver_profile_screen.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return FadeThroughPageRoute(
          page: const LoginScreen(),
          settings: settings,
        );

      case AppRoutes.shell:
        return FadeThroughPageRoute(
          page: const MainShellScreen(),
          settings: settings,
        );

      case AppRoutes.newClaim:
        return SlideUpPageRoute(
          page: const NewFuelClaimScreen(),
          settings: settings,
        );

      case AppRoutes.claimHistory:
        return FadeThroughPageRoute(
          page: const ClaimHistoryScreen(),
          settings: settings,
        );

      case AppRoutes.notifications:
        return SlideUpPageRoute(
          page: const NotificationsScreen(),
          settings: settings,
        );

      case AppRoutes.profile:
        return FadeThroughPageRoute(
          page: const DriverProfileScreen(),
          settings: settings,
        );

      default:
        return FadeThroughPageRoute(
          page: const MainShellScreen(),
          settings: settings,
        );
    }
  }
}
