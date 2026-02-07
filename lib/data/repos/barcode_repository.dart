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

  /// One doc read. Used by loader picking flow.
  Future<String?> resolveArticleByBarcode(String barcode) async {
    final snap = await _barcodeIndex.doc(barcode).get();
    if (!snap.exists) return null;
    final data = snap.data();
    final article = data?['article'];
    return (article is String && article.isNotEmpty) ? article : null;
  }

  /// Enforces 1:1 mapping via barcode_index/{barcode}.
  /// - If barcode_index exists => conflict error.
  /// - Else create barcode_index and update products/{article}.barcode in ONE transaction.
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
          'Barcode already bound to: $existingArticle', // TODO(l10n)
        );
      }

      final productSnap = await tx.get(productRef);
      if (!productSnap.exists) {
        throw Exception('Product not found: $article'); // TODO(l10n)
      }

      final currentBarcode = productSnap.data()?['barcode'] as String?;
      if (currentBarcode != null &&
          currentBarcode.isNotEmpty &&
          currentBarcode != barcode) {
        throw ProductAlreadyBoundException(
          'Product already has barcode: $currentBarcode', // TODO(l10n)
        );
      }

      final entry = BarcodeIndexEntry(
        barcode: barcode,
        article: article,
        createdAt: DateTime.now(),
        createdBy: createdByUid,
      );

      tx.set(barcodeRef, entry.toMap());
      tx.update(productRef, {'barcode': barcode});
    });
  }
}
