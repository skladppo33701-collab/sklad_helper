import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/barcode_index_entry.dart';

class BarcodeConflictException implements Exception {
  BarcodeConflictException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ProductAlreadyBoundException implements Exception {
  ProductAlreadyBoundException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BarcodeRepository {
  BarcodeRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _barcodeIndex =>
      _db.collection('barcode_index');
  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  Future<void> _emitNotification({
    required String type,
    required String title,
    required String body,
    required String byUid,
    String? transferId,
    List<String> audience = const ['staff'],
    String severity = 'info',
  }) async {
    await _db.collection('notifications').add({
      'type': type,
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': byUid,
      'transferId': transferId,
      'severity': severity,
      'audience': audience,
    });
  }

  Future<String?> resolveArticleByBarcode(String barcode) async {
    final snap = await _db.collection('barcode_index').doc(barcode).get();
    if (!snap.exists) return null;

    final data = snap.data();
    final article = data?['article'];

    return (article is String && article.isNotEmpty) ? article : null;
  }

  /// Enforces 1:1 mapping via barcode_index/{barcode} doc existence check.
  /// Flow:
  /// - if barcode_index doc exists => conflict
  /// - else create barcode_index doc + update product.barcode (single transaction)
  Future<void> bindBarcode({
    required String article,
    required String barcode,
    required String createdByUid,
  }) async {
    final barcodeRef = _barcodeIndex.doc(barcode);
    final productRef = _products.doc(article);

    await _db.runTransaction((tx) async {
      final barcodeSnap = await tx.get(barcodeRef);
      if (barcodeSnap.exists) {
        final existingArticle =
            (barcodeSnap.data()?['article'] as String?) ?? 'unknown';
        throw BarcodeConflictException(
          'Штрихкод уже привязан к артикулу: $existingArticle', // TODO(l10n)
        );
      }

      final productSnap = await tx.get(productRef);
      if (!productSnap.exists) {
        throw Exception('Товар не найден: $article'); // TODO(l10n)
      }

      final currentBarcode = productSnap.data()?['barcode'] as String?;
      if (currentBarcode != null && currentBarcode.isNotEmpty) {
        if (currentBarcode != barcode) {
          throw ProductAlreadyBoundException(
            'У товара уже есть штрихкод: $currentBarcode', // TODO(l10n)
          );
        }
        // same barcode -> idempotent; still ensure barcode_index exists
      }

      final now = DateTime.now();
      final entry = BarcodeIndexEntry(
        barcode: barcode,
        article: article,
        createdAt: now,
        createdBy: createdByUid,
      );

      tx.set(barcodeRef, entry.toMap());
      tx.update(productRef, {'barcode': barcode});
    });

    await _emitNotification(
      type: 'barcode_bound',
      title: 'Barcode bound', // TODO(l10n)
      body: 'Barcode $barcode → $article', // TODO(l10n)
      byUid: createdByUid,
      audience: const ['staff'],
    );
  }
}
