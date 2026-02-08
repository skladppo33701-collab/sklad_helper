import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/locale_controller.dart';
import 'features/notifications/push_navigation_bootstrap.dart';
import 'features/notifications/push_providers.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- НАСТРОЙКА ОФЛАЙН РЕЖИМА ---
  // Включаем долгосрочное хранение данных на устройстве
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Не ограничиваем кэш
  );
  // -------------------------------

  runApp(const ProviderScope(child: SkladHelperApp()));
}

class SkladHelperApp extends ConsumerWidget {
  const SkladHelperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    // Инициализация пушей
    ref.watch(pushBootstrapProvider);
    ref.watch(pushNavigationBootstrapProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SkladHelper',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      // Локализация
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      routerConfig: router,
    );
  }
}
