import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';
import 'app_exceptions.dart';

class ExceptionMapper {
  static String map(BuildContext context, Object error) {
    // В Flutter 3.10+ AppLocalizations.of(context) возвращает nullable,
    // но если мы уверены, что локализация загружена, можно использовать !
    // или fallback. Для безопасности используем ?.
    final l10n = AppLocalizations.of(context);

    // Fallback на английский или просто текст ошибки, если контекст потерян

    if (error is NotSignedInException) return l10n.errorNotSignedIn;
    if (error is ScanCancelledException) return l10n.scanCancelled;
    if (error is UnknownBarcodeException) return l10n.barcodeUnknown;

    if (error is WrongItemException) {
      // Метод generated l10n для placeholders
      return l10n.wrongItem(error.expectedArticle);
    }

    // --- Новые исключения ---
    if (error is LockTakenException) return l10n.errorLockedByOther;
    if (error is AlreadyHoldingLockException) {
      return l10n.errorAlreadyHoldingLock;
    }
    if (error is LockExpiredException) return l10n.errorLockExpired;
    if (error is NotLockOwnerException) return l10n.errorNotLockOwner;
    if (error is OverPickException) return l10n.errorOverPick;
    if (error is OverCheckException) return l10n.errorOverCheck;

    if (error is BarcodeConflictException) {
      return l10n.barcodeAlreadyBound(error.article);
    }
    if (error is ProductNotFoundException) {
      return l10n.productNotFound(error.article);
    }

    return l10n.errorGeneric(error.toString());
  }
}
