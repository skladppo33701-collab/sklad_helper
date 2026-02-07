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

// List screen: stream ONLY transfers
final transfersStreamProvider = StreamProvider<List<Transfer>>((ref) {
  return ref.watch(transferRepositoryProvider).watchTransfers(limit: 50);
});

// Details screen: stream ONLY lines while open
final transferLinesProvider = StreamProvider.autoDispose
    .family<List<TransferLine>, String>((ref, transferId) {
      return ref.watch(transferLinesRepositoryProvider).watchLines(transferId);
    });

// ✅ Optional recommended: stream a SINGLE transfer doc while details open
final transferDocProvider = StreamProvider.autoDispose.family<Transfer, String>(
  (ref, transferId) {
    return ref.watch(transferRepositoryProvider).watchTransfer(transferId);
  },
);
