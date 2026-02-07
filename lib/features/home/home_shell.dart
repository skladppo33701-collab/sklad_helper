import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/providers.dart';
import '../admin/admin_users_screen.dart';

/// Оболочка с нижней навигацией (Shell)
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
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
      // Здесь отображается текущий активный экран (Branch)
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.swap_horiz,
            ), // Изменил иконку на более подходящую для трансферов
            label: 'Transfers', // Было "Assignments"
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2), // Иконка для каталога
            label: 'Catalog', // Было "Tasks"
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Вынесенная логика вкладки Профиль (бывший Tab 2)
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(firebaseAuthProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;

    return Center(
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
    );
  }
}
