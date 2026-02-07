import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';
import '../../data/models/transfer_line.dart';
import '../../utils/barcode_validator.dart';
import '../catalog/barcode_scanner_screen.dart';
import 'transfers_providers.dart';

class CheckingNotAllowedException implements Exception {
  @override
  String toString() => 'Not allowed'; // TODO(l10n)
}

class NotFullyPickedException implements Exception {
  @override
  String toString() => 'Not fully picked'; // TODO(l10n)
}

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

class TransferCheckingController extends AutoDisposeAsyncNotifier<void> {
  final Map<String, String?> _barcodeToArticleCache = HashMap();

  @override
  Future<void> build() async {
    // no-op
  }

  String? get _uid => ref.read(firebaseAuthProvider).currentUser?.uid;

  Future<void> startChecking({required String transferId}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in'); // TODO(l10n)

    state = const AsyncLoading();
    try {
      await ref
          .read(transferRepositoryProvider)
          .startChecking(transferId: transferId, userId: uid);
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
    if (uid == null) throw Exception('Not signed in'); // TODO(l10n)

    final allChecked = currentLines.every((l) => l.qtyChecked >= l.qtyPlanned);
    if (!allChecked) {
      throw Exception('Not all checked'); // TODO(l10n)
    }

    state = const AsyncLoading();
    try {
      await ref
          .read(transferRepositoryProvider)
          .finishTransfer(transferId: transferId, userId: uid);
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
    if (uid == null) throw Exception('Not signed in'); // TODO(l10n)

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
    if (uid == null) throw Exception('Not signed in'); // TODO(l10n)

    // MVP: block checking if not fully picked
    if (line.qtyPicked < line.qtyPlanned) {
      throw NotFullyPickedException();
    }

    // Acquire check lock first (so another checker doesn’t scan in parallel)
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

    // Scan (UI flow)
    if (!context.mounted) return;
    final String? scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (scanned == null) {
      // Cancel scan => release check lock
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

    final barcode = scanned.trim();

    final v = BarcodeValidator.validate(barcode);
    if (!v.ok) {
      // Invalid format => release lock
      try {
        await ref
            .read(transferLinesRepositoryProvider)
            .releaseCheckLock(
              transferId: transferId,
              lineId: line.id,
              userId: uid,
            );
      } catch (_) {}
      throw FormatException(v.error ?? 'Invalid barcode'); // TODO(l10n)
    }

    // Resolve barcode -> article (1 read, cached per controller lifecycle)
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

    // Increment checked (+ auto release on complete)
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
      // On any failure, attempt to release check lock (best-effort)
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
