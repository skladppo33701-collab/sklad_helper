import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';
import '../../utils/barcode_validator.dart';
import '../catalog/barcode_scanner_screen.dart';
import 'transfers_providers.dart';

class UnknownBarcodeException implements Exception {
  @override
  String toString() => 'Unknown barcode'; // TODO(l10n)
}

class WrongItemException implements Exception {
  WrongItemException({
    required this.expectedArticle,
    required this.actualArticle,
  });
  final String expectedArticle;
  final String actualArticle;

  @override
  String toString() => 'Wrong item'; // TODO(l10n)
}

class ScanCancelledException implements Exception {
  @override
  String toString() => 'Scan cancelled'; // TODO(l10n)
}

class TransferPickingController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // no-op
  }

  String? get _uid => ref.read(firebaseAuthProvider).currentUser?.uid;

  Future<void> prepareLine({
    required String transferId,
    required String lineId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in'); // TODO(l10n)

    state = const AsyncLoading();
    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .acquireLock(transferId: transferId, lineId: lineId, userId: uid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow; // ✅ CRITICAL: let UI try/catch handle it
    }
  }

  Future<void> cancelLine({
    required String transferId,
    required String lineId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in'); // TODO(l10n)

    state = const AsyncLoading();
    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .releaseLock(transferId: transferId, lineId: lineId, userId: uid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow; // ✅ propagate
    }
  }

  /// LOCKED BY ME -> scan -> validate format -> resolve barcode -> increment (+auto-release if complete)
  Future<void> scanAndPick(
    BuildContext context, {
    required String transferId,
    required String lineId,
    required String expectedArticle,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in'); // TODO(l10n)

    // 1) Scan
    final String? scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (scanned == null) {
      throw ScanCancelledException();
    }

    final barcode = scanned.trim();

    // 2) Local validation (EAN-8/EAN-13)
    final res = BarcodeValidator.validate(barcode);
    if (!res.ok) {
      throw FormatException(res.error ?? 'Invalid barcode'); // TODO(l10n)
    }

    // 3) Resolve barcode -> article (1 read)
    final resolvedArticle = await ref
        .read(barcodeRepositoryProvider)
        .resolveArticleByBarcode(barcode);

    if (resolvedArticle == null) {
      throw UnknownBarcodeException();
    }
    if (resolvedArticle != expectedArticle) {
      throw WrongItemException(
        expectedArticle: expectedArticle,
        actualArticle: resolvedArticle,
      );
    }

    // 4) Increment (1 transaction)
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
      rethrow; // ✅ propagate so UI doesn't show "OK" on failure
    }
  }
}
