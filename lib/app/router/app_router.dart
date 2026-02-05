import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../features/home/schedule_demo_screen.dart';

import 'providers.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/waiting_activation_screen.dart';
import '../../features/home/home_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(
      ref.read(firebaseAuthProvider).authStateChanges(),
    ),

    redirect: (context, state) {
      final auth = ref.read(authStateProvider);

      final isLoggingIn = state.matchedLocation.startsWith('/auth');

      // auth loading
      if (auth.isLoading) return isLoggingIn ? null : '/auth';

      final user = auth.asData?.value;
      if (user == null) {
        return isLoggingIn ? null : '/auth';
      }

      // if logged in, check activation

      final isWaiting = state.matchedLocation == '/waiting';

      // DEMO MODE (temporary): as soon as user is logged in, allow /home
      // This is ONLY for previewing the UI. We will revert after UI is approved.
      if (isLoggingIn || isWaiting) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/waiting',
        builder: (context, state) => const WaitingActivationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const ScheduleDemoScreen(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
