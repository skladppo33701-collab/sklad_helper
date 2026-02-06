import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String article; // doc id
  final String name;
  final String category;
  final String? barcode;

  const Product({
    required this.article,
    required this.name,
    required this.category,
    this.barcode,
  });

  static Product fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Product(
      article: (d['article'] as String?) ?? doc.id,
      name: (d['name'] as String?) ?? '',
      category: (d['category'] as String?) ?? '',
      barcode: d['barcode'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'article': article,
    'name': name,
    'category': category,
    if (barcode != null) 'barcode': barcode,
  };
}
