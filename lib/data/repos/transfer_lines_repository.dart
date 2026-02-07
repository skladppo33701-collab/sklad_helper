import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer_line.dart';

class LockTakenException implements Exception {
  LockTakenException({required this.lockUserId});
  final String lockUserId;
  @override
  String toString() => 'Locked by $lockUserId';
}

class NotLockOwnerException implements Exception {
  @override
  String toString() => 'Not lock owner';
}

class LockExpiredException implements Exception {
  @override
  String toString() => 'Lock expired';
}

class OverPickException implements Exception {
  @override
  String toString() => 'Over-pick not allowed';
}

class TransferLinesRepository {
  TransferLinesRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _linesRef(String transferId) =>
      _db.collection('transfers').doc(transferId).collection('lines');

  DocumentReference<Map<String, dynamic>> _lineRef(
    String transferId,
    String lineId,
  ) => _linesRef(transferId).doc(lineId);

  Stream<List<TransferLine>> watchLines(String transferId) {
    // Free-tier: allowed only while detail screen is open.
    return _linesRef(transferId)
        .orderBy('category')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(TransferLine.fromDoc).toList(growable: false));
  }

  Future<void> acquireLock({
    required String transferId,
    required String lineId,
    required String userId,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final ref = _lineRef(transferId, lineId);
    final now = DateTime.now();
    final expiresAt = now.add(ttl);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Line not found');

      final data = snap.data() ?? <String, dynamic>{};
      final currentLock = TransferLineLock.fromMap(data['lock']);

      final lockActive = currentLock != null && !currentLock.isExpired;
      if (lockActive && currentLock.userId != userId) {
        throw LockTakenException(lockUserId: currentLock.userId);
      }

      tx.update(ref, {
        'lock': {'userId': userId, 'expiresAt': Timestamp.fromDate(expiresAt)},
      });
    });
  }

  Future<void> releaseLock({
    required String transferId,
    required String lineId,
    required String userId,
  }) async {
    final ref = _lineRef(transferId, lineId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? <String, dynamic>{};
      final currentLock = TransferLineLock.fromMap(data['lock']);
      if (currentLock == null) return;

      if (currentLock.userId != userId) {
        throw NotLockOwnerException();
      }

      tx.update(ref, {'lock': null});
    });
  }

  Future<void> incrementPicked({
    required String transferId,
    required String lineId,
    required String userId,
    bool autoReleaseOnComplete = false,
  }) async {
    final ref = _lineRef(transferId, lineId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Line not found');

      final data = snap.data() ?? <String, dynamic>{};
      final lock = TransferLineLock.fromMap(data['lock']);

      if (lock == null) throw NotLockOwnerException();
      if (lock.userId != userId) throw NotLockOwnerException();
      if (lock.isExpired) throw LockExpiredException();

      final planned = (data['qtyPlanned'] as num?)?.toInt() ?? 0;
      final picked = (data['qtyPicked'] as num?)?.toInt() ?? 0;

      if (picked >= planned) throw OverPickException();

      final newPicked = picked + 1;

      final updates = <String, dynamic>{'qtyPicked': newPicked};

      if (autoReleaseOnComplete && newPicked >= planned) {
        updates['lock'] = null;
      }

      tx.update(ref, updates);
    });
  }
}
