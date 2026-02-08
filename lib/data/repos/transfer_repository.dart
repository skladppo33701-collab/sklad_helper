import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer.dart';
import '../models/transfer_event.dart';

// УДАЛЕНО: final transferRepositoryProvider = ...
// Провайдер уже есть в transfers_providers.dart

class TransferRepository {
  TransferRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _transfers =>
      _db.collection('transfers');

  // --- Хелпер уведомлений ---
  Future<void> _emitNotification({
    required String type,
    required String title,
    required String body,
    required String byUid,
    String? transferId,
    List<String> audience = const ['staff'],
    String severity = 'info',
  }) async {
    await _db.collection('notifications').add({
      'type': type,
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': byUid,
      'transferId': transferId,
      'severity': severity,
      'audience': audience,
    });
  }

  // --- Список трансферов ---
  Stream<List<Transfer>> watchTransfers({int limit = 50}) {
    return _transfers
        // Фильтр: скрываем удаленные
        .where('isDeleted', isNotEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Transfer.fromDoc).toList(growable: false));
  }

  Stream<Transfer> watchTransfer(String transferId) {
    return _transfers.doc(transferId).snapshots().map(Transfer.fromDoc);
  }

  // --- Методы для статусов (Checking Controller) ---

  // 1. Начать проверку (перевод в статус checking)
  Future<void> startChecking(String transferId, String userId) async {
    await _transfers.doc(transferId).update({
      'status': 'checking',
      'checkedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. Завершить трансфер (перевод в статус done)
  Future<void> finishTransfer(String transferId, String userId) async {
    final ref = _transfers.doc(transferId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Transfer not found');

      tx.update(ref, {
        'status': 'done',
        'checkedAt': FieldValue.serverTimestamp(),
        'checkedBy': userId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userId,
      });
    });

    await _emitNotification(
      type: 'transfer_done',
      title: 'Transfer done',
      body: 'Transfer $transferId finished',
      byUid: userId,
      transferId: transferId,
    );
  }

  // --- Методы удаления (Soft Delete) ---

  Future<void> deleteTransfer(String id) async {
    await _transfers.doc(id).update({'isDeleted': true});
  }

  Future<void> restoreTransfer(String id) async {
    await _transfers.doc(id).update({'isDeleted': false});
  }

  // --- История событий ---

  Future<List<TransferEvent>> fetchEventsPage({
    required String transferId,
    int limit = 30,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('transfers')
        .doc(transferId)
        .collection('events')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.get();
    return snap.docs.map(TransferEvent.fromDoc).toList();
  }
}
