import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';
import '../../data/models/transfer.dart';
import '../../data/models/transfer_line.dart';
import '../../data/repos/barcode_repository.dart';
import '../../data/repos/transfer_lines_repository.dart';
import '../../data/repos/transfer_repository.dart';
import 'transfer_checking_controller.dart';
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

// transfers list: stream ONLY transfers
final transfersStreamProvider = StreamProvider<List<Transfer>>((ref) {
  return ref.watch(transferRepositoryProvider).watchTransfers(limit: 50);
});

// detail: stream ONLY lines while open
final transferLinesProvider = StreamProvider.autoDispose
    .family<List<TransferLine>, String>((ref, transferId) {
      return ref.watch(transferLinesRepositoryProvider).watchLines(transferId);
    });

// optional: single transfer doc listener while open
final transferDocProvider = StreamProvider.autoDispose.family<Transfer, String>(
  (ref, transferId) {
    return ref.watch(transferRepositoryProvider).watchTransfer(transferId);
  },
);

// Sprint4 picking controller
final transferPickingControllerProvider =
    AutoDisposeAsyncNotifierProvider<TransferPickingController, void>(
      TransferPickingController.new,
    );

// Sprint5 checking controller
final transferCheckingControllerProvider =
    AutoDisposeAsyncNotifierProvider<TransferCheckingController, void>(
      TransferCheckingController.new,
    );
