import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router/providers.dart';
import '../../data/models/transfer.dart';
import '../../data/models/transfer_line.dart';
import '../../data/models/user_profile.dart';
import '../../data/repos/transfer_repository.dart';
import '../../data/repos/transfer_lines_repository.dart';

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepository(ref.watch(firestoreProvider));
});

final transferLinesRepositoryProvider = Provider<TransferLinesRepository>((
  ref,
) {
  return TransferLinesRepository(ref.watch(firestoreProvider));
});

final transfersStreamProvider = StreamProvider<List<Transfer>>((ref) {
  return ref.watch(transferRepositoryProvider).watchTransfers(limit: 50);
});

// Lines stream only while details open
final transferLinesStreamProvider = StreamProvider.autoDispose
    .family<List<TransferLine>, String>((ref, transferId) {
      return ref.watch(transferLinesRepositoryProvider).watchLines(transferId);
    });

// One-time transfer fetch (no extra realtime stream)
final transferProvider = FutureProvider.autoDispose.family<Transfer, String>((
  ref,
  transferId,
) {
  return ref.watch(transferRepositoryProvider).fetchTransfer(transferId);
});

final currentRoleProvider = Provider<UserRole>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.asData?.value?.role ?? UserRole.guest;
});

final canDeleteTransferProvider = Provider<bool>((ref) {
  return ref.watch(currentRoleProvider) == UserRole.admin;
});

class TransferStatusController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // no state
  }

  Future<void> setStatus({
    required String transferId,
    required String from,
    required String to,
  }) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    final role = ref.read(currentRoleProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(transferRepositoryProvider)
          .updateStatus(
            transferId: transferId,
            from: from,
            to: to,
            byUid: uid,
            role: role,
          );

      // refresh transfer snapshot (one-time fetch)
      ref.invalidate(transferProvider(transferId));
      // if list screen is alive, it will update from stream automatically
    });
  }
}

final transferStatusControllerProvider =
    AsyncNotifierProvider<TransferStatusController, void>(
      TransferStatusController.new,
    );
