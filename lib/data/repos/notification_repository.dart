import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  Stream<List<AppNotification>> watchRecentForUser({
    required String uid,
    required String role,
    required DateTime since,
    int limit = 50,
  }) {
    // MVP: single channel via audience contains 'staff' (no fanout, free-tier safe).
    return _col
        .where('audience', arrayContains: 'staff')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (q) => q.docs.map(AppNotification.fromDoc).toList(growable: false),
        );
  }

  Future<void> markSeen({required String uid, required DateTime seenAt}) async {
    await _db.collection('users').doc(uid).update({
      'notificationsLastSeenAt': Timestamp.fromDate(seenAt),
    });
  }

  Future<void> createNotification(AppNotification n) async {
    await _col.add({
      ...n.toMap(),
      // Use server time for ordering consistency
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
