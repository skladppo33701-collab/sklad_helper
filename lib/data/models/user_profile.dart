import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { guest, loader, storekeeper, admin }

UserRole roleFromString(String? v) {
  switch (v) {
    case 'loader':
      return UserRole.loader;
    case 'storekeeper':
      return UserRole.storekeeper;
    case 'admin':
      return UserRole.admin;
    case 'guest':
    default:
      return UserRole.guest;
  }
}

String roleToString(UserRole r) => r.name;

class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const UserProfile({
    required this.uid,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.lastLoginAt,
    this.email,
    this.displayName,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'role': roleToString(role),
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastLoginAt': Timestamp.fromDate(lastLoginAt),
  };

  static UserProfile fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime tsToDt(dynamic v) =>
        (v is Timestamp) ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

    return UserProfile(
      uid: doc.id,
      email: d['email'] as String?,
      displayName: d['displayName'] as String?,
      role: roleFromString(d['role'] as String?),
      isActive: (d['isActive'] as bool?) ?? false,
      createdAt: tsToDt(d['createdAt']),
      lastLoginAt: tsToDt(d['lastLoginAt']),
    );
  }
}
