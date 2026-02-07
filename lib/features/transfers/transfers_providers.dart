import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';
import '../../data/models/transfer.dart';
import '../../data/models/transfer_line.dart';
import '../../data/repos/barcode_repository.dart';
import '../../data/repos/transfer_lines_repository.dart';
import '../../data/repos/transfer_repository.dart';
import 'transfer_picking_controller.dart';

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepository(ref.watch(firestoreProvider));
});

final transferLinesRepositoryProvider = Provider<TransferLinesRepository>((
  ref,
) {
  return TransferLinesRepository(ref.watch(firestoreProvider));
});

final barcodeRepositoryProvider = Provider<BarcodeRepository>((ref) {
  return BarcodeRepository(ref.watch(firestoreProvider));
});

// Transfers list: stream ONLY transfers
final transfersStreamProvider = StreamProvider<List<Transfer>>((ref) {
  return ref.watch(transferRepositoryProvider).watchTransfers(limit: 50);
});

// Lines: stream ONLY in details while open
final transferLinesProvider = StreamProvider.autoDispose
    .family<List<TransferLine>, String>((ref, transferId) {
      return ref.watch(transferLinesRepositoryProvider).watchLines(transferId);
    });

// Controller for picking flow
final transferPickingControllerProvider =
    AutoDisposeAsyncNotifierProvider<TransferPickingController, void>(
      TransferPickingController.new,
    );
