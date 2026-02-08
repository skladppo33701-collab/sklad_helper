import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushTokenRepository {
  PushTokenRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore db,
    FirebaseMessaging? messaging,
  }) : _auth = auth,
       _db = db,
       _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseMessaging _messaging;

  /// Call once after login + profile load.
  /// Free-tier safe: 1 token read + 1 user doc merge write if needed.
  Future<void> registerTokenIfNeeded() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (Platform.isIOS) {
      // Minimal iOS permission request
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _db.collection('users').doc(user.uid).set({
      'fcmTokens': {token: true},
    }, SetOptions(merge: true));
  }

  /// Hook this once; it keeps user doc updated when FCM rotates token.
  void listenTokenRefresh() {
    final user = _auth.currentUser;
    if (user == null) return;

    _messaging.onTokenRefresh.listen((token) async {
      if (token.isEmpty) return;
      await _db.collection('users').doc(user.uid).set({
        'fcmTokens': {token: true},
      }, SetOptions(merge: true));
    });
  }

  Future<void> unregisterToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({
      'fcmTokens.$token': FieldValue.delete(),
    });
  }
}
