import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer_line.dart';
import '../models/user_profile.dart'; // existing UserRole

// Typed exceptions
class LockTakenException implements Exception {
  LockTakenException({required this.lockUserId});
  final String lockUserId;
  @override
  String toString() => 'Locked by $lockUserId';
}

class AlreadyHoldingLockException implements Exception {
  AlreadyHoldingLockException({required this.lineId});
  final String lineId;
  @override
  String toString() => 'Already holding lock for line $lineId';
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
  String toString() => 'Over-pick not allowed';
}

class BarcodeMismatchException implements Exception {
  BarcodeMismatchException(this.message);
  final String message;
  @override
  String toString() => message;
}

class TransferLinesRepository {
  TransferLinesRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _linesRef(String transferId) =>
      _db.collection('transfers').doc(transferId).collection('lines');

  DocumentReference<Map<String, dynamic>> _lineDoc(
    String transferId,
    String lineId,
  ) => _linesRef(transferId).doc(lineId);

  DocumentReference<Map<String, dynamic>> _userLockDoc(
    String transferId,
    String uid,
  ) => _db.collection('transfers').doc(transferId).collection('locks').doc(uid);

  DocumentReference<Map<String, dynamic>> _barcodeIndexDoc(String barcode) =>
      _db.collection('barcode_index').doc(barcode);

  Stream<List<TransferLine>> watchLines(String transferId) {
    // Allowed: only while details open.
    return _linesRef(transferId)
        .orderBy('category')
        .orderBy('article')
        .snapshots()
        .map((s) => s.docs.map(TransferLine.fromDoc).toList(growable: false));
  }

  /// B2 + B4:
  /// - line.lock set only if unlocked or expired
  /// - ALSO enforce "one active lock per transfer per user" via transfers/{transferId}/locks/{uid}
  Future<void> tryAcquireLock({
    required String transferId,
    required String lineId,
    required String userId,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final lineRef = _lineDoc(transferId, lineId);
    final userLockRef = _userLockDoc(transferId, userId);
    final now = DateTime.now();
    final expiresAt = now.add(ttl);

    await _db.runTransaction((tx) async {
      // 1) check existing user lock doc (prevents same user 2 devices)
      final userLockSnap = await tx.get(userLockRef);
      if (userLockSnap.exists) {
        final d = userLockSnap.data() ?? <String, dynamic>{};
        final ts = d['expiresAt'];
        final currentExpires = ts is Timestamp
            ? ts.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        final currentLineId = d['lineId'] as String? ?? '';

        if (DateTime.now().isBefore(currentExpires)) {
          // active lock exists
          throw AlreadyHoldingLockException(lineId: currentLineId);
        }
      }

      // 2) check line lock
      final lineSnap = await tx.get(lineRef);
      if (!lineSnap.exists) throw Exception('Line not found');
      final lineData = lineSnap.data() ?? <String, dynamic>{};

      final currentLock = TransferLineLock.fromMap(lineData['lock']);
      final lockActive = currentLock != null && !currentLock.isExpired;

      if (lockActive && currentLock.userId != userId) {
        throw LockTakenException(lockUserId: currentLock.userId);
      }

      // 3) write both lock locations
      tx.update(lineRef, {
        'lock': {'userId': userId, 'expiresAt': Timestamp.fromDate(expiresAt)},
      });

      tx.set(userLockRef, {
        'lineId': lineId,
        'expiresAt': Timestamp.fromDate(expiresAt),
      });
    });
  }

  /// B3 + B4:
  /// - only owner can clear
  /// - if expired, admin/storekeeper may clear (optional)
  /// - clear user lock doc only if it matches
  Future<void> releaseLock({
    required String transferId,
    required String lineId,
    required String userId,
    required UserRole role,
  }) async {
    final lineRef = _lineDoc(transferId, lineId);
    final userLockRef = _userLockDoc(transferId, userId);

    await _db.runTransaction((tx) async {
      final lineSnap = await tx.get(lineRef);
      if (!lineSnap.exists) return;
      final data = lineSnap.data() ?? <String, dynamic>{};

      final current = TransferLineLock.fromMap(data['lock']);
      if (current == null) return;

      final isOwner = current.userId == userId;
      final isExpired = current.isExpired;
      final canClearExpired =
          isExpired && (role == UserRole.admin || role == UserRole.storekeeper);

      if (!isOwner && !canClearExpired) {
        throw NotLockOwnerException();
      }

      // clear line lock
      tx.update(lineRef, {'lock': null});

      // clear user lock doc if it matches this line
      final ul = await tx.get(userLockRef);
      if (ul.exists) {
        final ud = ul.data() ?? <String, dynamic>{};
        final lockedLineId = ud['lineId'] as String? ?? '';
        if (lockedLineId == lineId) {
          tx.delete(userLockRef);
        }
      }
    });
  }

  /// C5: Race-free increment that also validates barcode->article
  Future<void> validateAndIncrementPicked({
    required String transferId,
    required String lineId,
    required String expectedArticle,
    required String barcode,
    required String userId,
    required UserRole role,
    bool autoReleaseOnComplete = true,
  }) async {
    final lineRef = _lineDoc(transferId, lineId);
    final userLockRef = _userLockDoc(transferId, userId);
    final barcodeRef = _barcodeIndexDoc(barcode);

    await _db.runTransaction((tx) async {
      // barcode -> article
      final barcodeSnap = await tx.get(barcodeRef);
      if (!barcodeSnap.exists) {
        throw BarcodeMismatchException('Unknown barcode');
      }
      final barcodeArticle = (barcodeSnap.data()?['article'] as String?) ?? '';
      if (barcodeArticle != expectedArticle) {
        throw BarcodeMismatchException('Barcode mismatch');
      }

      final lineSnap = await tx.get(lineRef);
      if (!lineSnap.exists) throw Exception('Line not found');
      final data = lineSnap.data() ?? <String, dynamic>{};

      final lock = TransferLineLock.fromMap(data['lock']);
      if (lock == null) throw NotLockOwnerException();
      if (lock.isExpired) throw LockExpiredException();
      if (lock.userId != userId) throw NotLockOwnerException();

      final planned = (data['qtyPlanned'] as num?)?.toInt() ?? 0;
      final picked = (data['qtyPicked'] as num?)?.toInt() ?? 0;

      if (picked >= planned) throw OverPickException();

      final nextPicked = picked + 1;
      tx.update(lineRef, {'qtyPicked': nextPicked});

      // Optional: auto-release lock when complete
      if (autoReleaseOnComplete && nextPicked >= planned) {
        tx.update(lineRef, {'lock': null});

        final ul = await tx.get(userLockRef);
        if (ul.exists) {
          final ud = ul.data() ?? <String, dynamic>{};
          final lockedLineId = ud['lineId'] as String? ?? '';
          if (lockedLineId == lineId) {
            tx.delete(userLockRef);
          }
        }
      }
    });
  }
}
