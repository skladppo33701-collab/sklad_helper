import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/router/providers.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/widgets/keyboard_dismiss.dart';

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

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
      if (kIsWeb) {
        try {
          await auth.signInWithPopup(GoogleAuthProvider());
          _snack('Успешный вход через Google (Web)');
        } catch (e) {
          _snack('Ошибка входа Web: $e');
        }
      } else {
        final googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);
        await googleSignIn.signOut();

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return;

        final googleAuth = await googleUser.authentication;
        if (googleAuth.idToken == null) {
          _snack('Ошибка: Google не вернул idToken (Mobile).');
          return;
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await auth.signInWithCredential(credential);
        _snack('Успешный вход через Google (Mobile)');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismiss(child: Scaffold(body: _buildBody(context)));
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppDimens.x24,
            AppDimens.x24,
            AppDimens.x24,
            AppDimens.x24 + bottomInset,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Logo / Branding Area
                Icon(
                  Icons.inventory_2_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppDimens.x16),
                Text(
                  'SkladHelper',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppDimens.x8),
                Text(
                  _isLogin ? 'Welcome back' : 'Create your workspace',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppDimens.x32),

                // 2. Form Fields
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppDimens.x16),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _busy ? null : _emailAuth(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: AppDimens.x8),

                // 3. Password Reset
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _resetPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.x8,
                      ),
                    ),
                    child: const Text('Forgot password?'),
                  ),
                ),

                const SizedBox(height: AppDimens.x16),

                // 4. Main Action
                FilledButton(
                  onPressed: _busy ? null : _emailAuth,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isLogin ? 'Sign In' : 'Create Account'),
                ),

                const SizedBox(height: AppDimens.x16),

                // 5. Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: theme.colorScheme.outlineVariant),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.x16,
                      ),
                      child: Text('OR', style: theme.textTheme.labelMedium),
                    ),
                    Expanded(
                      child: Divider(color: theme.colorScheme.outlineVariant),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.x16),

                // 6. Secondary Actions
                OutlinedButton.icon(
                  onPressed: _busy ? null : _googleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Continue with Google'),
                ),

                const SizedBox(height: AppDimens.x24),

                // 7. Toggle Mode
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account?"
                          : "Already have an account?",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin ? 'Sign Up' : 'Sign In',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
