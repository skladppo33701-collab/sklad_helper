import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/providers.dart';
import '../../data/models/app_notification.dart';
import 'notifications_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _marked = false;

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(notificationsFeedProvider);
    final user = ref.watch(authStateProvider).asData?.value;

    if (!_marked && user != null) {
      _marked = true;
      ref
          .read(notificationRepositoryProvider)
          .markSeen(uid: user.uid, seenAt: DateTime.now());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'), // TODO(l10n)
      ),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')), // TODO(l10n)
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No notifications')); // TODO(l10n)
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = items[i];
              return ListTile(
                leading: Icon(_iconFor(n.type, n.severity)),
                title: Text(n.title),
                subtitle: Text(n.body),
                onTap: () {
                  final transferId = n.transferId;
                  if (transferId != null && transferId.isNotEmpty) {
                    context.push('/transfer/$transferId');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type, AppNotificationSeverity s) {
    if (s == AppNotificationSeverity.critical) return Icons.error_outline;
    if (s == AppNotificationSeverity.warning) {
      return Icons.warning_amber_outlined;
    }

    switch (type) {
      case 'transfer_created':
        return Icons.playlist_add;
      case 'transfer_picked':
        return Icons.check_circle_outline;
      case 'transfer_checking_started':
        return Icons.fact_check_outlined;
      case 'transfer_done':
        return Icons.done_all;
      case 'barcode_bound':
        return Icons.qr_code_2;
      default:
        return Icons.notifications_none;
    }
  }
}
