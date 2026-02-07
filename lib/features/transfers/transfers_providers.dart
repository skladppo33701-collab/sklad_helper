import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router/providers.dart';
import '../../data/models/transfer.dart';
import '../../data/models/transfer_line.dart';
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

// ✅ Fix: Provide the missing transfersStreamProvider used by TransfersListScreen.
final transfersStreamProvider = StreamProvider<List<Transfer>>((ref) {
  return ref.watch(transferRepositoryProvider).watchTransfers(limit: 50);
});

// Sprint 3: lines stream ONLY inside detail screen (autoDispose).
final transferLinesProvider = StreamProvider.autoDispose
    .family<List<TransferLine>, String>((ref, transferId) {
      return ref.watch(transferLinesRepositoryProvider).watchLines(transferId);
    });
