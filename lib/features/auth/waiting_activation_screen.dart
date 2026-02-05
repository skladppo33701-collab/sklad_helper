import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';

class WaitingActivationScreen extends ConsumerWidget {
  const WaitingActivationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ожидает активации'),
        actions: [
          TextButton(
            onPressed: () => auth.signOut(),
            child: const Text('Выйти'),
          ),
        ],
      ),
      body: Center(
        child: profileAsync.when(
          data: (p) => Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    'Ваш аккаунт создан.\nАдмин должен активировать доступ.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (p != null)
                    Text('Роль: ${p.role.name}, Active: ${p.isActive}'),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => ref.invalidate(userProfileProvider),
                    child: const Text('Проверить снова'),
                  ),
                ],
              ),
            ),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Ошибка: $e'),
          ),
        ),
      ),
    );
  }
}
