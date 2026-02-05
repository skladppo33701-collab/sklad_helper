import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';
import '../../data/models/user_profile.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(firestoreProvider);
    final repo = ref.watch(userRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Users')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final uid = docs[i].id;
              final email = d['email'] as String? ?? uid;
              final role = roleFromString(d['role'] as String?);
              final isActive = (d['isActive'] as bool?) ?? false;

              return ListTile(
                title: Text(email),
                subtitle: Text('role=${role.name} active=$isActive'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'activate_loader') {
                      await repo.adminSetRoleAndActive(
                        uid: uid,
                        role: UserRole.loader,
                        isActive: true,
                      );
                    } else if (v == 'activate_storekeeper') {
                      await repo.adminSetRoleAndActive(
                        uid: uid,
                        role: UserRole.storekeeper,
                        isActive: true,
                      );
                    } else if (v == 'activate_admin') {
                      await repo.adminSetRoleAndActive(
                        uid: uid,
                        role: UserRole.admin,
                        isActive: true,
                      );
                    } else if (v == 'deactivate') {
                      await repo.adminSetRoleAndActive(
                        uid: uid,
                        role: UserRole.guest,
                        isActive: false,
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'activate_loader',
                      child: Text('Activate as loader'),
                    ),
                    PopupMenuItem(
                      value: 'activate_storekeeper',
                      child: Text('Activate as storekeeper'),
                    ),
                    PopupMenuItem(
                      value: 'activate_admin',
                      child: Text('Activate as admin'),
                    ),
                    PopupMenuItem(
                      value: 'deactivate',
                      child: Text('Deactivate (guest)'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
