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

  @override
  String barcodeAlreadyBound(String article) {
    return 'Штрихкод уже привязан к: $article';
  }

  @override
  String productNotFound(String article) {
    return 'Товар не найден: $article';
  }

  @override
  String get labelArticle => 'Артикул';

  @override
  String get labelCategory => 'Категория';

  @override
  String get labelBrand => 'Бренд';

  @override
  String get labelBarcode => 'Штрихкод';

  @override
  String get labelName => 'Наименование';

  @override
  String get catalogTitle => 'Каталог';

  @override
  String get searchByArticle => 'Поиск по названию/артикулу';

  @override
  String get loadMore => 'Загрузить еще';

  @override
  String get listEnd => 'Конец списка';

  @override
  String get statusBinding => 'Привязка...';

  @override
  String get actionBindBarcode => 'Привязать штрихкод';

  @override
  String get errorNotAllowed => 'Не разрешено.';

  @override
  String errorGeneric(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get successBound => 'Штрихкод успешно привязан';

  @override
  String get errorNotSignedIn => 'Вы не авторизованы';

  @override
  String get scanCancelled => 'Сканирование отменено';

  @override
  String get barcodeUnknown => 'Неизвестный штрихкод';

  @override
  String wrongItem(String expected) {
    return 'Не тот товар. Ожидался: $expected';
  }

  @override
  String get transferTitle => 'Перемещение';

  @override
  String get transferNotFound => 'Перемещение не найдено';

  @override
  String get listEmpty => 'Список пуст';

  @override
  String get status => 'Статус';

  @override
  String get items => 'Позиций';

  @override
  String get errorLockedByOther => 'Заблокировано другим пользователем';

  @override
  String get errorAlreadyHoldingLock => 'У вас уже есть активная задача';

  @override
  String get errorLockExpired => 'Время блокировки истекло';

  @override
  String get errorNotLockOwner => 'Вы не являетесь исполнителем этой задачи';

  @override
  String get errorOverPick => 'Нельзя собрать больше плана';

  @override
  String get errorOverCheck => 'Нельзя проверить больше плана';

  @override
  String get valEmpty => 'Пустой штрихкод';

  @override
  String get valNumericOnly => 'Разрешены только цифры (EAN-8 / EAN-13)';

  @override
  String get valChecksum => 'Неверная контрольная сумма EAN-13';

  @override
  String get valLength =>
      'Разрешены только EAN-8 (8 цифр) или EAN-13 (13 цифр)';

  @override
  String get statusNew => 'Новый';

  @override
  String get statusPicking => 'В работе';

  @override
  String get statusPicked => 'Собран';

  @override
  String get statusChecking => 'Проверка';

  @override
  String get statusDone => 'Готов';

  @override
  String get btnStartChecking => 'Начать проверку';

  @override
  String get btnFinish => 'Завершить';

  @override
  String get btnFinishPicking => 'Завершить сборку';

  @override
  String get btnPrepare => 'Подготовить';

  @override
  String get btnScan => 'Скан';

  @override
  String get btnCancel => 'Отмена';

  @override
  String get btnCheck => 'Проверить';

  @override
  String get btnCancelCheck => 'Отм. пров.';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get confirmDelete => 'Вы уверены, что хотите удалить?';

  @override
  String get msgCheckingStarted => 'Проверка начата';

  @override
  String get msgFinishBlocked => 'Нельзя завершить: не все проверено';

  @override
  String get msgFinished => 'Завершено';

  @override
  String get msgOk => 'OK';

  @override
  String get msgChecked => 'Проверено +1';

  @override
  String get msgCheckCancelled => 'Проверка отменена';

  @override
  String subPicked(String picked, String planned) {
    return 'Собрано $picked/$planned';
  }

  @override
  String subChecked(String checked, String planned) {
    return 'Проверено $checked/$planned';
  }

  @override
  String get subLockedPick => 'Заблокировано (сборка)';

  @override
  String get subLockedCheck => 'Заблокировано (проверка)';

  @override
  String get scanTitle => 'Сканировать штрихкод';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get noNotifications => 'Нет уведомлений';

  @override
  String get navHome => 'Главная';

  @override
  String get navTransfers => 'Перемещения';

  @override
  String get navCatalog => 'Каталог';

  @override
  String get account => 'Аккаунт';

  @override
  String get guest => 'Гость';

  @override
  String get active => 'Активен';

  @override
  String get inactive => 'Неактивен';

  @override
  String get language => 'Язык';

  @override
  String get adminUsers => 'Админ: Пользователи';

  @override
  String get adminProducts => 'Админ: База товаров';
}
