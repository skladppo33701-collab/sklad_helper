import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin/admin_products_screen.dart';
import '../../app/router/providers.dart';
import '../../app/theme/locale_controller.dart';
import '../../data/models/user_profile.dart';
import '../admin/admin_users_screen.dart';
import '../products/products_list_screen.dart';
import '../transfers/transfers_list_screen.dart';
import 'schedule_planner_demo_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  final _pages = const [
    SchedulePlannerDemoScreen(),
    TransfersListScreen(),
    ProductsListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(firebaseAuthProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('SkladHelper')),
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Transfers',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      auth.currentUser?.email ?? 'Guest',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile?.role.name ?? '...'} • ${profile?.isActive == true ? 'Active' : 'Inactive'}',
                      // ИСПРАВЛЕНО: используем apply() для изменения цвета/прозрачности
                      style: Theme.of(context).textTheme.labelMedium?.apply(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- ЯЗЫКОВОЙ БЛОК ---
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: Text(_getLanguageName(currentLocale.languageCode)),
              trailing: PopupMenuButton<Locale>(
                icon: const Icon(Icons.arrow_drop_down),
                onSelected: (Locale newLocale) {
                  ref.read(localeProvider.notifier).setLocale(newLocale);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: Locale('en'),
                    child: Text('English 🇺🇸'),
                  ),
                  PopupMenuItem(
                    value: Locale('ru'),
                    child: Text('Русский 🇷🇺'),
                  ),
                  PopupMenuItem(
                    value: Locale('kk'),
                    child: Text('Қазақша 🇰🇿'),
                  ),
                ],
              ),
            ),
            const Divider(),
            if (profile?.role == UserRole.admin) ...[
              // Группируем админские кнопки
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin: Users'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                  );
                },
              ),
              // НОВАЯ КНОПКА
              ListTile(
                leading: const Icon(Icons.dataset),
                title: const Text('Admin: Products DB'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminProductsScreen(),
                    ), // Импортируйте экран
                  );
                },
              ),
            ],
            const Divider(),
            // ---------------------
            if (profile?.role == UserRole.admin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin: Users'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                  );
                },
              ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () async {
                Navigator.of(context).pop();
                await auth.signOut();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      case 'kk':
        return 'Қазақша';
      default:
        return code.toUpperCase();
    }
  }
}
