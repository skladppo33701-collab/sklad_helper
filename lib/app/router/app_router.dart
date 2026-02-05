import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

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
      final profileAsync = ref.read(userProfileProvider);
      final profile = profileAsync.asData?.value;
      final isWaiting = state.matchedLocation == '/waiting';

      // profile may still be loading; allow navigation but steer away from /home until ready
      if (profileAsync.isLoading || profile == null) {
        return isWaiting ? null : '/waiting';
      }

      if (!profile.isActive) {
        return isWaiting ? null : '/waiting';
      }

      // Active user
      if (isLoggingIn || isWaiting) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/waiting',
        builder: (context, state) => const WaitingActivationScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
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
