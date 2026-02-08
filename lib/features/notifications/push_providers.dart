import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';
import '../../data/repos/push_token_repository.dart';

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  return PushTokenRepository(
    auth: ref.watch(firebaseAuthProvider),
    db: ref.watch(firestoreProvider),
  );
});

/// Bootstrap that runs once after auth+profile are available.
/// No widgets call Firestore directly.
final pushBootstrapProvider = Provider<void>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  final profile = ref.watch(userProfileProvider).asData?.value;

  if (user == null || profile == null) return;

  // Role/isActive already exist in profile; you may optionally guard active users.
  // Trigger once per session.
  final repo = ref.read(pushTokenRepositoryProvider);
  repo.registerTokenIfNeeded();
  repo.listenTokenRefresh();
});
