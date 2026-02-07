import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer.dart';
import '../models/transfer_event.dart';

class TransferRepository {
  TransferRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _transfers =>
      _db.collection('transfers');

  Stream<List<Transfer>> watchTransfers({int limit = 50}) {
    return _transfers
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Transfer.fromDoc).toList(growable: false));
  }

  Stream<Transfer> watchTransfer(String transferId) {
    return _transfers.doc(transferId).snapshots().map((doc) {
      if (!doc.exists) throw Exception('Transfer not found');
      return Transfer.fromDoc(doc);
    });
  }

  Future<void> startChecking({
    required String transferId,
    required String userId,
  }) async {
    final ref = _transfers.doc(transferId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Transfer not found');

      final data = snap.data() ?? <String, dynamic>{};
      final currentStatus = (data['status'] as String?) ?? 'new';

      // Sprint5 precondition: must be picked
      if (currentStatus != 'picked') {
        throw Exception('Invalid status: $currentStatus'); // TODO(l10n)
      }

      tx.update(ref, {
        'status': 'checking',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userId,
      });
    });
  }

  Future<void> finishTransfer({
    required String transferId,
    required String userId,
  }) async {
    final ref = _transfers.doc(transferId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Transfer not found');

      final data = snap.data() ?? <String, dynamic>{};
      final currentStatus = (data['status'] as String?) ?? 'new';

      if (currentStatus != 'checking') {
        throw Exception('Invalid status: $currentStatus'); // TODO(l10n)
      }

      tx.update(ref, {
        'status': 'done',
        'checkedAt': FieldValue.serverTimestamp(),
        'checkedBy': userId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userId,
      });
    });
  }

  Future<List<TransferEvent>> fetchEventsPage({
    required String transferId,
    int limit = 30,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('transfers')
        .doc(transferId)
        .collection('events')
        .orderBy('at', descending: true)
        .limit(limit);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.get();
    return snap.docs.map(TransferEvent.fromDoc).toList(growable: false);
  }
}
