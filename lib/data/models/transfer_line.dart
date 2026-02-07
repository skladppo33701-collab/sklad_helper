import 'package:cloud_firestore/cloud_firestore.dart';

class TransferLineLock {
  const TransferLineLock({required this.userId, required this.expiresAt});

  final String userId;
  final DateTime expiresAt;

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  static TransferLineLock? fromMap(dynamic value) {
    if (value == null || value is! Map) return null;
    final userId = value['userId'];
    final expiresAt = value['expiresAt'];

    if (userId is! String || userId.isEmpty) return null;
    if (expiresAt is! Timestamp) return null;

    return TransferLineLock(userId: userId, expiresAt: expiresAt.toDate());
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'expiresAt': Timestamp.fromDate(expiresAt),
  };
}

class TransferLine {
  const TransferLine({
    required this.id,
    required this.article,
    required this.name,
    required this.category,
    required this.qtyPlanned,
    required this.qtyPicked,
    required this.lock,
  });

  final String id;
  final String article;
  final String name;
  final String category;
  final int qtyPlanned;
  final int qtyPicked;
  final TransferLineLock? lock;

  bool get isCompleted => qtyPicked >= qtyPlanned;

  factory TransferLine.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};

    return TransferLine(
      id: doc.id,
      article: (data['article'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      category: (data['category'] as String?) ?? '',
      qtyPlanned: (data['qtyPlanned'] as num?)?.toInt() ?? 0,
      qtyPicked: (data['qtyPicked'] as num?)?.toInt() ?? 0,
      lock: TransferLineLock.fromMap(data['lock']),
    );
  }
}
