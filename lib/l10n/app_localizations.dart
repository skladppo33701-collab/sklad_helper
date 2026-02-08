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

  /// Button text to log out
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// Title for the assignments section
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignments;

  /// Title for the tasks section
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// Title for the profile section
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Error message when a barcode is already assigned to another product
  ///
  /// In en, this message translates to:
  /// **'Barcode already bound to: {article}'**
  String barcodeAlreadyBound(String article);

  /// Error message when a product cannot be found by article
  ///
  /// In en, this message translates to:
  /// **'Product not found: {article}'**
  String productNotFound(String article);

  /// Label for the article field
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get labelArticle;

  /// Label for the category field
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get labelCategory;

  /// Label for the barcode field
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get labelBarcode;

  /// Button text indicating progress
  ///
  /// In en, this message translates to:
  /// **'Binding...'**
  String get statusBinding;

  /// Button label to start binding
  ///
  /// In en, this message translates to:
  /// **'Bind barcode'**
  String get actionBindBarcode;

  /// Error shown when user lacks permissions
  ///
  /// In en, this message translates to:
  /// **'Not allowed.'**
  String get errorNotAllowed;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// Success message after binding
  ///
  /// In en, this message translates to:
  /// **'Barcode bound successfully'**
  String get successBound;

  /// Error when user is not authenticated
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get errorNotSignedIn;

  /// Message when user cancels scanning
  ///
  /// In en, this message translates to:
  /// **'Scan cancelled'**
  String get scanCancelled;

  /// Error when barcode is not in database
  ///
  /// In en, this message translates to:
  /// **'Unknown barcode'**
  String get barcodeUnknown;

  /// Error when checking is forbidden
  ///
  /// In en, this message translates to:
  /// **'Checking not allowed'**
  String get checkingNotAllowed;

  /// Error trying to check before picking is done
  ///
  /// In en, this message translates to:
  /// **'Items not fully picked yet'**
  String get checkingNotFullyPicked;

  /// No description provided for @checkingWrongItem.
  ///
  /// In en, this message translates to:
  /// **'Wrong item. Expected: {expected}, Actual: {actual}'**
  String checkingWrongItem(String expected, String actual);

  /// Error trying to finish transfer before checking all items
  ///
  /// In en, this message translates to:
  /// **'Not all items are checked'**
  String get checkingNotAllChecked;

  /// Title for barcode scanner screen
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanTitle;

  /// Title for catalog screen
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalogTitle;

  /// Hint text for search field
  ///
  /// In en, this message translates to:
  /// **'Search by article (exact)'**
  String get searchByArticle;

  /// Tooltip for clear search button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSearch;

  /// Button to load more items
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// Text indicating end of list
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get listEnd;

  /// Badge text for missing barcode
  ///
  /// In en, this message translates to:
  /// **'NO BARCODE'**
  String get noBarcode;

  /// Title for notifications screen
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Text when notification list is empty
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// Title for products screen
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// Placeholder text for products screen
  ///
  /// In en, this message translates to:
  /// **'Products list (MVP placeholder)'**
  String get productsPlaceholder;

  /// Error when transfer line is missing
  ///
  /// In en, this message translates to:
  /// **'Line not found'**
  String get errorLineNotFound;

  /// Error when line is locked by another user
  ///
  /// In en, this message translates to:
  /// **'Locked by other'**
  String get errorLockedByOther;

  /// Error when user tries to lock multiple lines
  ///
  /// In en, this message translates to:
  /// **'Already holding another lock'**
  String get errorAlreadyHoldingLock;

  /// Error when lock time has passed
  ///
  /// In en, this message translates to:
  /// **'Lock expired'**
  String get errorLockExpired;

  /// Error when operation performed without lock ownership
  ///
  /// In en, this message translates to:
  /// **'Not lock owner'**
  String get errorNotLockOwner;

  /// Error when trying to pick more than planned
  ///
  /// In en, this message translates to:
  /// **'Over-pick prevented'**
  String get errorOverPick;

  /// Error when trying to check more than planned
  ///
  /// In en, this message translates to:
  /// **'Over-check prevented'**
  String get errorOverCheck;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Barcode is empty'**
  String get valEmpty;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Digits only (EAN-8 / EAN-13)'**
  String get valNumericOnly;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Invalid EAN-13 checksum'**
  String get valChecksum;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Only EAN-8 (8 digits) or EAN-13 (13 digits)'**
  String get valLength;

  /// Transfer status New
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// Transfer status Picking
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusPicking;

  /// Transfer status Picked
  ///
  /// In en, this message translates to:
  /// **'Picked'**
  String get statusPicked;

  /// Transfer status Checking
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get statusChecking;

  /// Transfer status Done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// Button to start checking process
  ///
  /// In en, this message translates to:
  /// **'Start checking'**
  String get btnStartChecking;

  /// Button to finish transfer
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get btnFinish;

  /// Button to acquire lock on line
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

  /// Button to perform check
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get btnCheck;

  /// Button to cancel check action
  ///
  /// In en, this message translates to:
  /// **'Cancel check'**
  String get btnCancelCheck;

  /// Toast message
  ///
  /// In en, this message translates to:
  /// **'Checking started'**
  String get msgCheckingStarted;

  /// Toast message
  ///
  /// In en, this message translates to:
  /// **'Finish blocked: not all checked'**
  String get msgFinishBlocked;

  /// Toast message
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get msgFinished;

  /// Toast message
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get msgPrepared;

  /// Toast message
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get msgCancelled;

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

  /// Label when list is empty
  ///
  /// In en, this message translates to:
  /// **'No lines'**
  String get labelNoLines;

  /// Badge text for completed items
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get labelDoneBadge;

  /// Title for transfer detail screen
  ///
  /// In en, this message translates to:
  /// **'Transfer Details'**
  String get transferDetails;
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
