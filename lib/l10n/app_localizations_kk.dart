// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appTitle => 'SkladHelper';

  @override
  String get loginTitle => 'Кіру';

  @override
  String get email => 'Email';

  @override
  String get password => 'Құпиясөз';

  @override
  String get signIn => 'Кіру';

  @override
  String get signUp => 'Тіркелу';

  @override
  String get forgotPassword => 'Құпиясөзді ұмыттыңыз ба?';

  @override
  String get signInWithGoogle => 'Google арқылы кіру';

  @override
  String get waitingActivationTitle => 'Белсендіру күтілуде';

  @override
  String get waitingActivationBody =>
      'Аккаунт құрылды. Әкімші қолжетімділікті белсендіруі керек.';

  @override
  String get checkAgain => 'Қайта тексеру';

  @override
  String get logout => 'Шығу';

  @override
  String get assignments => 'Тапсырмалар';

  @override
  String get tasks => 'Жоспар';

  @override
  String get profile => 'Профиль';

  @override
  String barcodeAlreadyBound(String article) {
    return 'Штрих-код мына тауарға тіркелген: $article';
  }

  @override
  String productNotFound(String article) {
    return 'Тауар табылмады: $article';
  }

  @override
  String get labelArticle => 'Артикул';

  @override
  String get labelCategory => 'Санат';

  @override
  String get labelBarcode => 'Штрих-код';

  @override
  String get statusBinding => 'Тіркеу...';

  @override
  String get actionBindBarcode => 'Штрих-кодты тіркеу';

  @override
  String get errorNotAllowed => 'Рұқсат етілмеген.';

  @override
  String errorGeneric(String error) {
    return 'Қате: $error';
  }

  @override
  String get successBound => 'Штрих-код сәтті тіркелді';

  @override
  String get errorNotSignedIn => 'Сіз жүйеге кірмедіңіз';

  @override
  String get scanCancelled => 'Сканерлеу тоқтатылды';

  @override
  String get barcodeUnknown => 'Белгісіз штрих-код';

  @override
  String get checkingNotAllowed => 'Тексеруге тыйым салынған';

  @override
  String get checkingNotFullyPicked => 'Тауарлар толық жиналмаған';

  @override
  String checkingWrongItem(String expected, String actual) {
    return 'Бұл тауар емес. Күтілген: $expected, Факті: $actual';
  }

  @override
  String get checkingNotAllChecked => 'Барлық тауарлар тексерілмеген';

  @override
  String get scanTitle => 'Сканерлеу';

  @override
  String get catalogTitle => 'Каталог';

  @override
  String get searchByArticle => 'Артикул бойынша іздеу';

  @override
  String get clearSearch => 'Тазалау';

  @override
  String get loadMore => 'Көбірек жүктеу';

  @override
  String get listEnd => 'Тізім соңы';

  @override
  String get noBarcode => 'ШТРИХ-КОДСЫЗ';

  @override
  String get notificationsTitle => 'Хабарламалар';

  @override
  String get noNotifications => 'Хабарламалар жоқ';

  @override
  String get productsTitle => 'Тауарлар';

  @override
  String get productsPlaceholder => 'Тауарлар тізімі (әзірленуде)';

  @override
  String get errorLineNotFound => 'Жол табылмады';

  @override
  String get errorLockedByOther => 'Басқа пайдаланушы құлыптаған';

  @override
  String get errorAlreadyHoldingLock => 'Сізде белсенді тапсырма бар';

  @override
  String get errorLockExpired => 'Құлыптау уақыты аяқталды';

  @override
  String get errorNotLockOwner => 'Сіз бұл тапсырманың орындаушысы емессіз';

  @override
  String get errorOverPick => 'Жоспардан артық жинауға болмайды';

  @override
  String get errorOverCheck => 'Жоспардан артық тексеруге болмайды';

  @override
  String get valEmpty => 'Бос штрих-код';

  @override
  String get valNumericOnly => 'Тек сандар (EAN-8 / EAN-13)';

  @override
  String get valChecksum => 'EAN-13 бақылау сомасы қате';

  @override
  String get valLength => 'Тек EAN-8 (8 сан) немесе EAN-13 (13 сан)';

  @override
  String get statusNew => 'Жаңа';

  @override
  String get statusPicking => 'Орындалуда';

  @override
  String get statusPicked => 'Жиналды';

  @override
  String get statusChecking => 'Тексеру';

  @override
  String get statusDone => 'Дайын';

  @override
  String get btnStartChecking => 'Тексеруді бастау';

  @override
  String get btnFinish => 'Аяқтау';

  @override
  String get btnPrepare => 'Дайындау';

  @override
  String get btnScan => 'Скан';

  @override
  String get btnCancel => 'Болдырмау';

  @override
  String get btnCheck => 'Тексеру';

  @override
  String get btnCancelCheck => 'Текс. болдырмау';

  @override
  String get msgCheckingStarted => 'Тексеру басталды';

  @override
  String get msgFinishBlocked => 'Аяқтау мүмкін емес: бәрі тексерілмеген';

  @override
  String get msgFinished => 'Аяқталды';

  @override
  String get msgPrepared => 'Дайындалды';

  @override
  String get msgCancelled => 'Болдырылмады';

  @override
  String get msgOk => 'ОК';

  @override
  String get msgChecked => 'Тексерілді +1';

  @override
  String get msgCheckCancelled => 'Тексеру тоқтатылды';

  @override
  String subPicked(String picked, String planned) {
    return 'Жиналды $picked/$planned';
  }

  @override
  String subChecked(String checked, String planned) {
    return 'Тексерілді $checked/$planned';
  }

  @override
  String get subLockedPick => 'Блок (жинау)';

  @override
  String get subLockedCheck => 'Блок (тексеру)';

  @override
  String get labelNoLines => 'Жолдар жоқ';

  @override
  String get labelDoneBadge => 'ДАЙЫН';

  @override
  String get transferDetails => 'Ауыстыру мәліметтері';
}
