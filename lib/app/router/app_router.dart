import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/auth/waiting_activation_screen.dart';
import '../../features/catalog/product_detail_screen.dart'; // <--- Импорт
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

      if (user == null) return isAuthRoute ? null : '/auth';

      final profileAsync = ref.read(userProfileProvider);
      final profile = profileAsync.asData?.value;
      if (profile == null) return null;

      if (!profile.isActive) return isWaitingRoute ? null : '/waiting';

      if (isAuthRoute || isWaitingRoute) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/waiting',
        builder: (context, state) => const WaitingActivationScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
      GoRoute(
        path: '/transfers',
        builder: (context, state) => const TransfersListScreen(),
      ),
      GoRoute(
        path: '/transfer/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TransferDetailScreen(transferId: id);
        },
      ),
      // --- ДОБАВЛЕН МАРШРУТ ---
      GoRoute(
        path: '/product/:article',
        builder: (context, state) {
          final article = state.pathParameters['article']!;
          return ProductDetailScreen(article: article);
        },
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _authSub = _ref.read(firebaseAuthProvider).authStateChanges().listen((_) {
      notifyListeners();
    });
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
