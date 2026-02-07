import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer_line.dart';

class LockDeniedException implements Exception {
  LockDeniedException(this.message);
  final String message;
  @override
  String toString() => message;
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

  Future<void> tryAcquireLock({
    required String transferId,
    required String lineId,
    required String userId,
    Duration ttl = const Duration(minutes: 2),
  }) async {
    final ref = _lineDoc(transferId, lineId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Line not found');
      final data = snap.data() ?? <String, dynamic>{};

      final lockRaw = data['lock'];
      final current = TransferLineLock.fromMap(lockRaw);
      final now = DateTime.now();

      final lockedByOther =
          current != null && !current.isExpired && current.userId != userId;

      if (lockedByOther) {
        throw LockDeniedException('Locked by another user');
      }

      tx.update(ref, {
        'lock': {
          'userId': userId,
          'expiresAt': Timestamp.fromDate(now.add(ttl)),
        },
      });
    });
  }

  Future<void> releaseLock({
    required String transferId,
    required String lineId,
    required String userId,
  }) async {
    final ref = _lineDoc(transferId, lineId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? <String, dynamic>{};
      final current = TransferLineLock.fromMap(data['lock']);

      if (current == null) return;
      if (current.userId != userId) return; // only owner releases

      tx.update(ref, {'lock': null});
    });
  }

  /// Validates barcode via barcode_index/{barcode} -> article and increments qtyPicked by 1.
  /// - requires lock ownership (not expired)
  /// - caps at qtyPlanned
  Future<void> validateAndIncrementPicked({
    required String transferId,
    required String lineId,
    required String expectedArticle,
    required String barcode,
    required String userId,
  }) async {
    final lineRef = _lineDoc(transferId, lineId);
    final barcodeRef = _barcodeIndexDoc(barcode);

    await _db.runTransaction((tx) async {
      final barcodeSnap = await tx.get(barcodeRef);
      if (!barcodeSnap.exists) {
        throw BarcodeMismatchException('Unknown barcode');
      }
      final barcodeArticle = (barcodeSnap.data()?['article'] as String?) ?? '';
      if (barcodeArticle != expectedArticle) {
        throw BarcodeMismatchException('Barcode does not match this line');
      }

      final lineSnap = await tx.get(lineRef);
      if (!lineSnap.exists) throw Exception('Line not found');
      final data = lineSnap.data() ?? <String, dynamic>{};

      final currentLock = TransferLineLock.fromMap(data['lock']);
      if (currentLock == null ||
          currentLock.isExpired ||
          currentLock.userId != userId) {
        throw LockDeniedException('Lock required');
      }

      final planned = (data['qtyPlanned'] as num?)?.toInt() ?? 0;
      final picked = (data['qtyPicked'] as num?)?.toInt() ?? 0;

      if (picked >= planned) return; // already complete; no-op

      tx.update(lineRef, {'qtyPicked': picked + 1});
    });
  }
}
