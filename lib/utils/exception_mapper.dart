import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';
import '../data/repos/barcode_repository.dart';
import '../data/repos/transfer_lines_repository.dart';
import 'app_exceptions.dart';

class ExceptionMapper {
  static String map(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);

    if (error is BarcodeConflictException) {
      return l10n.barcodeAlreadyBound(error.article);
    }
    if (error is ProductAlreadyBoundException) {
      return l10n.barcodeAlreadyBound(error.barcode);
    }
    if (error is ProductNotFoundException) {
      return l10n.productNotFound(error.article);
    }

    // Репозиторий линий
    if (error is LineNotFoundException) return l10n.errorLineNotFound;
    if (error is LockTakenException) return l10n.errorLockedByOther;
    if (error is AlreadyHoldingLockException) {
      return l10n.errorAlreadyHoldingLock;
    }
    if (error is LockExpiredException) return l10n.errorLockExpired;
    if (error is NotLockOwnerException) return l10n.errorNotLockOwner;
    if (error is OverPickException) return l10n.errorOverPick;
    if (error is OverCheckException) return l10n.errorOverCheck;

    // Общие
    if (error is NotSignedInException) return l10n.errorNotSignedIn;
    if (error is CheckingNotAllowedException) return l10n.checkingNotAllowed;
    if (error is NotFullyPickedException) return l10n.checkingNotFullyPicked;
    if (error is UnknownBarcodeException) return l10n.barcodeUnknown;
    if (error is ScanCancelledException) return l10n.scanCancelled;

    if (error is WrongItemException) {
      return l10n.checkingWrongItem(error.expectedArticle, error.actualArticle);
    }

    final s = error.toString();
    if (s.contains('Not signed in')) return l10n.errorNotSignedIn;

    return s.replaceAll('Exception:', '').trim();
  }
}
