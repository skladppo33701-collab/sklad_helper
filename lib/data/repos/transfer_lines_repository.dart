import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer_line.dart';
import '../../utils/app_exceptions.dart'; // <--- Импортируем общие исключения

class TransferLinesRepository {
  TransferLinesRepository(this._db);
  final FirebaseFirestore _db;

  Future<void> acquireLock({
    required String transferId,
    required String lineId,
    required String userId,
  }) async {
    final ref = _db
        .collection('transfers')
        .doc(transferId)
        .collection('lines')
        .doc(lineId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw LineNotFoundException();

      final data = snap.data()!;
      // Тут логика проверки (упрощено)
      final currentLock = data['pickedLock'];
      if (currentLock != null) {
        // Проверка на занятость...
      }

      tx.update(ref, {
        'pickedLock': {
          'userId': userId,
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(minutes: 5)),
          ),
        },
      });
    });
  }

  Future<void> releaseLock({
    required String transferId,
    required String lineId,
    required String userId,
  }) async {
    final ref = _db
        .collection('transfers')
        .doc(transferId)
        .collection('lines')
        .doc(lineId);
    await ref.update({'pickedLock': FieldValue.delete()});
  }

  Future<void> incrementPicked({
    required String transferId,
    required String lineId,
    required String userId,
    bool autoReleaseOnComplete = false,
  }) async {
    final ref = _db
        .collection('transfers')
        .doc(transferId)
        .collection('lines')
        .doc(lineId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw LineNotFoundException();
      final data = snap.data()!; // Теперь data используется

      final current = (data['qtyPicked'] as num?)?.toInt() ?? 0;
      final planned = (data['qtyPlanned'] as num?)?.toInt() ?? 0;

      if (current >= planned) throw OverPickException();

      tx.update(ref, {'qtyPicked': FieldValue.increment(1)});

      if (autoReleaseOnComplete && (current + 1 >= planned)) {
        tx.update(ref, {'pickedLock': FieldValue.delete()});
      }
    });
  }

  Future<void> acquireCheckLock({
    required String transferId,
    required String lineId,
    required String userId,
  }) async {}
  Future<void> releaseCheckLock({
    required String transferId,
    required String lineId,
    required String userId,
  }) async {}

  Future<void> incrementChecked({
    required String transferId,
    required String lineId,
    required String userId,
    bool autoReleaseOnComplete = false,
  }) async {
    final ref = _db
        .collection('transfers')
        .doc(transferId)
        .collection('lines')
        .doc(lineId);
    await ref.update({'qtyChecked': FieldValue.increment(1)});
  }

  Stream<List<TransferLine>> watchLines(String transferId) {
    return _db
        .collection('transfers')
        .doc(transferId)
        .collection('lines')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            return TransferLine.fromMap(doc.id, doc.data());
          }).toList();
        });
  }
}
