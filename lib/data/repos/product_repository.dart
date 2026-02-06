import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductRepository {
  ProductRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  /// Free-tier friendly: one-time read (no listener) for list page.
  Future<List<Product>> fetchCatalogPage({
    String? startAfterArticle,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> q = _products
        .orderBy(FieldPath.documentId)
        .limit(limit);

    if (startAfterArticle != null && startAfterArticle.isNotEmpty) {
      q = q.startAfter([startAfterArticle]);
    }

    final snap = await q.get();
    return snap.docs.map(Product.fromDoc).toList(growable: false);
  }

  /// Exact article lookup (doc id).
  Future<Product?> getByArticle(String article) async {
    final doc = await _products.doc(article).get();
    if (!doc.exists) return null;
    return Product.fromDoc(doc);
  }

  /// Single-doc listener is acceptable (low cost) for detail screen freshness.
  Stream<Product?> watchByArticle(String article) {
    return _products.doc(article).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Product.fromDoc(doc);
    });
  }
}
