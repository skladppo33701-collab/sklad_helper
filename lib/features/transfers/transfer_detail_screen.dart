import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router/providers.dart';
import '../../data/models/transfer_line.dart';
import '../../data/repos/transfer_lines_repository.dart';
import '../../utils/barcode_validator.dart';
import '../catalog/barcode_scanner_screen.dart';
import 'transfers_providers.dart';

class TransferDetailScreen extends ConsumerStatefulWidget {
  const TransferDetailScreen({super.key, required this.transferId});
  final String transferId;

  @override
  ConsumerState<TransferDetailScreen> createState() =>
      _TransferDetailScreenState();
}

class _TransferDetailScreenState extends ConsumerState<TransferDetailScreen> {
  String? _busyLineId;

  bool _isCompleted(TransferLine l) => l.qtyPicked >= l.qtyPlanned;

  bool _isLockedByOther(TransferLine l, String myUid) {
    final lock = l.lock;
    if (lock == null) return false;
    if (lock.isExpired) return false;
    return lock.userId != myUid;
  }

  bool _isLockedByMe(TransferLine l, String myUid) {
    final lock = l.lock;
    if (lock == null) return false;
    if (lock.isExpired) return false;
    return lock.userId == myUid;
  }

  Future<void> _releaseLock(TransferLine line) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    final role = ref.read(currentRoleProvider);

    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .releaseLock(
            transferId: widget.transferId,
            lineId: line.lineId,
            userId: uid,
            role: role,
          );
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _prepareOrContinue(
    TransferLine line, {
    required bool needsLock,
  }) async {
    if (_busyLineId != null) return;

    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    final role = ref.read(currentRoleProvider);

    setState(() => _busyLineId = line.lineId);

    bool shouldRelease = false;

    try {
      if (needsLock) {
        await ref
            .read(transferLinesRepositoryProvider)
            .tryAcquireLock(
              transferId: widget.transferId,
              lineId: line.lineId,
              userId: uid,
            );
      }

      if (!mounted) return;

      final String? scanned = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      );

      if (!mounted) return;

      if (scanned == null) {
        shouldRelease = true;
        return;
      }

      final validation = BarcodeValidator.validate(scanned);
      if (!validation.ok) {
        shouldRelease = true;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(validation.error!)));
        return;
      }

      await ref
          .read(transferLinesRepositoryProvider)
          .validateAndIncrementPicked(
            transferId: widget.transferId,
            lineId: line.lineId,
            expectedArticle: line.article,
            barcode: scanned,
            userId: uid,
            role: role,
            autoReleaseOnComplete: true,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OK')), // TODO(l10n)
      );
    } on BarcodeMismatchException catch (e) {
      shouldRelease = true;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on OverPickException {
      shouldRelease = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already complete')), // TODO(l10n)
      );
    } on AlreadyHoldingLockException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Already locked: ${e.lineId}')), // TODO(l10n)
      );
    } on LockTakenException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Locked by ${e.lockUserId}')), // TODO(l10n)
      );
    } on LockExpiredException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lock expired, retry.')), // TODO(l10n)
      );
    } on NotLockOwnerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lock required, retry.')), // TODO(l10n)
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')), // TODO(l10n)
      );
    } finally {
      if (shouldRelease) {
        await _releaseLock(line);
      }
      if (mounted) setState(() => _busyLineId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linesAsync = ref.watch(
      transferLinesStreamProvider(widget.transferId),
    );
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer'), // TODO(l10n)
      ),
      body: linesAsync.when(
        data: (lines) {
          if (lines.isEmpty) {
            return const Center(child: Text('No lines')); // TODO(l10n)
          }

          final grouped = <String, List<TransferLine>>{};
          for (final l in lines) {
            (grouped[l.category.isEmpty ? '—' : l.category] ??= []).add(l);
          }
          final categories = grouped.keys.toList()..sort();

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              final catLines = grouped[cat]!;
              return _CategorySection(
                category: cat,
                lines: catLines,
                busyLineId: _busyLineId,
                myUid: uid,
                isCompleted: _isCompleted,
                isLockedByOther: _isLockedByOther,
                isLockedByMe: _isLockedByMe,
                onPrepare: (line) => _prepareOrContinue(line, needsLock: true),
                onContinue: (line) =>
                    _prepareOrContinue(line, needsLock: false),
                onCancel: _releaseLock,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')), // TODO(l10n)
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.lines,
    required this.busyLineId,
    required this.myUid,
    required this.isCompleted,
    required this.isLockedByOther,
    required this.isLockedByMe,
    required this.onPrepare,
    required this.onContinue,
    required this.onCancel,
  });

  final String category;
  final List<TransferLine> lines;
  final String? busyLineId;
  final String? myUid;

  final bool Function(TransferLine) isCompleted;
  final bool Function(TransferLine, String) isLockedByOther;
  final bool Function(TransferLine, String) isLockedByMe;

  final Future<void> Function(TransferLine) onPrepare;
  final Future<void> Function(TransferLine) onContinue;
  final Future<void> Function(TransferLine) onCancel;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(category),
      children: [
        for (final l in lines)
          _LineTile(
            line: l,
            busyLineId: busyLineId,
            myUid: myUid,
            isCompleted: isCompleted,
            isLockedByOther: isLockedByOther,
            isLockedByMe: isLockedByMe,
            onPrepare: onPrepare,
            onContinue: onContinue,
            onCancel: onCancel,
          ),
      ],
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.busyLineId,
    required this.myUid,
    required this.isCompleted,
    required this.isLockedByOther,
    required this.isLockedByMe,
    required this.onPrepare,
    required this.onContinue,
    required this.onCancel,
  });

  final TransferLine line;
  final String? busyLineId;
  final String? myUid;

  final bool Function(TransferLine) isCompleted;
  final bool Function(TransferLine, String) isLockedByOther;
  final bool Function(TransferLine, String) isLockedByMe;

  final Future<void> Function(TransferLine) onPrepare;
  final Future<void> Function(TransferLine) onContinue;
  final Future<void> Function(TransferLine) onCancel;

  @override
  Widget build(BuildContext context) {
    final uid = myUid;
    final completed = isCompleted(line);

    final lockedByOther = uid != null && isLockedByOther(line, uid);
    final lockedByMe = uid != null && isLockedByMe(line, uid);

    final lockedBy = lockedByOther ? (line.lock?.userId ?? '') : '';

    final isBusy = busyLineId == line.lineId;
    final disablePrimary = completed || lockedByOther || isBusy || uid == null;

    final primaryLabel = completed
        ? 'Done' // TODO(l10n)
        : (lockedByMe ? 'Continue' : 'Prepare'); // TODO(l10n)

    return ListTile(
      title: Text('${line.article} — ${line.name}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planned: ${line.qtyPlanned} | Picked: ${line.qtyPicked}', // TODO(l10n)
          ),
          if (lockedByOther)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    lockedBy.isNotEmpty
                        ? 'Locked by $lockedBy'
                        : 'Locked by other', // TODO(l10n)
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lockedByMe && !completed)
            IconButton(
              onPressed: isBusy ? null : () => onCancel(line),
              icon: const Icon(Icons.close),
              tooltip: 'Cancel preparation', // TODO(l10n)
            ),
          FilledButton(
            onPressed: disablePrimary
                ? null
                : () => lockedByMe ? onContinue(line) : onPrepare(line),
            child: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}
