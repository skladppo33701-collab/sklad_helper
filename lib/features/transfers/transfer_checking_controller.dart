import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';
import '../../data/models/transfer_line.dart';
import '../../utils/barcode_validator.dart';
import '../../utils/app_exceptions.dart';
import '../catalog/barcode_scanner_screen.dart';
import 'transfers_providers.dart';
import '../../l10n/app_localizations.dart';

class TransferCheckingController extends AutoDisposeAsyncNotifier<void> {
  final Map<String, String?> _barcodeToArticleCache = HashMap();

  @override
  Future<void> build() async {}

  String? get _uid => ref.read(firebaseAuthProvider).currentUser?.uid;

  Future<void> startChecking({required String transferId}) async {
    final uid = _uid;
    if (uid == null) throw NotSignedInException();

    state = const AsyncLoading();
    try {
      await ref.read(transferRepositoryProvider).startChecking(transferId, uid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> finish({
    required String transferId,
    required List<TransferLine> currentLines,
  }) async {
    final uid = _uid;
    if (uid == null) throw NotSignedInException();

    final allChecked = currentLines.every((l) => l.qtyChecked >= l.qtyPlanned);
    if (!allChecked) throw Exception('Not all checked');

    state = const AsyncLoading();
    try {
      await ref
          .read(transferRepositoryProvider)
          .finishTransfer(transferId, uid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> cancelCheckLine({
    required String transferId,
    required String lineId,
  }) async {
    final uid = _uid;
    if (uid == null) throw NotSignedInException();

    state = const AsyncLoading();
    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .releaseCheckLock(
            transferId: transferId,
            lineId: lineId,
            userId: uid,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> checkLine(
    BuildContext context, {
    required String transferId,
    required TransferLine line,
  }) async {
    final uid = _uid;
    if (uid == null) throw NotSignedInException();

    if (line.qtyPicked < line.qtyPlanned) throw NotFullyPickedException();

    state = const AsyncLoading();
    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .acquireCheckLock(
            transferId: transferId,
            lineId: line.id,
            userId: uid,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }

    if (!context.mounted) return;

    // 1) Scan
    final String? scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (scanned == null) {
      // Если отменили скан — отпускаем блокировку
      try {
        await ref
            .read(transferLinesRepositoryProvider)
            .releaseCheckLock(
              transferId: transferId,
              lineId: line.id,
              userId: uid,
            );
      } catch (_) {}
      throw ScanCancelledException();
    }

    // --- ИСПРАВЛЕНИЕ: Проверяем mounted перед использованием context ---
    if (!context.mounted) {
      // Если экран закрылся во время скана — тоже отпускаем блокировку
      try {
        await ref
            .read(transferLinesRepositoryProvider)
            .releaseCheckLock(
              transferId: transferId,
              lineId: line.id,
              userId: uid,
            );
      } catch (_) {}
      return;
    }
    // ------------------------------------------------------------------

    final l10n = AppLocalizations.of(context);
    final barcode = scanned.trim();

    // 2) Validate
    final v = BarcodeValidator.validate(barcode, l10n);
    if (!v.ok) {
      try {
        await ref
            .read(transferLinesRepositoryProvider)
            .releaseCheckLock(
              transferId: transferId,
              lineId: line.id,
              userId: uid,
            );
      } catch (_) {}
      throw FormatException(v.error ?? 'Invalid barcode');
    }

    // 3) Resolve
    String? resolved = _barcodeToArticleCache[barcode];
    if (!_barcodeToArticleCache.containsKey(barcode)) {
      resolved = await ref
          .read(barcodeRepositoryProvider)
          .resolveArticleByBarcode(barcode);
      _barcodeToArticleCache[barcode] = resolved;
    }

    if (resolved == null) {
      try {
        await ref
            .read(transferLinesRepositoryProvider)
            .releaseCheckLock(
              transferId: transferId,
              lineId: line.id,
              userId: uid,
            );
      } catch (_) {}
      throw UnknownBarcodeException();
    }

    if (resolved != line.article) {
      try {
        await ref
            .read(transferLinesRepositoryProvider)
            .releaseCheckLock(
              transferId: transferId,
              lineId: line.id,
              userId: uid,
            );
      } catch (_) {}
      throw WrongItemException(
        expectedArticle: line.article,
        actualArticle: resolved,
      );
    }

    // 4) Increment
    state = const AsyncLoading();
    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .incrementChecked(
            transferId: transferId,
            lineId: line.id,
            userId: uid,
            autoReleaseOnComplete: true,
          );
      HapticFeedback.lightImpact();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      try {
        await ref
            .read(transferLinesRepositoryProvider)
            .releaseCheckLock(
              transferId: transferId,
              lineId: line.id,
              userId: uid,
            );
      } catch (_) {}
      rethrow;
    }
  }
}
