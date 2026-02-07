import 'package:cloud_firestore/cloud_firestore.dart';

class TransferEvent {
  final String eventId;
  final String type;
  final DateTime at;
  final String by;
  final Map<String, dynamic>? payload;

  const TransferEvent({
    required this.eventId,
    required this.type,
    required this.at,
    required this.by,
    this.payload,
  });

  static TransferEvent fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final ts = d['at'];
    return TransferEvent(
      eventId: doc.id,
      type: (d['type'] as String?) ?? '',
      at: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      by: (d['by'] as String?) ?? '',
      payload: d['payload'] as Map<String, dynamic>?,
    );
  }
}
