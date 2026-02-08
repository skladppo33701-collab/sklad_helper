import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/auth/waiting_activation_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/transfers/transfer_detail_screen.dart';
import '../../features/transfers/transfers_list_screen.dart';
import 'providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(firebaseAuthProvider).currentUser;

      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isWaitingRoute = state.matchedLocation == '/waiting';

      // 1) Если не вошли -> на экран входа
      if (user == null) {
        return isAuthRoute ? null : '/auth';
      }

      // 2) Если вошли, но профиль еще грузится -> ждем
      final profileAsync = ref.read(userProfileProvider);
      final profile = profileAsync.asData?.value;
      if (profile == null) return null;

      // 3) Если пользователь не активен -> на экран ожидания
      if (!profile.isActive) {
        return isWaitingRoute ? null : '/waiting';
      }

      // 4) Если активен, но пытается зайти на auth/waiting -> домой
      if (isAuthRoute || isWaitingRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/waiting',
        builder: (context, state) => const WaitingActivationScreen(),
      ),

      // HomeShell теперь обычный экран, который сам внутри управляет табами
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),

      // Отдельные экраны
      GoRoute(
        path: '/transfers',
        builder: (context, state) => const TransfersListScreen(),
      ),

      // Детали трансфера
      GoRoute(
        path: '/transfer/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TransferDetailScreen(transferId: id);
        },
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    // Слушаем изменения авторизации
    _authSub = _ref.read(firebaseAuthProvider).authStateChanges().listen((_) {
      notifyListeners();
    });

    // Слушаем изменения профиля (активация, роль)
    _ref.listen(userProfileProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
  StreamSubscription? _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
