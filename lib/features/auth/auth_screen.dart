import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/router/providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _isLogin = true;
  bool _busy = false;

  Future<void> _withBusy(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? e.code);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _emailAuth() async {
    final auth = ref.read(firebaseAuthProvider);
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || pass.isEmpty) {
      _snack('Введите email и пароль');
      return;
    }

    await _withBusy(() async {
      if (_isLogin) {
        await auth.signInWithEmailAndPassword(email: email, password: pass);
      } else {
        await auth.createUserWithEmailAndPassword(email: email, password: pass);
      }
    });
  }

  Future<void> _resetPassword() async {
    final auth = ref.read(firebaseAuthProvider);
    final email = _email.text.trim();
    if (email.isEmpty) {
      _snack('Введите email для сброса пароля');
      return;
    }
    await _withBusy(() async {
      await auth.sendPasswordResetEmail(email: email);
      _snack('Письмо для сброса пароля отправлено');
    });
  }

  Future<void> _googleSignIn() async {
    final auth = ref.read(firebaseAuthProvider);

    await _withBusy(() async {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // cancelled
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.signInWithCredential(credential);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SkladHelper')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Пароль'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _emailAuth,
                  child: Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin ? 'Создать аккаунт' : 'У меня уже есть аккаунт',
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _resetPassword,
                  child: const Text('Забыли пароль?'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _googleSignIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Войти через Google'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'После регистрации ваш аккаунт будет в статусе гостя, пока админ не активирует доступ.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
