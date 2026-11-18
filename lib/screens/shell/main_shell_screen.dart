import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/app_state.dart';
import '../home/home_screen.dart';
import '../history/claim_history_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/driver_profile_screen.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  static const List<Widget> _pages = [
    HomeScreen(),
    ClaimHistoryScreen(),
    NotificationsScreen(),
    DriverProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final currentIndex = appState.currentNavigationIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 6.0,
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'New Fuel Claim',
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.newClaim);
        },
        child: const Icon(Icons.qr_code_scanner_rounded, size: 28.0),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surfaceContainerLow,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 12.0,
        padding: EdgeInsets.zero,
        height: AppDimensions.bottomNavHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 0: Home
            _buildNavButton(
              context: context,
              index: 0,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => appState.setNavigationIndex(0),
            ),

            // Tab 1: Claims
            _buildNavButton(
              context: context,
              index: 1,
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: 'Claims',
              isSelected: currentIndex == 1,
              onTap: () => appState.setNavigationIndex(1),
            ),

            const SizedBox(width: 48.0), // Gap for Center FloatingActionButton

            // Tab 2: Alerts / Notifications
            _buildNavButton(
              context: context,
              index: 2,
              icon: Icons.notifications_outlined,
              activeIcon: Icons.notifications_rounded,
              label: 'Alerts',
              isSelected: currentIndex == 2,
              badgeCount: appState.unreadNotificationCount,
              onTap: () => appState.setNavigationIndex(2),
            ),

            // Tab 3: Profile
            _buildNavButton(
              context: context,
              index: 3,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
              isSelected: currentIndex == 3,
              onTap: () => appState.setNavigationIndex(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final color = isSelected ? AppColors.secondaryContainer : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: 22.0,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3.0),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14.0, minHeight: 14.0),
                      alignment: Alignment.center,
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          fontSize: 8.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2.0),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
