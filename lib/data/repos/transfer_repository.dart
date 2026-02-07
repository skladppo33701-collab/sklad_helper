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
  // loaders cannot change transfer status
  if (role == UserRole.loader) return false;

  // forward-only transitions
  const allowed = <String, Set<String>>{
    'new': {'picking'},
    'picking': {'picked'},
    'picked': {'checking'},
    'checking': {'done'},
    'done': <String>{},
  };

  // optional fast-close: admin/storekeeper can do new->done
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
      // optional stage timestamps
      'pickedAt': null,
      'checkedAt': null,
      'doneAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Status update MUST be transaction-based, stale-safe, role-gated.
  ///
  /// - read transfer
  /// - ensure current status == from (stale write protection)
  /// - validate transition (role-aware)
  /// - update status + updatedAt + stage timestamp for target status
  Future<void> updateStatus({
    required String transferId,
    required String from,
    required String to,
    required String byUid,
    required UserRole role,
  }) async {
    final ref = _transfers.doc(transferId);

    // A) fail fast: client-side guard
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

      // stale write protection
      if (current != from) {
        throw StaleTransferStatusException(
          'Stale status. Current=$current, expected=$from',
        );
      }

      // B) guard again inside transaction (defense in depth)
      if (!isValidStatusTransition(from: current, to: to, role: role)) {
        throw InvalidStatusTransitionException(
          'Invalid transition: $current -> $to',
        );
      }

      final updates = <String, dynamic>{
        'status': to,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (to == 'picked') {
        updates['pickedAt'] = FieldValue.serverTimestamp();
      } else if (to == 'checking') {
        updates['checkedAt'] = FieldValue.serverTimestamp();
      } else if (to == 'done') {
        updates['doneAt'] = FieldValue.serverTimestamp();
      }

      tx.update(ref, updates);

      // Optional (NOT realtime): could append event here, but MVP says events are NOT realtime;
      // still allowed to write events, but do not stream them. Omit for now to minimize writes.
      // If you add events later, write a single small event doc here.
      // (No-op)
      (void,) byUid;
    });
  }

  Future<void> deleteTransfer({required String transferId}) async {
    await _transfers.doc(transferId).delete();
  }

  /// Events are NOT realtime: get() page with pagination.
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
