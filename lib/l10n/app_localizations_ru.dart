// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'SkladHelper';

  @override
  String get loginTitle => 'Вход';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get signIn => 'Войти';

  @override
  String get signUp => 'Создать аккаунт';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String get waitingActivationTitle => 'Ожидает активации';

  @override
  String get waitingActivationBody =>
      'Ваш аккаунт создан. Админ должен активировать доступ.';

  @override
  String get checkAgain => 'Проверить снова';

  @override
  String get logout => 'Выйти';

  @override
  String get assignments => 'Назначения';

  @override
  String get tasks => 'Задачи';

  @override
  String get profile => 'Профиль';
}
