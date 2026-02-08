import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transfer_line.dart';

// Если вы НЕ используете app_exceptions.dart для этих классов, раскомментируйте их здесь:
/*
class NotFullyPickedException implements Exception {
  @override
  String toString() => 'Not fully picked';
}
*/
// Остальные исключения специфичны для репозитория:

class LineNotFoundException implements Exception {
  @override
  String toString() => 'Line not found';
}

class LockTakenException implements Exception {
  LockTakenException({required this.lockUserId});
  final String lockUserId;
  @override
  String toString() => 'Locked by other';
}

class AlreadyHoldingLockException implements Exception {
  AlreadyHoldingLockException({required this.lineId});
  final String lineId;
  @override
  String toString() => 'Already holding another lock';
}

class LockExpiredException implements Exception {
  @override
  String toString() => 'Lock expired';
}

class NotLockOwnerException implements Exception {
  @override
  String toString() => 'Not lock owner';
}

class OverPickException implements Exception {
  @override
  String toString() => 'Over-pick prevented';
}

class OverCheckException implements Exception {
  @override
  String toString() => 'Over-check prevented';
}

class TransferLinesRepository {
  TransferLinesRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _linesCol(String transferId) =>
      _db.collection('transfers').doc(transferId).collection('lines');

  DocumentReference<Map<String, dynamic>> _lineRef({
    required String transferId,
    required String lineId,
  }) => _linesCol(transferId).doc(lineId);

  DocumentReference<Map<String, dynamic>> _userLockRef({
    required String transferId,
    required String userId,
  }) => _db
      .collection('transfers')
      .doc(transferId)
      .collection('locks')
      .doc(userId);

  Stream<List<TransferLine>> watchLines(String transferId) {
    return _linesCol(transferId)
        .orderBy('category')
        .orderBy('name')
        .snapshots()
        .map((q) => q.docs.map(TransferLine.fromDoc).toList(growable: false));
  }

