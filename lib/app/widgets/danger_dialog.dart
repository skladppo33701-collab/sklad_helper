import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DangerDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String confirmText,
  }) async {
    final passwordController = TextEditingController();
    final confirmTextController = TextEditingController();

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text('⚠️ $title', style: const TextStyle(color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Это необратимое действие! Для подтверждения введите ваш пароль и кодовую фразу.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Ваш пароль',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                const Text('Введите фразу ниже для подтверждения:'),
                const SizedBox(height: 8),
                // Исправлено: убран userSelect
                Text(
                  confirmText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmTextController,
                  decoration: InputDecoration(
                    hintText: confirmText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  // 1. Проверка фразы
                  if (confirmTextController.text != confirmText) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Кодовая фраза не совпадает'),
                      ),
                    );
                    return;
                  }

                  // 2. Проверка пароля (Re-Auth)
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && user.email != null) {
                      final cred = EmailAuthProvider.credential(
                        email: user.email!,
                        password: passwordController.text,
                      );

                      // Пытаемся повторно авторизоваться
                      await user.reauthenticateWithCredential(cred);

                      // Проверка mounted перед использованием контекста
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop(true); // Успех
                    }
                  } catch (e) {
                    // Проверка mounted перед использованием контекста
                    if (!dialogContext.mounted) return;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Неверный пароль')),
                    );
                  }
                },
                child: const Text('УДАЛИТЬ'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
