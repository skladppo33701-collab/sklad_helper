import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../features/catalog/catalog_screen.dart';
import '../../features/catalog/product_detail_screen.dart';
import '../../features/transfers/transfers_list_screen.dart';
import '../../features/transfers/transfer_detail_screen.dart';

import 'providers.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/waiting_activation_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(
      ref.read(firebaseAuthProvider).authStateChanges(),
    ),

    redirect: (context, state) {
      final isAuth = state.matchedLocation.startsWith('/auth');

      // DEMO MODE: if user is logged in -> always go to /home (ignore activation/profile)
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        return isAuth ? null : '/auth';
      }

      if (isAuth || state.matchedLocation == '/waiting') {
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
      GoRoute(
        path: '/home',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/product/:article',
        builder: (context, state) {
          final article = state.pathParameters['article']!;
          return ProductDetailScreen(article: article);
        },
      ),
      GoRoute(
        path: '/transfers',
        builder: (context, state) => const TransfersListScreen(),
      ),
      GoRoute(
        path: '/transfer/:transferId',
        builder: (context, state) {
          final id = state.pathParameters['transferId']!;
          return TransferDetailScreen(transferId: id);
        },
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
