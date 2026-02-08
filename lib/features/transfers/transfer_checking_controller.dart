import 'dart:collection';
import 'package:flutter/material.dart'; // Включает foundation
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';
import '../../data/models/transfer_line.dart';
import '../../utils/barcode_validator.dart';
import '../../utils/app_exceptions.dart';
import '../catalog/barcode_scanner_screen.dart';
import 'transfers_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../data/models/transfer.dart';
import '../../features/notifications/push_sender_service.dart';

// Объявляем провайдер
final transferCheckingControllerProvider =
    AutoDisposeAsyncNotifierProvider<TransferCheckingController, void>(() {
      return TransferCheckingController();
    });

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

    state = const AsyncLoading();
    try {
      await ref
          .read(transferRepositoryProvider)
          .updateStatus(transferId, TransferStatus.done);

      state = const AsyncData(null);

      try {
        await PushSenderService().sendNotification(
          topic: 'admin',
          title: '✅ Трансфер закрыт',
          body: 'Проверка завершена успешно.',
          data: {'transferId': transferId},
        );
      } catch (e) {
        debugPrint('Ошибка отправки пуша (Проверка): $e');
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> processScan({
    required BuildContext context,
    required String transferId,
    required TransferLine line,
  }) async {
    final uid = _uid;
    if (uid == null) throw NotSignedInException();

    final l10n = AppLocalizations.of(context);

    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (scanned == null) throw ScanCancelledException();
    final barcode = scanned.trim();

    final val = BarcodeValidator.validate(barcode, l10n);
    if (!val.ok) throw FormatException(val.error ?? 'Invalid');

    String? resolved;
    if (_barcodeToArticleCache.containsKey(barcode)) {
      resolved = _barcodeToArticleCache[barcode];
    } else {
      resolved = await ref
          .read(barcodeRepositoryProvider)
          .resolveArticleByBarcode(barcode);
      _barcodeToArticleCache[barcode] = resolved;
    }

    if (resolved == null) throw UnknownBarcodeException();

    if (resolved != line.article) {
      throw WrongItemException(
        expectedArticle: line.article,
        actualArticle: resolved,
      );
    }

    state = const AsyncLoading();
    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .acquireCheckLock(
            transferId: transferId,
            lineId: line.id,
            userId: uid,
          );

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
      try {
        await ref
            .read(transferLinesRepositoryProvider)
            .releaseCheckLock(
              transferId: transferId,
              lineId: line.id,
              userId: uid,
            );
      } catch (_) {}

      state = AsyncError(e, st);
      rethrow;
    }
  }
}
