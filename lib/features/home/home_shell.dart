import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../app/router/providers.dart';
import '../../app/theme/locale_controller.dart';
import '../../data/models/user_profile.dart';
import '../admin/admin_users_screen.dart';
import '../admin/admin_products_screen.dart';
import '../products/products_list_screen.dart';
import '../transfers/transfers_list_screen.dart';
import 'schedule_planner_demo_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 1; // По умолчанию открываем список задач (самое важное)

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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      // Расширяем тело под навигацию и статус бар для эффекта погружения
      extendBody: true,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: Text(
          l10n.appTitle.toUpperCase(),
          style: const TextStyle(letterSpacing: 1.2),
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
      ),

      drawer: _buildDrawer(context, l10n, auth, profile, currentLocale),

      body: _pages[_currentIndex],

      bottomNavigationBar: _buildGlassBottomNav(theme, l10n),
    );
  }

  Widget _buildGlassBottomNav(ThemeData theme, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  label: 'Plan', // l10n.navHome (заменим позже на Planner)
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.swap_horiz,
                  activeIcon: Icons.swap_horiz,
                  label: l10n.navTransfers,
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  label: l10n.navCatalog,
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    AppLocalizations l10n,
    dynamic auth,
    UserProfile? profile,
    Locale currentLocale,
  ) {
    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF004B73), Color(0xFF121212)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      (profile?.email ?? 'G').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    auth.currentUser?.email ?? l10n.guest,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${profile?.role.name.toUpperCase() ?? '...'} • ${profile?.isActive == true ? l10n.active : l10n.inactive}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Язык
          ListTile(
            leading: const Icon(Icons.language, color: Colors.white70),
            title: Text(
              l10n.language,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                dropdownColor: const Color(0xFF1E1E1E),
                value: currentLocale,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                style: const TextStyle(color: Colors.white),
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) {
                    ref.read(localeProvider.notifier).setLocale(newLocale);
                  }
                },
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text('EN')),
                  DropdownMenuItem(value: Locale('ru'), child: Text('RU')),
                  DropdownMenuItem(value: Locale('kk'), child: Text('KZ')),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white10),

          if (profile?.role == UserRole.admin) ...[
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: Colors.orangeAccent,
              ),
              title: Text(
                l10n.adminUsers,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dataset, color: Colors.orangeAccent),
              title: Text(
                l10n.adminProducts,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminProductsScreen(),
                  ),
                );
              },
            ),
            const Divider(color: Colors.white10),
          ],

          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              l10n.logout,
              style: const TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              Navigator.pop(context);
              auth.signOut();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.white.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
