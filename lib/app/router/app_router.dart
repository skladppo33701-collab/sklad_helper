import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';
import 'package:sklad_helper/app/router/providers.dart';
import 'package:sklad_helper/features/auth/auth_screen.dart';
import 'package:sklad_helper/features/auth/waiting_activation_screen.dart';
import 'package:sklad_helper/features/home/home_shell.dart';
import 'package:sklad_helper/features/transfers/transfer_detail_screen.dart';
import 'package:sklad_helper/features/transfers/transfers_list_screen.dart';

/// Forces GoRouter to refresh when streams emit.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Auth changes should refresh router.
  final auth = ref.watch(firebaseAuthProvider);

  // IMPORTANT: watch profile so router rebuilds when user gets activated.
  final profileAsync = ref.watch(userProfileProvider);
  final profile = profileAsync.asData?.value;

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/waiting',
        builder: (context, state) => const WaitingActivationScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const TransfersListScreen(),
          ),
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
        ],
      ),
    ],
    redirect: (context, state) {
      final user = auth.currentUser;

      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isWaitingRoute = state.matchedLocation.startsWith('/waiting');

      // 1) Not signed in -> /auth
      if (user == null) {
        return isAuthRoute ? null : '/auth';
      }

      // 2) Signed in, but profile not loaded yet -> don't redirect (avoid loops)
      if (profile == null) {
        return null;
      }

      // 3) Signed in, but inactive -> /waiting only
      if (!profile.isActive) {
        return isWaitingRoute ? null : '/waiting';
      }

      // 4) Active staff -> block /auth and /waiting
      if (isAuthRoute || isWaitingRoute) {
        return '/home';
      }

      return null;
    },
  );
});
