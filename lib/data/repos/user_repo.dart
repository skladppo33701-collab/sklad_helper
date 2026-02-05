import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserRepo {
  UserRepo(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromDoc(doc);
    });
  }

  Future<UserProfile> upsertOnLogin({
    required String uid,
    required String? email,
    required String? displayName,
  }) async {
    final ref = _users.doc(uid);
    final snap = await ref.get();
    final now = DateTime.now();

    if (!snap.exists) {
      final profile = UserProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        role: UserRole.guest,
        isActive: false,
        createdAt: now,
        lastLoginAt: now,
      );
      await ref.set(profile.toMap());
      return profile;
    } else {
      await ref.update({
        'email': email,
        'displayName': displayName,
        'lastLoginAt': Timestamp.fromDate(now),
      });
      final updated = await ref.get();
      return UserProfile.fromDoc(updated);
    }
  }

  Future<void> adminSetRoleAndActive({
    required String uid,
    required UserRole role,
    required bool isActive,
  }) async {
    await _users.doc(uid).update({
      'role': roleToString(role),
      'isActive': isActive,
    });
  }
}
