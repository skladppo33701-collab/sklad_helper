import 'package:cloud_firestore/cloud_firestore.dart';

class BarcodeIndexEntry {
  final String barcode; // doc id
  final String article;
  final DateTime createdAt;
  final String createdBy;

  const BarcodeIndexEntry({
    required this.barcode,
    required this.article,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
    'barcode': barcode,
    'article': article,
    'createdAt': Timestamp.fromDate(createdAt),
    'createdBy': createdBy,
  };
}
