import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../models/notification_model.dart';
import '../../widgets/obp_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final quota = appState.quota;
    final allNotifications = appState.notifications;

    final filtered = _selectedCategory == NotificationCategory.all
        ? allNotifications
        : allNotifications.where((n) => n.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.done_all_rounded, size: 18.0),
            label: const Text('Mark all read'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondaryContainer,
            ),
            onPressed: () {
              appState.markAllNotificationsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read.')),
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
              // Driver Fleet Pulse Quick Glance Hero Card
              _buildPulseHeroCard(quota),
              const SizedBox(height: AppDimensions.md),

              // Filter Category Chips
              _buildFilterChips(allNotifications),
              const SizedBox(height: AppDimensions.md),

              // Notifications List
              if (filtered.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: AppDimensions.sm),
                  itemBuilder: (ctx, i) {
                    final item = filtered[i];
                    return _buildNotificationCard(item, appState);
                  },
                )
              else
                _buildEmptyState(),

              const SizedBox(height: AppDimensions.lg),

              // End of Alerts Stamp
              Center(
                child: Text(
                  'End of Alerts Feed',
                  style: AppTypography.caption.copyWith(color: AppColors.textHint),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseHeroCard(dynamic quota) {
    final percentUsed = (quota.percentageUsed / 100.0).clamp(0.0, 1.0);

    return ObpCard(
      accentColor: AppColors.secondaryContainer,
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(percentUsed * 100).toStringAsFixed(0)}% Monthly Allowance Consumed',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: AppColors.statusWarning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'NOTICE',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.statusWarning,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999.0),
            child: SizedBox(
              height: 8.0,
              child: LinearProgressIndicator(
                value: percentUsed,
                backgroundColor: AppColors.surfaceContainerLowest,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryContainer),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Remaining quota: ${quota.currentBalance.toStringAsFixed(0)} L before reset on ${quota.resetDate}.',
            style: AppTypography.bodySm.copyWith(fontSize: 12.0),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<NotificationModel> all) {
    return SizedBox(
      height: 36.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: NotificationCategory.values.map((cat) {
          final isSelected = cat == _selectedCategory;
          final count = cat == NotificationCategory.all
              ? all.length
              : all.where((n) => n.category == cat).length;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Material(
              color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(9999.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(9999.0),
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9999.0),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryContainer : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Text(
                    '${cat.label} ($count)',
                    style: AppTypography.labelSm.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel item, AppState appState) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (item.priority) {
      case NotificationPriority.high:
        icon = Icons.warning_rounded;
        iconColor = AppColors.statusError;
        iconBg = const Color(0x22EF4444);
        break;
      case NotificationPriority.normal:
        if (item.category == NotificationCategory.maintenance) {
          icon = Icons.build_circle_rounded;
          iconColor = AppColors.statusInfo;
          iconBg = const Color(0x223B82F6);
        } else {
          icon = Icons.check_circle_rounded;
          iconColor = AppColors.statusSuccess;
          iconBg = const Color(0x2210B981);
        }
        break;
      case NotificationPriority.low:
        icon = Icons.info_rounded;
        iconColor = AppColors.textMuted;
        iconBg = AppColors.surfaceContainerHigh;
        break;
    }

    return ObpCard(
      backgroundColor: item.isRead ? AppColors.surfaceCard : AppColors.surfaceContainerLow,
      border: Border.all(
        color: item.isRead ? AppColors.surfaceBorder : AppColors.primaryContainer.withValues(alpha: 0.35),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: iconColor, size: 22.0),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.only(left: 8.0),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  item.message,
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.timestamp,
                      style: AppTypography.caption.copyWith(color: AppColors.textHint),
                    ),
                    if (item.actionLabel != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: AppColors.secondaryContainer,
                        ),
                        onPressed: () {
                          if (item.actionLabel == 'Update Photo') {
                            Navigator.of(context).pushNamed(AppRoutes.newClaim);
                          } else {
                            appState.setNavigationIndex(1);
                            Navigator.of(context).pop();
                          }
                        },
                        child: Row(
                          children: [
                            Text(item.actionLabel!, style: AppTypography.labelSm.copyWith(color: AppColors.secondaryContainer)),
                            const SizedBox(width: 4.0),
                            const Icon(Icons.arrow_forward_rounded, size: 12.0, color: AppColors.secondaryContainer),
                          ],
                        ),
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.notifications_off_outlined, size: 48.0, color: AppColors.textMuted),
          const SizedBox(height: AppDimensions.md),
          const Text('No Notifications', style: AppTypography.headlineMd),
          const SizedBox(height: 4.0),
          Text(
            'You are completely up to date with your fleet alerts.',
            style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
