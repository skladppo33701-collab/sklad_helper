import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transfer.dart';
import '../../data/models/transfer_line.dart';
import '../../data/repos/transfer_repository.dart';
import '../../data/repos/transfer_lines_repository.dart';
import '../../data/repos/barcode_repository.dart';

// Репозитории
final transferRepositoryProvider = Provider((ref) {
  return TransferRepository(FirebaseFirestore.instance);
});

final transferLinesRepositoryProvider = Provider((ref) {
  return TransferLinesRepository(FirebaseFirestore.instance);
});

final barcodeRepositoryProvider = Provider((ref) {
  return BarcodeRepository(FirebaseFirestore.instance);
});

// --- Провайдеры данных ---

// Список трансферов (исправлено имя для соответствия TransfersListScreen)
final transfersStreamProvider = StreamProvider<List<Transfer>>((ref) {
  return ref.watch(transferRepositoryProvider).watchTransfers();
});

// Один трансфер
final transferStreamProvider = StreamProvider.family<Transfer?, String>((
  ref,
  id,
) {
  return ref.watch(transferRepositoryProvider).watchTransfer(id);
});

// Линии трансфера
final transferLinesStreamProvider =
    StreamProvider.family<List<TransferLine>, String>((ref, id) {
      return ref.watch(transferLinesRepositoryProvider).watchLines(id);
    });
