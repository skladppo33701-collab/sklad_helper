import 'package:cloud_firestore/cloud_firestore.dart';

enum TransferStatus { new_, picking, picked, checking, done }

TransferStatus transferStatusFromString(String s) {
  switch (s) {
    case 'new':
      return TransferStatus.new_;
    case 'picking':
      return TransferStatus.picking;
    case 'picked':
      return TransferStatus.picked;
    case 'checking':
      return TransferStatus.checking;
    case 'done':
      return TransferStatus.done;
    default:
      return TransferStatus.new_;
  }
}

String transferStatusToString(TransferStatus s) {
  switch (s) {
    case TransferStatus.new_:
      return 'new';
    case TransferStatus.picking:
      return 'picking';
    case TransferStatus.picked:
      return 'picked';
    case TransferStatus.checking:
      return 'checking';
    case TransferStatus.done:
      return 'done';
  }
}

class Transfer {
  final String transferId; // doc id
  final String title;
  final DateTime createdAt;
  final String createdBy;
  final TransferStatus status;
  final Map<String, dynamic>? flags;
  final Map<String, dynamic>? stats;

  const Transfer({
    required this.transferId,
    required this.title,
    required this.createdAt,
    required this.createdBy,
    required this.status,
    this.flags,
    this.stats,
  });

  static Transfer fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final ts = d['createdAt'];
    return Transfer(
      transferId: (d['transferId'] as String?) ?? doc.id,
      title: (d['title'] as String?) ?? doc.id,
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      createdBy: (d['createdBy'] as String?) ?? '',
      status: transferStatusFromString((d['status'] as String?) ?? 'new'),
      flags: d['flags'] as Map<String, dynamic>?,
      stats: d['stats'] as Map<String, dynamic>?,
    );
  }
}