  Future<void> acquireLock({
    required String transferId,
    required String lineId,
    required String userId,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final ref = _lineRef(transferId: transferId, lineId: lineId);
    final userLockRef = _userLockRef(transferId: transferId, userId: userId);

    await _db.runTransaction((tx) async {
      final now = DateTime.now();
      final expiresAt = now.add(ttl);

      final userLockSnap = await tx.get(userLockRef);
      if (userLockSnap.exists) {
        final d = userLockSnap.data() ?? <String, dynamic>{};
        final existingExpires = d['expiresAt'];
        final existingLineId = d['lineId'] as String?;

        final existingExpiresDt = (existingExpires is Timestamp)
            ? existingExpires.toDate()
            : null;

        final isActive =
            existingExpiresDt != null && existingExpiresDt.isAfter(now);

        if (isActive && existingLineId != null && existingLineId != lineId) {
          throw AlreadyHoldingLockException(lineId: existingLineId);
        }
      }

      final snap = await tx.get(ref);
      if (!snap.exists) throw LineNotFoundException();

      final data = snap.data() ?? <String, dynamic>{};
      final lock = data['lock'];
      final lockUserId = (lock is Map) ? lock['userId'] as String? : null;
      final lockExpires = (lock is Map) ? lock['expiresAt'] : null;
      final lockExpiresDt = (lockExpires is Timestamp)
          ? lockExpires.toDate()
          : null;

      final lockActive =
          lockUserId != null &&
          lockExpiresDt != null &&
          lockExpiresDt.isAfter(now);

      if (lockActive && lockUserId != userId) {
        throw LockTakenException(lockUserId: lockUserId);
      }

      final newLock = <String, dynamic>{
        'userId': userId,
        'expiresAt': Timestamp.fromDate(expiresAt),
      };

      tx.update(ref, {'lock': newLock});
      tx.set(userLockRef, {
        'lineId': lineId,
        'expiresAt': Timestamp.fromDate(expiresAt),
      });
    });
  }

  Future<void> releaseLock({
    required String transferId,
    required String lineId,
    required String userId,
  }) async {
    final ref = _lineRef(transferId: transferId, lineId: lineId);
    final userLockRef = _userLockRef(transferId: transferId, userId: userId);

    await _db.runTransaction((tx) async {
      final now = DateTime.now();
      final snap = await tx.get(ref);
      if (!snap.exists) throw LineNotFoundException();

      final data = snap.data() ?? <String, dynamic>{};
      final lock = data['lock'];
      final lockUserId = (lock is Map) ? lock['userId'] as String? : null;
      final lockExpires = (lock is Map) ? lock['expiresAt'] : null;
      final lockExpiresDt = (lockExpires is Timestamp)
          ? lockExpires.toDate()
          : null;

      final lockActive =
          lockUserId != null &&
          lockExpiresDt != null &&
          lockExpiresDt.isAfter(now);

      if (lockActive && lockUserId != userId) {
        throw NotLockOwnerException();
      }

      tx.update(ref, {'lock': null});

      final userLockSnap = await tx.get(userLockRef);
      if (userLockSnap.exists) {
        final d = userLockSnap.data() ?? <String, dynamic>{};
        final heldLineId = d['lineId'] as String?;
        if (heldLineId == lineId) {
          tx.delete(userLockRef);
        }
      }
    });
  }

  Future<void> incrementPicked({
    required String transferId,
    required String lineId,
    required String userId,
    bool autoReleaseOnComplete = true,
  }) async {
    final ref = _lineRef(transferId: transferId, lineId: lineId);
    final userLockRef = _userLockRef(transferId: transferId, userId: userId);

    await _db.runTransaction((tx) async {
      final now = DateTime.now();
      final snap = await tx.get(ref);
      if (!snap.exists) throw LineNotFoundException();

      final data = snap.data() ?? <String, dynamic>{};
      final qtyPlanned = (data['qtyPlanned'] as num?)?.toInt() ?? 0;
      final qtyPicked = (data['qtyPicked'] as num?)?.toInt() ?? 0;

      final lock = data['lock'];
      final lockUserId = (lock is Map) ? lock['userId'] as String? : null;
      final lockExpires = (lock is Map) ? lock['expiresAt'] : null;
      final lockExpiresDt = (lockExpires is Timestamp)
          ? lockExpires.toDate()
          : null;

      if (lockUserId == null || lockExpiresDt == null || lockUserId != userId) {
        throw NotLockOwnerException();
      }
      if (!lockExpiresDt.isAfter(now)) {
        throw LockExpiredException();
      }
      if (qtyPicked >= qtyPlanned) {
        throw OverPickException();
      }

      final newPicked = qtyPicked + 1;
      final completed = newPicked >= qtyPlanned;
      final updates = <String, dynamic>{'qtyPicked': newPicked};
      if (autoReleaseOnComplete && completed) {
        updates['lock'] = null;
      }

      tx.update(ref, updates);

      if (autoReleaseOnComplete && completed) {
        final userLockSnap = await tx.get(userLockRef);
        if (userLockSnap.exists) {
          final d = userLockSnap.data() ?? <String, dynamic>{};
          final heldLineId = d['lineId'] as String?;
          if (heldLineId == lineId) {
            tx.delete(userLockRef);
          }
        }
      }
    });
  }

  Future<void> acquireCheckLock({
    required String transferId,
    required String lineId,
    required String userId,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final ref = _lineRef(transferId: transferId, lineId: lineId);

    await _db.runTransaction((tx) async {
      final now = DateTime.now();
      final expiresAt = now.add(ttl);
      final snap = await tx.get(ref);
      if (!snap.exists) throw LineNotFoundException();

      final data = snap.data() ?? <String, dynamic>{};
      final checkedLock = data['checkedLock'];
      final lockUserId = (checkedLock is Map)
          ? checkedLock['userId'] as String?
          : null;
      final lockExpires = (checkedLock is Map)
          ? checkedLock['expiresAt']
          : null;
      final lockExpiresDt = (lockExpires is Timestamp)
          ? lockExpires.toDate()
          : null;

      final active =
          lockUserId != null &&
          lockExpiresDt != null &&
          lockExpiresDt.isAfter(now);

      if (active && lockUserId != userId) {
        throw LockTakenException(lockUserId: lockUserId);
      }

      tx.update(ref, {
        'checkedLock': {
          'userId': userId,
          'expiresAt': Timestamp.fromDate(expiresAt),
        },
      });
    });
  }

  Future<void> releaseCheckLock({
    required String transferId,
    required String lineId,
    required String userId,
  }) async {
    final ref = _lineRef(transferId: transferId, lineId: lineId);
    await _db.runTransaction((tx) async {
      final now = DateTime.now();
      final snap = await tx.get(ref);
      if (!snap.exists) throw LineNotFoundException();

      final data = snap.data() ?? <String, dynamic>{};
      final checkedLock = data['checkedLock'];
      final lockUserId = (checkedLock is Map)
          ? checkedLock['userId'] as String?
          : null;
      final lockExpires = (checkedLock is Map)
          ? checkedLock['expiresAt']
          : null;
      final lockExpiresDt = (lockExpires is Timestamp)
          ? lockExpires.toDate()
          : null;

      final active =
          lockUserId != null &&
          lockExpiresDt != null &&
          lockExpiresDt.isAfter(now);

      if (active && lockUserId != userId) {
        throw NotLockOwnerException();
      }
      tx.update(ref, {'checkedLock': null});
    });
  }

  Future<void> incrementChecked({
    required String transferId,
    required String lineId,
    required String userId,
    bool autoReleaseOnComplete = true,
  }) async {
    final ref = _lineRef(transferId: transferId, lineId: lineId);

    await _db.runTransaction((tx) async {
      final now = DateTime.now();
      final snap = await tx.get(ref);
      if (!snap.exists) throw LineNotFoundException();

      final data = snap.data() ?? <String, dynamic>{};
      final qtyPlanned = (data['qtyPlanned'] as num?)?.toInt() ?? 0;
      final qtyPicked = (data['qtyPicked'] as num?)?.toInt() ?? 0;
      final qtyChecked = (data['qtyChecked'] as num?)?.toInt() ?? 0;

      // Используем класс исключения, который вы должны добавить в app_exceptions.dart или использовать тот что есть
      if (qtyPicked < qtyPlanned) {
        // throw NotFullyPickedException(); // Раскомментируйте если класс доступен
        throw Exception('Not fully picked'); // Fallback
      }

      final checkedLock = data['checkedLock'];
      final lockUserId = (checkedLock is Map)
          ? checkedLock['userId'] as String?
          : null;
      final lockExpires = (checkedLock is Map)
          ? checkedLock['expiresAt']
          : null;
      final lockExpiresDt = (lockExpires is Timestamp)
          ? lockExpires.toDate()
          : null;

      final lockActive =
          lockUserId != null &&
          lockExpiresDt != null &&
          lockExpiresDt.isAfter(now);

      if (!lockActive || lockUserId != userId) {
        throw NotLockOwnerException();
      }

      if (qtyChecked >= qtyPlanned) {
        throw OverCheckException();
      }

      final newChecked = qtyChecked + 1;
      final completed = newChecked >= qtyPlanned;
      final updates = <String, dynamic>{'qtyChecked': newChecked};
      if (autoReleaseOnComplete && completed) {
        updates['checkedLock'] = null;
      }
      tx.update(ref, updates);
    });
  }
}
