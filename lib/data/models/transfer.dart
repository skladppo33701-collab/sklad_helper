import 'package:cloud_firestore/cloud_firestore.dart';

enum TransferStatus { newTx, picking, picked, checking, done, cancelled }

class Transfer {
  final String transferId;
  final String title;
  final TransferStatus status;
  final int itemsTotal;
  final int pcsTotal;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? checkerUid;

  const Transfer({
    required this.transferId,
    required this.title,
    required this.status,
    required this.itemsTotal,
    required this.pcsTotal,
    this.createdAt,
    this.updatedAt,
    this.checkerUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'transferId': transferId,
      'title': title,
      'status': status.name,
      'itemsTotal': itemsTotal,
      'pcsTotal': pcsTotal,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
      'checkerUid': checkerUid,
    };
  }

  factory Transfer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Transfer(
      transferId: doc.id,
      title: data['title'] ?? '',
      status: _parseStatus(data['status']),
      itemsTotal: (data['itemsTotal'] as num?)?.toInt() ?? 0,
      pcsTotal: (data['pcsTotal'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      checkerUid: data['checkerUid'],
    );
  }

  static TransferStatus _parseStatus(String? val) {
    if (val == 'new' || val == 'new_tx') return TransferStatus.newTx;
    return TransferStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => TransferStatus.newTx,
    );
  }
}
