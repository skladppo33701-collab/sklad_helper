import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer.dart';
// import '../models/transfer_event.dart'; // Если используется Event log

class TransferRepository {
  TransferRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _transfers =>
      _db.collection('transfers');

  // --- Основные методы обновления статусов (Добавлены) ---

  /// Обновляет статус трансфера (используется в finishPicking, finishChecking)
  Future<void> updateStatus(String transferId, TransferStatus status) async {
    await _transfers.doc(transferId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Начинает проверку (ставит статус checking и записывает проверяющего)
  Future<void> startChecking(String transferId, String userId) async {
    await _transfers.doc(transferId).update({
      'status': TransferStatus.checking.name,
      'checkerUid': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Остальные методы (Create, Delete, Restore, List) ---

  Future<void> createTransfer(Transfer transfer) async {
    // Пример создания, если нужно
    await _transfers.doc(transfer.transferId).set(transfer.toMap());
  }

  Future<void> deleteTransfer(String id) async {
    await _transfers.doc(id).update({'isDeleted': true});
  }

  Future<void> restoreTransfer(String id) async {
    await _transfers.doc(id).update({'isDeleted': false});
  }

  Stream<List<Transfer>> watchTransfers({int limit = 50}) {
    return _transfers
        .where('isDeleted', isNotEqualTo: true) // Скрываем удаленные
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Transfer.fromDoc(d)).toList());
  }

  Stream<Transfer?> watchTransfer(String id) {
    return _transfers.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Transfer.fromDoc(doc);
    });
  }
}
