import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer.dart';
import '../models/transfer_event.dart';
import '../models/user_profile.dart'; // existing UserRole

class InvalidStatusTransitionException implements Exception {
  InvalidStatusTransitionException(this.message);
  final String message;
  @override
  String toString() => message;
}

bool isValidStatusTransition(String from, String to, UserRole role) {
  // loaders can never change status
  if (role == UserRole.loader) return false;

  const allowed = <String, Set<String>>{
    'new': {'picking'},
    'picking': {'picked'},
    'picked': {'checking'},
    'checking': {'done'},
    'done': <String>{},
  };

  // Optional fast-close: new -> done for admin/storekeeper
  final canFastClose = (role == UserRole.admin || role == UserRole.storekeeper);
  if (canFastClose && from == 'new' && to == 'done') return true;

  return allowed[from]?.contains(to) ?? false;
}

class TransferRepository {
  TransferRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _transfers =>
      _db.collection('transfers');

  Stream<List<Transfer>> watchTransfers({int limit = 50}) {
    // Free-tier: stream ONLY transfers list, no subcollections.
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
    final ref = _transfers.doc();
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

  /// Status update with:
  /// - read current status
  /// - validate transition (role-aware)
  /// - update in transaction (race-safe)
  Future<void> updateStatus({
    required String transferId,
    required TransferStatus to,
    required UserRole role,
  }) async {
    final ref = _transfers.doc(transferId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Transfer not found');

      final data = snap.data() ?? <String, dynamic>{};
      final from = (data['status'] as String?) ?? 'new';
      final toStr = transferStatusToString(to);

      if (!isValidStatusTransition(from, toStr, role)) {
        throw InvalidStatusTransitionException(
          'Invalid status transition: $from -> $toStr',
        );
      }

      tx.update(ref, {'status': toStr});
    });
  }

  Future<void> deleteTransfer({required String transferId}) async {
    await _transfers.doc(transferId).delete();
  }

  /// D) EVENTS are NOT realtime: get() page with pagination.
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
