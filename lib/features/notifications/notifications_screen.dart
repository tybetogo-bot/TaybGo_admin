import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/app_notification.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    Future.microtask(provider.loadNotifications);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.notifications),
            if (provider.unreadCount > 0)
              Text(
                l.notificationsUnread(provider.unreadCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
          ],
        ),
        actions: [
          if (provider.isRefreshing)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            onPressed: provider.isRefreshing ? null : () => provider.refresh(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l.refresh,
          ),
        ],
      ),
      body: _buildBody(context, provider, theme, l),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationProvider provider,
    ThemeData theme,
    AppLocalizations l,
  ) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.notifications.isEmpty) {
      return _MessageState(
        icon: Icons.notifications_off_outlined,
        title: l.notificationsLoadError,
        detail: provider.error,
        actionLabel: l.retry,
        onAction: () => provider.refresh(),
      );
    }

    if (provider.notifications.isEmpty) {
      return _MessageState(
        icon: Icons.notifications_none_rounded,
        title: l.noNotifications,
        detail: null,
        actionLabel: null,
        onAction: null,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: provider.notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notification = provider.notifications[index];
          return _NotificationTile(
            notification: notification,
            onTap: () => unawaited(provider.openNotification(notification)),
            onMarkRead: () => _toggleRead(provider, notification),
            onDelete: () => _delete(provider, notification),
          );
        },
      ),
    );
  }

  Future<void> _toggleRead(
    NotificationProvider provider,
    AppNotification notification,
  ) async {
    final success = notification.isRead
        ? await provider.markUnread(notification.id)
        : await provider.markRead(notification.id);
    if (!success && mounted) _showActionError(provider);
  }

  Future<void> _delete(
    NotificationProvider provider,
    AppNotification notification,
  ) async {
    final success = await provider.deleteNotification(notification.id);
    if (!success && mounted) _showActionError(provider);
  }

  void _showActionError(NotificationProvider provider) {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.actionError ?? l.notificationActionFailed),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
    required this.onDelete,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final unread = !notification.isRead;

    return Material(
      color: unread
          ? AppColors.primary.withValues(alpha: 0.07)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIcon(type: notification.type, unread: unread),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (unread)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsetsDirectional.only(
                              top: 6,
                              end: 6,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title.isEmpty
                                ? l.notifications
                                : notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        notification.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(context, notification.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l.notifications,
                onSelected: (value) {
                  if (value == 'toggle') onMarkRead();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      notification.isRead ? l.markAsUnread : l.markAsRead,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l.deleteNotification),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final material = MaterialLocalizations.of(context);
    final date = material.formatMediumDate(local);
    final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date $time';
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.type, required this.unread});

  final String type;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      'support_ticket_created' => Icons.support_agent_outlined,
      'support_message_from_requester' => Icons.forum_outlined,
      'support_ticket_assigned' => Icons.assignment_ind_outlined,
      'admin_test_notification' => Icons.notifications_active_outlined,
      _ => Icons.notifications_none_rounded,
    };
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: unread ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Icon(icon, color: AppColors.primary, size: 21),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
