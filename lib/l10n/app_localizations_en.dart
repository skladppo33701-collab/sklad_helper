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

  @override
  String barcodeAlreadyBound(String article) {
    return 'Barcode already bound to: $article';
  }

  @override
  String productNotFound(String article) {
    return 'Product not found: $article';
  }

  @override
  String get labelArticle => 'Article';

  @override
  String get labelCategory => 'Category';

  @override
  String get labelBarcode => 'Barcode';

  @override
  String get statusBinding => 'Binding...';

  @override
  String get actionBindBarcode => 'Bind barcode';

  @override
  String get errorNotAllowed => 'Not allowed.';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get successBound => 'Barcode bound successfully';

  @override
  String get errorNotSignedIn => 'Not signed in';

  @override
  String get scanCancelled => 'Scan cancelled';

  @override
  String get barcodeUnknown => 'Unknown barcode';

  @override
  String get checkingNotAllowed => 'Checking not allowed';

  @override
  String get checkingNotFullyPicked => 'Items not fully picked yet';

  @override
  String checkingWrongItem(String expected, String actual) {
    return 'Wrong item. Expected: $expected, Actual: $actual';
  }

  @override
  String get checkingNotAllChecked => 'Not all items are checked';

  @override
  String get scanTitle => 'Scan';

  @override
  String get catalogTitle => 'Catalog';

  @override
  String get searchByArticle => 'Search by article (exact)';

  @override
  String get clearSearch => 'Clear';

  @override
  String get loadMore => 'Load more';

  @override
  String get listEnd => 'End';

  @override
  String get noBarcode => 'NO BARCODE';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get productsTitle => 'Products';

  @override
  String get productsPlaceholder => 'Products list (MVP placeholder)';

  @override
  String get errorLineNotFound => 'Line not found';

  @override
  String get errorLockedByOther => 'Locked by other';

  @override
  String get errorAlreadyHoldingLock => 'Already holding another lock';

  @override
  String get errorLockExpired => 'Lock expired';

  @override
  String get errorNotLockOwner => 'Not lock owner';

  @override
  String get errorOverPick => 'Over-pick prevented';

  @override
  String get errorOverCheck => 'Over-check prevented';

  @override
  String get valEmpty => 'Barcode is empty';

  @override
  String get valNumericOnly => 'Digits only (EAN-8 / EAN-13)';

  @override
  String get valChecksum => 'Invalid EAN-13 checksum';

  @override
  String get valLength => 'Only EAN-8 (8 digits) or EAN-13 (13 digits)';

  @override
  String get statusNew => 'New';

  @override
  String get statusPicking => 'In progress';

  @override
  String get statusPicked => 'Picked';

  @override
  String get statusChecking => 'Checking';

  @override
  String get statusDone => 'Done';

  @override
  String get btnStartChecking => 'Start checking';

  @override
  String get btnFinish => 'Finish';

  @override
  String get btnPrepare => 'Prepare';

  @override
  String get btnScan => 'Scan';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnCheck => 'Check';

  @override
  String get btnCancelCheck => 'Cancel check';

  @override
  String get msgCheckingStarted => 'Checking started';

  @override
  String get msgFinishBlocked => 'Finish blocked: not all checked';

  @override
  String get msgFinished => 'Finished';

  @override
  String get msgPrepared => 'Prepared';

  @override
  String get msgCancelled => 'Cancelled';

  @override
  String get msgOk => 'OK';

  @override
  String get msgChecked => 'Checked +1';

  @override
  String get msgCheckCancelled => 'Check cancelled';

  @override
  String subPicked(String picked, String planned) {
    return 'Picked $picked/$planned';
  }

  @override
  String subChecked(String checked, String planned) {
    return 'Checked $checked/$planned';
  }

  @override
  String get subLockedPick => 'Locked (pick)';

  @override
  String get subLockedCheck => 'Locked (check)';

  @override
  String get labelNoLines => 'No lines';

  @override
  String get labelDoneBadge => 'DONE';

  @override
  String get transferDetails => 'Transfer Details';
}
