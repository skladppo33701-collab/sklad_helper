// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SkladHelper';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get waitingActivationTitle => 'Waiting for activation';

  @override
  String get waitingActivationBody =>
      'Your account was created. Admin must activate access.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get logout => 'Log out';

  @override
  String get assignments => 'Assignments';

  @override
  String get tasks => 'Tasks';

  @override
  String get profile => 'Profile';
}
