import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/barcode_index_entry.dart';

// --- ИСКЛЮЧЕНИЯ (Обновлены для работы с ExceptionMapper) ---

class BarcodeConflictException implements Exception {
  // Храним артикул, который уже занят этим штрихкодом
  BarcodeConflictException(this.article);
  final String article;

  @override
  String toString() => 'BarcodeConflictException: $article';
}

class ProductAlreadyBoundException implements Exception {
  // Храним штрихкод, который уже есть у товара
  ProductAlreadyBoundException(this.barcode);
  final String barcode;

  @override
  String toString() => 'ProductAlreadyBoundException: $barcode';
}

class ProductNotFoundException implements Exception {
  ProductNotFoundException(this.article);
  final String article;

  @override
  String toString() => 'ProductNotFoundException: $article';
}

// -----------------------------------------------------------

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

        // ИСПРАВЛЕНО: Передаем данные (артикул), а не текст
        throw BarcodeConflictException(existingArticle);
      }

      final productSnap = await tx.get(productRef);
      if (!productSnap.exists) {
        // ИСПРАВЛЕНО: Используем типизированное исключение
        throw ProductNotFoundException(article);
      }

      final currentBarcode = productSnap.data()?['barcode'] as String?;
      if (currentBarcode != null &&
          currentBarcode.isNotEmpty &&
          currentBarcode != barcode) {
        // ИСПРАВЛЕНО: Передаем данные (штрихкод), а не текст
        throw ProductAlreadyBoundException(currentBarcode);
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
