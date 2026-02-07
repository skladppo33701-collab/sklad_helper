import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';
import '../../data/models/transfer_line.dart';
import '../../data/repos/transfer_lines_repository.dart';
import 'transfer_picking_controller.dart';
import 'transfers_providers.dart';

class TransferDetailScreen extends ConsumerStatefulWidget {
  const TransferDetailScreen({super.key, required this.transferId});
  final String transferId;

  @override
  ConsumerState<TransferDetailScreen> createState() =>
      _TransferDetailScreenState();
}

class _TransferDetailScreenState extends ConsumerState<TransferDetailScreen> {
  String? get _uid => ref.read(firebaseAuthProvider).currentUser?.uid;

  bool _lockedByOther(TransferLine line, String myUid) {
    final lock = line.lock;
    if (lock == null) return false;
    if (lock.isExpired) return false;
    return lock.userId != myUid;
  }

  bool _lockedByMe(TransferLine line, String myUid) {
    final lock = line.lock;
    if (lock == null) return false;
    if (lock.isExpired) return false;
    return lock.userId == myUid;
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final linesAsync = ref.watch(transferLinesProvider(widget.transferId));
    final pickingCtrl = ref.watch(transferPickingControllerProvider);
    final picking = ref.read(transferPickingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer'), // TODO(l10n)
      ),
      body: linesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')), // TODO(l10n)
        data: (lines) {
          if (lines.isEmpty) {
            return const Center(child: Text('No lines')); // TODO(l10n)
          }

          // Group by category
          final grouped = <String, List<TransferLine>>{};
          for (final l in lines) {
            final cat = l.category.isEmpty ? '—' : l.category;
            (grouped[cat] ??= []).add(l);
          }
          final cats = grouped.keys.toList()..sort();

          return ListView.builder(
            itemCount: cats.length,
            itemBuilder: (context, i) {
              final cat = cats[i];
              final catLines = grouped[cat]!;
              return ExpansionTile(
                title: Text(cat),
                children: [
                  for (final line in catLines)
                    _LineTile(
                      line: line,
                      myUid: uid,
                      controllerBusy: pickingCtrl.isLoading,
                      lockedByMe: uid != null && _lockedByMe(line, uid),
                      lockedByOther: uid != null && _lockedByOther(line, uid),
                      onPrepare: uid == null
                          ? null
                          : () async {
                              try {
                                await picking.prepareLine(
                                  transferId: widget.transferId,
                                  lineId: line.id,
                                );
                                _snack('Prepared'); // TODO(l10n)
                              } catch (e) {
                                _snack('$e'); // TODO(l10n)
                              }
                            },
                      onCancel: uid == null
                          ? null
                          : () async {
                              try {
                                await picking.cancelLine(
                                  transferId: widget.transferId,
                                  lineId: line.id,
                                );
                                _snack('Cancelled'); // TODO(l10n)
                              } catch (e) {
                                _snack('$e'); // TODO(l10n)
                              }
                            },
                      onScan: uid == null
                          ? null
                          : () async {
                              try {
                                await picking.scanAndPick(
                                  context,
                                  transferId: widget.transferId,
                                  lineId: line.id,
                                  expectedArticle: line.article,
                                );
                                _snack('OK'); // TODO(l10n)
                              } on ScanCancelledException {
                                // Don’t auto release here; user has explicit Cancel.
                              } on UnknownBarcodeException {
                                _snack('Unknown barcode'); // TODO(l10n)
                              } on WrongItemException {
                                _snack('Wrong item'); // TODO(l10n)
                              } on FormatException catch (_) {
                                _snack('Invalid barcode'); // TODO(l10n)
                              } on LockExpiredException {
                                _snack(
                                  'Lock expired. Prepare again.',
                                ); // TODO(l10n)
                              } on NotLockOwnerException {
                                _snack('Prepare first.'); // TODO(l10n)
                              } on OverPickException {
                                _snack('Already completed.'); // TODO(l10n)
                              } catch (e) {
                                _snack('Error: $e'); // TODO(l10n)
                              }
                            },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.myUid,
    required this.controllerBusy,
    required this.lockedByMe,
    required this.lockedByOther,
    required this.onPrepare,
    required this.onScan,
    required this.onCancel,
  });

  final TransferLine line;
  final String? myUid;
  final bool controllerBusy;
  final bool lockedByMe;
  final bool lockedByOther;

  final VoidCallback? onPrepare;
  final VoidCallback? onScan;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final completed = line.isCompleted;

    final lockLabel = completed
        ? 'Done' // TODO(l10n)
        : lockedByMe
        ? 'Locked by me' // TODO(l10n)
        : lockedByOther
        ? 'Locked by other' // TODO(l10n)
        : 'Available'; // TODO(l10n)

    final disableAll = controllerBusy || myUid == null;
    final canPrepare =
        !disableAll && !completed && !lockedByMe && !lockedByOther;
    final canScan = !disableAll && !completed && lockedByMe;
    final canCancel = !disableAll && !completed && lockedByMe;

    return ListTile(
      title: Text(line.name.isEmpty ? line.article : line.name),
      subtitle: Text(
        '${line.article} • ${line.qtyPicked}/${line.qtyPlanned} • $lockLabel',
      ), // TODO(l10n)
      trailing: completed
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'DONE',
                style: Theme.of(context).textTheme.labelSmall,
              ), // TODO(l10n)
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (lockedByMe)
                  IconButton(
                    onPressed: canCancel ? onCancel : null,
                    tooltip: 'Cancel', // TODO(l10n)
                    icon: const Icon(Icons.close),
                  ),
                FilledButton(
                  onPressed: canPrepare ? onPrepare : null,
                  child: const Text('Prepare'), // TODO(l10n)
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: canScan ? onScan : null,
                  child: const Text('Scan'), // TODO(l10n)
                ),
              ],
            ),
    );
  }
}
