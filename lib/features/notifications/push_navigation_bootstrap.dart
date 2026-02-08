import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';

final pushNavigationBootstrapProvider = Provider<void>((ref) {
  final router = ref.read(appRouterProvider);

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final transferId = message.data['transferId']?.toString();
    if (transferId == null || transferId.isEmpty) return;
    router.go('/transfer/$transferId');
  });

  Future.microtask(() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    final transferId = initial?.data['transferId']?.toString();
    if (transferId == null || transferId.isEmpty) return;
    router.go('/transfer/$transferId');
  });
});
