import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router/providers.dart';
import '../../data/models/transfer.dart';
import '../../data/models/transfer_line.dart';
import '../../data/repos/transfer_repository.dart';
import '../../data/repos/transfer_lines_repository.dart';
import '../../data/models/user_profile.dart';

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

final transferLinesStreamProvider =
    StreamProvider.family<List<TransferLine>, String>((ref, transferId) {
      return ref.watch(transferLinesRepositoryProvider).watchLines(transferId);
    });

final currentRoleProvider = Provider<UserRole>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.asData?.value?.role ?? UserRole.guest;
});

final canDeleteTransferProvider = Provider<bool>((ref) {
  return ref.watch(currentRoleProvider) == UserRole.admin;
});
