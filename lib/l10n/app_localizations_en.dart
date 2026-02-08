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
  String get tasks => 'Plan';

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
  String get labelBrand => 'Brand';

  @override
  String get labelBarcode => 'Barcode';

  @override
  String get labelName => 'Name';

  @override
  String get catalogTitle => 'Catalog';

  @override
  String get searchByArticle => 'Search by Name/Article';

  @override
  String get loadMore => 'Load More';

  @override
  String get listEnd => 'End of list';

  @override
  String get statusBinding => 'Binding...';

  @override
  String get actionBindBarcode => 'Bind Barcode';

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
  String wrongItem(String expected) {
    return 'Wrong item scanned. Expected: $expected';
  }

  @override
  String get transferTitle => 'Transfer';

  @override
  String get transferNotFound => 'Transfer not found';

  @override
  String get listEmpty => 'List is empty';

  @override
  String get status => 'Status';

  @override
  String get items => 'Items';

  @override
  String get errorLockedByOther => 'Locked by another user';

  @override
  String get errorAlreadyHoldingLock => 'You already have an active task';

  @override
  String get errorLockExpired => 'Lock expired';

  @override
  String get errorNotLockOwner => 'You are not the owner of this lock';

  @override
  String get errorOverPick => 'Cannot pick more than planned';

  @override
  String get errorOverCheck => 'Cannot check more than planned';

  @override
  String get valEmpty => 'Empty barcode';

  @override
  String get valNumericOnly => 'Digits only (EAN-8 / EAN-13)';

  @override
  String get valChecksum => 'Invalid EAN-13 checksum';

  @override
  String get valLength => 'Only EAN-8 (8 digits) or EAN-13 (13 digits)';

  @override
  String get statusNew => 'New';

  @override
  String get statusPicking => 'Picking';

  @override
  String get statusPicked => 'Picked';

  @override
  String get statusChecking => 'Checking';

  @override
  String get statusDone => 'Done';

  @override
  String get btnStartChecking => 'Start Checking';

  @override
  String get btnFinish => 'Finish';

  @override
  String get btnFinishPicking => 'Finish Picking';

  @override
  String get btnPrepare => 'Prepare';

  @override
  String get btnScan => 'Scan';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnCheck => 'Check';

  @override
  String get btnCancelCheck => 'Cancel Check';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDelete => 'Are you sure you want to delete this?';

  @override
  String get msgCheckingStarted => 'Checking started';

  @override
  String get msgFinishBlocked => 'Cannot finish: not all items checked';

  @override
  String get msgFinished => 'Finished';

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
  String get scanTitle => 'Scan Barcode';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get navHome => 'Home';

  @override
  String get navTransfers => 'Transfers';

  @override
  String get navCatalog => 'Catalog';

  @override
  String get account => 'Account';

  @override
  String get guest => 'Guest';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get language => 'Language';

  @override
  String get adminUsers => 'Admin: Users';

  @override
  String get adminProducts => 'Admin: Products DB';
}
