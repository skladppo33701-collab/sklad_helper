import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_exceptions.dart';
import '../../app/router/providers.dart';
import '../../utils/barcode_validator.dart';
import '../catalog/barcode_scanner_screen.dart';
import 'transfers_providers.dart';
import '../../l10n/app_localizations.dart';

class TransferPickingController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  String? get _uid => ref.read(firebaseAuthProvider).currentUser?.uid;

  Future<void> prepareLine({
    required String transferId,
    required String lineId,
  }) async {
    final uid = _uid;
    if (uid == null) throw NotSignedInException();

    state = const AsyncLoading();
    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .acquireLock(transferId: transferId, lineId: lineId, userId: uid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> cancelLine({
    required String transferId,
    required String lineId,
  }) async {
    final uid = _uid;
    if (uid == null) throw NotSignedInException();

    state = const AsyncLoading();
    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .releaseLock(transferId: transferId, lineId: lineId, userId: uid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> scanAndPick(
    BuildContext context, {
    required String transferId,
    required String lineId,
    required String expectedArticle,
  }) async {
    final uid = _uid;
    if (uid == null) throw NotSignedInException();

    final l10n = AppLocalizations.of(context);

    // 1) Scan
    final String? scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (scanned == null) throw ScanCancelledException();
    final barcode = scanned.trim();

    // 2) Validate
    final res = BarcodeValidator.validate(barcode, l10n);
    if (!res.ok) {
      throw FormatException(res.error ?? 'Invalid barcode');
    }

    // 3) Resolve
    final resolvedArticle = await ref
        .read(barcodeRepositoryProvider)
        .resolveArticleByBarcode(barcode);

    if (resolvedArticle == null) throw UnknownBarcodeException();

    if (resolvedArticle != expectedArticle) {
      throw WrongItemException(
        expectedArticle: expectedArticle,
        actualArticle: resolvedArticle,
      );
    }

    // 4) Increment
    state = const AsyncLoading();
    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .incrementPicked(
            transferId: transferId,
            lineId: lineId,
            userId: uid,
            autoReleaseOnComplete: true,
          );
      HapticFeedback.lightImpact();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
