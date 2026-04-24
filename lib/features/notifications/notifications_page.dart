import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';
import 'notifications_repository.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.notificationsTitle),
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(notificationsRepositoryProvider)
                  .markAllAsRead();
              ref.invalidate(notificationsProvider);
            },
            child: Text(locale.markAllRead),
          ),
        ],
      ),
      body: notifications.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    locale.notificationEmpty,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: items.map((notification) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NotificationCard(
                    notification: notification,
                    onTap: () => _handleTap(context, ref, notification),
                  ),
                );
              }).toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) {
    if (!notification.isRead) {
      ref.read(notificationsRepositoryProvider).markAsRead(notification.id);
      ref.invalidate(notificationsProvider);
    }

    switch (notification.type) {
      case 'new_match':
      case 'new_message':
        if (notification.referenceId != null) {
          context.push('/chats/${notification.referenceId}');
        }
        break;
      case 'listing_approved':
        if (notification.referenceId != null) {
          context.push('/flat-details/${notification.referenceId}');
        }
        break;
      case 'visit_scheduled':
      case 'visit_confirmed':
        context.go('/visits');
        break;
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_match':
        return Icons.favorite_rounded;
      case 'new_message':
        return Icons.chat_bubble_rounded;
      case 'listing_approved':
        return Icons.check_circle_rounded;
      case 'visit_scheduled':
        return Icons.calendar_month_rounded;
      case 'visit_confirmed':
        return Icons.event_available_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type, ColorScheme colorScheme) {
    switch (type) {
      case 'new_match':
        return const Color(0xFF10B981);
      case 'new_message':
        return colorScheme.primary;
      case 'listing_approved':
        return const Color(0xFF10B981);
      case 'visit_scheduled':
        return const Color(0xFFF59E0B);
      case 'visit_confirmed':
        return const Color(0xFF10B981);
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final color = _colorForType(notification.type, theme.colorScheme);
    final timestamp = DateFormat(
      'd MMM, h:mm a',
      locale.localeName,
    ).format(notification.createdAt.toLocal());

    return Card(
      clipBehavior: Clip.antiAlias,
      color: notification.isRead
          ? null
          : color.withValues(alpha: 0.04),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(
                  _iconForType(notification.type),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
