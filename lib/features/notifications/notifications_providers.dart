import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';
import '../../data/models/app_notification.dart';

final notificationsLastSeenAtProvider = Provider<DateTime?>((ref) {
  final profile = ref.watch(userProfileProvider).asData?.value;
  return profile?.notificationsLastSeenAt;
});

final notificationsFeedProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
      final user = ref.watch(authStateProvider).asData?.value;
      final profile = ref.watch(userProfileProvider).asData?.value;

      if (user == null || profile == null) {
        return const Stream.empty();
      }

      final since =
          ref.watch(notificationsLastSeenAtProvider) ??
          DateTime.now().subtract(const Duration(days: 7));

      return ref
          .watch(notificationRepositoryProvider)
          .watchRecentForUser(
            uid: user.uid,
            role: profile.role.name,
            since: since,
            limit: 50,
          );
    });
