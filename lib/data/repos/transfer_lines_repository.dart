import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer_line.dart';
import '../models/user_profile.dart';

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

  // Grace window to reduce client clock-skew issues (MVP).
  static const Duration _clockSkewGrace = Duration(seconds: 10);

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
    // Allowed: stream lines only while details screen is open.
    return _linesRef(transferId)
        .orderBy('category')
        .orderBy('article')
        .snapshots()
        .map((s) => s.docs.map(TransferLine.fromDoc).toList(growable: false));
  }

  /// Acquire lock for a line using transaction:
  /// - allow if line.lock is null or expired
  /// - deny if locked by other (not expired)
  /// Also enforces "one active lock per transfer per user" using:
  /// transfers/{transferId}/locks/{uid} -> { lineId, expiresAt }
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
      // 1) Check existing user lock doc to prevent same user holding 2 locks (2 devices)
      final userLockSnap = await tx.get(userLockRef);
      if (userLockSnap.exists) {
        final d = userLockSnap.data() ?? <String, dynamic>{};
        final ts = d['expiresAt'];
        final currentExpires = ts is Timestamp
            ? ts.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        final currentLineId = d['lineId'] as String? ?? '';

        // active if expiresAt is sufficiently in the future
        final isActive = currentExpires.isAfter(
          DateTime.now().add(_clockSkewGrace),
        );
        if (isActive) {
          throw AlreadyHoldingLockException(lineId: currentLineId);
        }
      }

      // 2) Check line lock
      final lineSnap = await tx.get(lineRef);
      if (!lineSnap.exists) throw Exception('Line not found');
      final lineData = lineSnap.data() ?? <String, dynamic>{};

      final currentLock = TransferLineLock.fromMap(lineData['lock']);
      final lockActive =
          currentLock != null &&
          currentLock.expiresAt.isAfter(DateTime.now().add(_clockSkewGrace));

      if (lockActive && currentLock.userId != userId) {
        throw LockTakenException(lockUserId: currentLock.userId);
      }

      // 3) Write both lock locations
      tx.update(lineRef, {
        'lock': {'userId': userId, 'expiresAt': Timestamp.fromDate(expiresAt)},
      });

      tx.set(userLockRef, {
        'lineId': lineId,
        'expiresAt': Timestamp.fromDate(expiresAt),
      });
    });
  }

  /// Release lock:
  /// - owner can clear anytime
  /// - if expired, storekeeper/admin can clear as well (support)
  /// Also clears user lock doc if it matches this line.
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

      final now = DateTime.now();
      final isExpired = current.expiresAt.isBefore(
        now.subtract(_clockSkewGrace),
      );
      final canClearExpired =
          isExpired && (role == UserRole.admin || role == UserRole.storekeeper);

      if (!isOwner && !canClearExpired) {
        throw NotLockOwnerException();
      }

      tx.update(lineRef, {'lock': null});

      // Clear user lock doc if it matches this line
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

  /// Validates barcode via barcode_index/{barcode} -> article and increments qtyPicked by +1.
  /// Transaction:
  /// - verify barcode maps to expectedArticle
  /// - verify lock exists, owned by caller, and not expired
  /// - verify qtyPicked < qtyPlanned
  /// - update qtyPicked += 1
  /// - optionally auto-release lock when complete (also removes user lock doc)
  Future<void> validateAndIncrementPicked({
    required String transferId,
    required String lineId,
    required String expectedArticle,
    required String barcode,
    required String userId,
    required UserRole
    role, // kept for API symmetry; not required by MVP logic here
    bool autoReleaseOnComplete = true,
  }) async {
    final lineRef = _lineDoc(transferId, lineId);
    final userLockRef = _userLockDoc(transferId, userId);
    final barcodeRef = _barcodeIndexDoc(barcode);

    await _db.runTransaction((tx) async {
      // 1) barcode -> article
      final barcodeSnap = await tx.get(barcodeRef);
      if (!barcodeSnap.exists) {
        throw BarcodeMismatchException('Unknown barcode');
      }
      final barcodeArticle = (barcodeSnap.data()?['article'] as String?) ?? '';
      if (barcodeArticle != expectedArticle) {
        throw BarcodeMismatchException('Barcode mismatch');
      }

      // 2) read line and validate lock
      final lineSnap = await tx.get(lineRef);
      if (!lineSnap.exists) throw Exception('Line not found');
      final data = lineSnap.data() ?? <String, dynamic>{};

      final lock = TransferLineLock.fromMap(data['lock']);
      if (lock == null) throw NotLockOwnerException();
      if (lock.userId != userId) throw NotLockOwnerException();

      final now = DateTime.now();
      final expired = lock.expiresAt.isBefore(now.subtract(_clockSkewGrace));
      if (expired) throw LockExpiredException();

      // 3) qty rules
      final planned = (data['qtyPlanned'] as num?)?.toInt() ?? 0;
      final picked = (data['qtyPicked'] as num?)?.toInt() ?? 0;

      if (picked >= planned) throw OverPickException();

      final nextPicked = picked + 1;
      tx.update(lineRef, {'qtyPicked': nextPicked});

      // 4) optional auto-release when complete
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
