import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/providers.dart';
import '../admin/admin_users_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(firebaseAuthProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;

    final tabs = <Widget>[
      const Center(child: Text('Assignments (скоро)')), // TODO(l10n)
      const Center(child: Text('Tasks (скоро)')), // TODO(l10n)
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('User: ${auth.currentUser?.email ?? auth.currentUser?.uid}'),
            const SizedBox(height: 8),
            Text(
              'Role: ${profile?.role.name ?? '-'} | Active: ${profile?.isActive ?? false}',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => auth.signOut(),
              child: const Text('Выйти'), // TODO(l10n)
            ),
            const SizedBox(height: 12),
            if (profile?.role.name == 'admin')
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                  );
                },
                child: const Text('Admin: Users'),
              ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkladHelper'),
        actions: [
          IconButton(
            tooltip: 'Notifications', // TODO(l10n)
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment),
            label: 'Assignments',
          ),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
