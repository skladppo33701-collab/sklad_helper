import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_profile.dart';
import '../../data/repos/user_repo.dart';
import '../../data/repos/notification_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final userRepoProvider = Provider<UserRepo>(
  (ref) => UserRepo(ref.watch(firestoreProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(firestoreProvider)),
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final userAsync = ref.watch(authStateProvider);
  final user = userAsync.asData?.value;
  if (user == null) return const Stream.empty();

  // Ensure user doc exists (guest by default) when they log in.
  // Fire-and-forget, but safe.
  ref
      .read(userRepoProvider)
      .upsertOnLogin(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );

  return ref.watch(userRepoProvider).watchProfile(user.uid);
});
