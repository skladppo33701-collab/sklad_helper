import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer.dart';
import '../models/transfer_event.dart';
import '../models/user_profile.dart';

class InvalidStatusTransitionException implements Exception {
  InvalidStatusTransitionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class StaleTransferStatusException implements Exception {
  StaleTransferStatusException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// MVP status transition rules (role-aware).
bool isValidStatusTransition({
  required String from,
  required String to,
  required UserRole role,
}) {
  if (role == UserRole.loader) return false;

  const allowed = <String, Set<String>>{
    'new': {'picking'},
    'picking': {'picked'},
    'picked': {'checking'},
    'checking': {'done'},
    'done': <String>{},
  };

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
    // Free-tier: stream ONLY transfers list.
    return _transfers
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Transfer.fromDoc).toList(growable: false));
  }

  /// Optional (Sprint3 recommended): stream a SINGLE transfer doc while details are open.
  Stream<Transfer> watchTransfer(String transferId) {
    return _transfers.doc(transferId).snapshots().map((doc) {
      if (!doc.exists) throw Exception('Transfer not found');
      return Transfer.fromDoc(doc);
    });
  }

  Future<Transfer> fetchTransfer(String transferId) async {
    final snap = await _transfers.doc(transferId).get();
    if (!snap.exists) {
      throw Exception('Transfer not found');
    }
    return Transfer.fromDoc(snap);
  }

  Future<String> createTransfer({
    required String title,
    required String createdByUid,
  }) async {
    final ref = _transfers.doc();
    await ref.set({
      'transferId': ref.id,
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdByUid,
      'status': 'new',
      'pickedAt': null,
      'checkedAt': null,
      'doneAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': createdByUid,
    });
    return ref.id;
  }

  Future<void> updateStatus({
    required String transferId,
    required String from,
    required String to,
    required String byUid,
    required UserRole role,
  }) async {
    final ref = _transfers.doc(transferId);

    if (!isValidStatusTransition(from: from, to: to, role: role)) {
      throw InvalidStatusTransitionException(
        'Invalid transition: $from -> $to',
      );
    }

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Transfer not found');

      final data = snap.data() ?? <String, dynamic>{};
      final current = (data['status'] as String?) ?? 'new';

      if (current != from) {
        throw StaleTransferStatusException(
          'Stale status. Current=$current, expected=$from',
        );
      }

      if (!isValidStatusTransition(from: current, to: to, role: role)) {
        throw InvalidStatusTransitionException(
          'Invalid transition: $current -> $to',
        );
      }

      final updates = <String, dynamic>{
        'status': to,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ✅ Use byUid (fix analyzer + useful audit field)
      updates['updatedBy'] = byUid;

      if (to == 'picked') {
        updates['pickedAt'] = FieldValue.serverTimestamp();
      } else if (to == 'checking') {
        updates['checkedAt'] = FieldValue.serverTimestamp();
      } else if (to == 'done') {
        updates['doneAt'] = FieldValue.serverTimestamp();
      }

      tx.update(ref, updates);
    });
  }

  Future<void> deleteTransfer({required String transferId}) async {
    await _transfers.doc(transferId).delete();
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
