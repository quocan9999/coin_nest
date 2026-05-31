import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/backup_alert_provider.dart';
import '../theme/app_theme.dart';

class NotificationBadgeButton extends StatelessWidget {
  const NotificationBadgeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final backupAlert = context.watch<BackupAlertProvider>();

    return IconButton(
      tooltip: 'Thông báo',
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (backupAlert.hasPendingChanges)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: AppTheme.spacing8,
                  minHeight: AppTheme.spacing8,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                alignment: Alignment.center,
                child: Text(
                  backupAlert.badgeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
