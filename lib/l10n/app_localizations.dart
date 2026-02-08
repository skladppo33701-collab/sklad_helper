import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// The main application title
  ///
  /// In en, this message translates to:
  /// **'SkladHelper'**
  String get appTitle;

  /// Title shown on the login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// Label for the email input field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for the password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Button text to sign in
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Button text to create a new account
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// Link text for password recovery
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Button text for Google Sign-In
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// Title on the screen when waiting for admin approval
  ///
  /// In en, this message translates to:
  /// **'Waiting for activation'**
  String get waitingActivationTitle;

  /// Message explaining the waiting status
  ///
  /// In en, this message translates to:
  /// **'Your account was created. Admin must activate access.'**
  String get waitingActivationBody;

  /// Button to refresh activation status
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// Button text to sign out
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// Tab title for assigned tasks
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignments;

  /// Tab title for planning
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get tasks;

  /// Tab title for user profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Error message when barcode is duplicate
  ///
  /// In en, this message translates to:
  /// **'Barcode already bound to: {article}'**
  String barcodeAlreadyBound(String article);

  /// Error message when product is missing
  ///
  /// In en, this message translates to:
  /// **'Product not found: {article}'**
  String productNotFound(String article);

  /// Label for product article
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get labelArticle;

  /// Label for product category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get labelCategory;

  /// Label for product brand
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get labelBrand;

  /// Label for barcode field
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get labelBarcode;

  /// Label for product name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get labelName;

  /// Screen title for catalog
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalogTitle;

  /// Hint text for search field
  ///
  /// In en, this message translates to:
  /// **'Search by Name/Article'**
  String get searchByArticle;

  /// Button to load next page
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// Message shown at the end of pagination
  ///
  /// In en, this message translates to:
  /// **'End of list'**
  String get listEnd;

  /// Status text during binding process
  ///
  /// In en, this message translates to:
  /// **'Binding...'**
  String get statusBinding;

  /// Button text to bind barcode
  ///
  /// In en, this message translates to:
  /// **'Bind Barcode'**
  String get actionBindBarcode;

  /// Permission error message
  ///
  /// In en, this message translates to:
  /// **'Not allowed.'**
  String get errorNotAllowed;

  /// Generic error message template
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// Success message after binding
  ///
  /// In en, this message translates to:
  /// **'Barcode bound successfully'**
  String get successBound;

  /// Error message when user is not authenticated
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get errorNotSignedIn;

  /// Message when user cancels scanning
  ///
  /// In en, this message translates to:
  /// **'Scan cancelled'**
  String get scanCancelled;

  /// Error when barcode is not found in db
  ///
  /// In en, this message translates to:
  /// **'Unknown barcode'**
  String get barcodeUnknown;

  /// Error when scanned item does not match expected
  ///
  /// In en, this message translates to:
  /// **'Wrong item scanned. Expected: {expected}'**
  String wrongItem(String expected);

  /// Screen title for transfer details
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferTitle;

  /// Error message when transfer document is missing
  ///
  /// In en, this message translates to:
  /// **'Transfer not found'**
  String get transferNotFound;

  /// Message shown when list has no items
  ///
  /// In en, this message translates to:
  /// **'List is empty'**
  String get listEmpty;

  /// Label for status field
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Label for items count
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// Error when item is locked by someone else
  ///
  /// In en, this message translates to:
  /// **'Locked by another user'**
  String get errorLockedByOther;

  /// Error when user tries to take another task
  ///
  /// In en, this message translates to:
  /// **'You already have an active task'**
  String get errorAlreadyHoldingLock;

  /// Error when lock time ran out
  ///
  /// In en, this message translates to:
  /// **'Lock expired'**
  String get errorLockExpired;

  /// Error when trying to modify lock owned by others
  ///
  /// In en, this message translates to:
  /// **'You are not the owner of this lock'**
  String get errorNotLockOwner;

  /// Error when picking exceeds quantity
  ///
  /// In en, this message translates to:
  /// **'Cannot pick more than planned'**
  String get errorOverPick;

  /// Error when checking exceeds quantity
  ///
  /// In en, this message translates to:
  /// **'Cannot check more than planned'**
  String get errorOverCheck;

  /// Validation error for empty input
  ///
  /// In en, this message translates to:
  /// **'Empty barcode'**
  String get valEmpty;

  /// Validation error for non-numeric input
  ///
  /// In en, this message translates to:
  /// **'Digits only (EAN-8 / EAN-13)'**
  String get valNumericOnly;

  /// Validation error for invalid checksum
  ///
  /// In en, this message translates to:
  /// **'Invalid EAN-13 checksum'**
  String get valChecksum;

  /// Validation error for invalid length
  ///
  /// In en, this message translates to:
  /// **'Only EAN-8 (8 digits) or EAN-13 (13 digits)'**
  String get valLength;

  /// Status label: New
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// Status label: Picking
  ///
  /// In en, this message translates to:
  /// **'Picking'**
  String get statusPicking;

  /// Status label: Picked
  ///
  /// In en, this message translates to:
  /// **'Picked'**
  String get statusPicked;

  /// Status label: Checking
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get statusChecking;

  /// Status label: Done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// Button to start checking process
  ///
  /// In en, this message translates to:
  /// **'Start Checking'**
  String get btnStartChecking;

  /// Button to finish process
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get btnFinish;

  /// Button to finish picking phase
  ///
  /// In en, this message translates to:
  /// **'Finish Picking'**
  String get btnFinishPicking;

  /// Button to prepare item (lock)
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get btnPrepare;

  /// Button to open scanner
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get btnScan;

  /// Button to cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// Button to verify item
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get btnCheck;

  /// Button to cancel check
  ///
  /// In en, this message translates to:
  /// **'Cancel Check'**
  String get btnCancelCheck;

  /// Button label Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button label Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get confirmDelete;

  /// Toast message
  ///
  /// In en, this message translates to:
  /// **'Checking started'**
  String get msgCheckingStarted;

  /// Error message when trying to finish incomplete check
  ///
  /// In en, this message translates to:
  /// **'Cannot finish: not all items checked'**
  String get msgFinishBlocked;

  /// Toast message
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get msgFinished;

  /// Toast message
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get msgOk;

  /// Toast message
  ///
  /// In en, this message translates to:
  /// **'Checked +1'**
  String get msgChecked;

  /// Toast message
  ///
  /// In en, this message translates to:
  /// **'Check cancelled'**
  String get msgCheckCancelled;

  /// Subtitle showing pick progress
  ///
  /// In en, this message translates to:
  /// **'Picked {picked}/{planned}'**
  String subPicked(String picked, String planned);

  /// Subtitle showing check progress
  ///
  /// In en, this message translates to:
  /// **'Checked {checked}/{planned}'**
  String subChecked(String checked, String planned);

  /// Subtitle indicating pick lock
  ///
  /// In en, this message translates to:
  /// **'Locked (pick)'**
  String get subLockedPick;

  /// Subtitle indicating check lock
  ///
  /// In en, this message translates to:
  /// **'Locked (check)'**
  String get subLockedCheck;

  /// Title for scanner screen
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanTitle;

  /// Title for notifications screen
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Message when notification list is empty
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// Bottom navigation label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get navTransfers;

  /// Bottom navigation label
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get navCatalog;

  /// Drawer header title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Fallback username
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// User status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// User status
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Language settings tile
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Admin menu item
  ///
  /// In en, this message translates to:
  /// **'Admin: Users'**
  String get adminUsers;

  /// Admin menu item
  ///
  /// In en, this message translates to:
  /// **'Admin: Products DB'**
  String get adminProducts;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
