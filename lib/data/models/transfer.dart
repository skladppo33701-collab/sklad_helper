import 'package:cloud_firestore/cloud_firestore.dart';

enum TransferStatus { new_, picking, picked, checking, done }

class Transfer {
  final String transferId;
  final String title;
  final TransferStatus status;
  final DateTime createdAt;
  final String from;
  final String to;
  final int itemsTotal;
  final int pcsTotal;
  // НОВОЕ ПОЛЕ
  final bool isDeleted;

  Transfer({
    required this.transferId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.from,
    required this.to,
    this.itemsTotal = 0,
    this.pcsTotal = 0,
    this.isDeleted = false, // По умолчанию не удален
  });

  factory Transfer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Transfer(
      transferId: doc.id,
      title: data['title'] ?? 'Transfer ${doc.id}',
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      itemsTotal: (data['itemsTotal'] as num?)?.toInt() ?? 0,
      pcsTotal: (data['pcsTotal'] as num?)?.toInt() ?? 0,
      // Читаем флаг (если его нет в базе — считаем false)
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  static TransferStatus _parseStatus(String? s) {
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
}
