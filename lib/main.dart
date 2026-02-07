import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'package:sklad_helper/features/notifications/push_navigation_bootstrap.dart';
import 'package:sklad_helper/features/notifications/push_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: SkladHelperApp()));
}

class SkladHelperApp extends ConsumerWidget {
  const SkladHelperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // запускает регистрацию токена после логина (через repo)
    ref.watch(pushBootstrapProvider);

    // запуск навигации по push (см. следующий блок)
    ref.watch(pushNavigationBootstrapProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
