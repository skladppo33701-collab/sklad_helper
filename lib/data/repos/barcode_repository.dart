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
          'Штрихкод уже привязан к артикулу: $existingArticle',
        );
      }

      final productSnap = await tx.get(productRef);
      if (!productSnap.exists) {
        throw Exception('Товар не найден: $article');
      }

      final currentBarcode = productSnap.data()?['barcode'] as String?;
      if (currentBarcode != null && currentBarcode.isNotEmpty) {
        if (currentBarcode != barcode) {
          throw ProductAlreadyBoundException(
            'У товара уже есть штрихкод: $currentBarcode',
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
  }
}
