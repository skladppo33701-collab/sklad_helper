import 'package:cloud_firestore/cloud_firestore.dart';

class TransferLineLock {
  final String userId;
  final DateTime expiresAt;

  const TransferLineLock({required this.userId, required this.expiresAt});

  static TransferLineLock? fromMap(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final userId = raw['userId'] as String?;
    final ts = raw['expiresAt'];
    if (userId == null || ts is! Timestamp) return null;
    return TransferLineLock(userId: userId, expiresAt: ts.toDate());
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'expiresAt': Timestamp.fromDate(expiresAt),
  };

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class TransferLine {
  final String lineId; // doc id
  final String article;
  final String name;
  final String category;
  final int qtyPlanned;
  final int qtyPicked;
  final TransferLineLock? lock;

  const TransferLine({
    required this.lineId,
    required this.article,
    required this.name,
    required this.category,
    required this.qtyPlanned,
    required this.qtyPicked,
    required this.lock,
  });

  static TransferLine fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return TransferLine(
      lineId: doc.id,
      article: (d['article'] as String?) ?? '',
      name: (d['name'] as String?) ?? '',
      category: (d['category'] as String?) ?? '',
      qtyPlanned: (d['qtyPlanned'] as num?)?.toInt() ?? 0,
      qtyPicked: (d['qtyPicked'] as num?)?.toInt() ?? 0,
      lock: TransferLineLock.fromMap(d['lock']),
    );
  }
}
