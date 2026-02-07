import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer.dart';

class TransferRepository {
  TransferRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _transfers =>
      _db.collection('transfers');

  Stream<List<Transfer>> watchTransfers({int limit = 50}) {
    // Free-tier friendly: only stream transfers, no subcollections.
    return _transfers
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Transfer.fromDoc).toList(growable: false));
  }

  Future<String> createTransfer({
    required String title,
    required String createdByUid,
  }) async {
    final ref = _transfers.doc(); // auto id
    final now = DateTime.now();
    await ref.set({
      'transferId': ref.id,
      'title': title,
      'createdAt': Timestamp.fromDate(now),
      'createdBy': createdByUid,
      'status': 'new',
    });
    return ref.id;
  }

  Future<void> updateStatus({
    required String transferId,
    required TransferStatus status,
  }) async {
    await _transfers.doc(transferId).update({
      'status': transferStatusToString(status),
    });
  }

  Future<void> deleteTransfer({required String transferId}) async {
    // Admin-only enforcement should be done at UI/provider + Firestore rules.
    await _transfers.doc(transferId).delete();
  }
}
