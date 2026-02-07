import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';
import '../../data/models/transfer.dart';
import '../../data/models/transfer_line.dart';
import '../../data/models/user_profile.dart';
import 'transfer_checking_controller.dart' as check;
import 'transfer_picking_controller.dart' as pick;
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

  bool _isStorekeeperOrAdmin(WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    return profileAsync.maybeWhen(
      data: (p) =>
          p != null &&
          (p.role == UserRole.admin || p.role == UserRole.storekeeper),
      orElse: () => false,
    );
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    final transferAsync = ref.watch(transferDocProvider(widget.transferId));
    final linesAsync = ref.watch(transferLinesProvider(widget.transferId));

    final isStorekeeperOrAdmin = _isStorekeeperOrAdmin(ref);

    final pickingState = ref.watch(transferPickingControllerProvider);
    final picking = ref.read(transferPickingControllerProvider.notifier);

    final checkingState = ref.watch(transferCheckingControllerProvider);
    final checking = ref.read(transferCheckingControllerProvider.notifier);

    final controllerBusy = pickingState.isLoading || checkingState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer'), // TODO(l10n)
      ),
      body: Column(
        children: [
          transferAsync.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, _) => const SizedBox(height: 2),
            data: (t) => _Header(
              transfer: t,
              isStorekeeperOrAdmin: isStorekeeperOrAdmin,
              onStartChecking:
                  (t.status == TransferStatus.picked &&
                      isStorekeeperOrAdmin &&
                      !controllerBusy)
                  ? () async {
                      try {
                        await checking.startChecking(
                          transferId: widget.transferId,
                        );
                        _snack('Checking started'); // TODO(l10n)
                      } catch (e) {
                        _snack('$e'); // TODO(l10n)
                      }
                    }
                  : null,
              onFinish:
                  (t.status == TransferStatus.checking &&
                      isStorekeeperOrAdmin &&
                      !controllerBusy)
                  ? () async {
                      final lines = linesAsync.value ?? const <TransferLine>[];
                      final allChecked =
                          lines.isNotEmpty &&
                          lines.every((l) => l.qtyChecked >= l.qtyPlanned);

                      if (!allChecked) {
                        _snack('Finish blocked: not all checked'); // TODO(l10n)
                        return;
                      }

                      try {
                        await checking.finish(
                          transferId: widget.transferId,
                          currentLines: lines,
                        );
                        _snack('Finished'); // TODO(l10n)
                      } catch (e) {
                        _snack('$e'); // TODO(l10n)
                      }
                    }
                  : null,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: linesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')), // TODO(l10n)
              data: (lines) {
                if (lines.isEmpty) {
                  return const Center(child: Text('No lines')); // TODO(l10n)
                }

                final transferStatus = transferAsync.value?.status;

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
                            transferStatus: transferStatus,
                            isStorekeeperOrAdmin: isStorekeeperOrAdmin,
                            busy: controllerBusy,
                            onPrepare: (uid == null)
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
                            onCancelPick: (uid == null)
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
                            onScanPick: (uid == null)
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
                                    } on pick.ScanCancelledException {
                                      // no snackbar
                                    } catch (e) {
                                      _snack('$e'); // TODO(l10n)
                                    }
                                  },
                            onCheck: (uid == null)
                                ? null
                                : () async {
                                    try {
                                      await checking.checkLine(
                                        context,
                                        transferId: widget.transferId,
                                        line: line,
                                      );
                                      _snack('Checked +1'); // TODO(l10n)
                                    } on check.ScanCancelledException {
                                      // no snackbar
                                    } catch (e) {
                                      _snack('$e'); // TODO(l10n)
                                    }
                                  },
                            onCancelCheck: (uid == null)
                                ? null
                                : () async {
                                    try {
                                      await checking.cancelCheckLine(
                                        transferId: widget.transferId,
                                        lineId: line.id,
                                      );
                                      _snack('Check cancelled'); // TODO(l10n)
                                    } catch (e) {
                                      _snack('$e'); // TODO(l10n)
                                    }
                                  },
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.transfer,
    required this.isStorekeeperOrAdmin,
    required this.onStartChecking,
    required this.onFinish,
  });

  final Transfer transfer;
  final bool isStorekeeperOrAdmin;
  final VoidCallback? onStartChecking;
  final VoidCallback? onFinish;

  String _statusLabel(TransferStatus s) {
    switch (s) {
      case TransferStatus.new_:
        return 'New'; // TODO(l10n)
      case TransferStatus.picking:
        return 'In progress'; // TODO(l10n)
      case TransferStatus.picked:
        return 'Picked'; // TODO(l10n)
      case TransferStatus.checking:
        return 'Checking'; // TODO(l10n)
      case TransferStatus.done:
        return 'Done'; // TODO(l10n)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _statusLabel(transfer.status),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (isStorekeeperOrAdmin) ...[
              if (onStartChecking != null)
                FilledButton(
                  onPressed: onStartChecking,
                  child: const Text('Start checking'), // TODO(l10n)
                ),
              if (onFinish != null) ...[
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onFinish,
                  child: const Text('Finish'), // TODO(l10n)
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.myUid,
    required this.transferStatus,
    required this.isStorekeeperOrAdmin,
    required this.busy,
    required this.onPrepare,
    required this.onScanPick,
    required this.onCancelPick,
    required this.onCheck,
    required this.onCancelCheck,
  });

  final TransferLine line;
  final String? myUid;
  final TransferStatus? transferStatus;
  final bool isStorekeeperOrAdmin;
  final bool busy;

  final VoidCallback? onPrepare;
  final VoidCallback? onScanPick;
  final VoidCallback? onCancelPick;

  final VoidCallback? onCheck;
  final VoidCallback? onCancelCheck;

  @override
  Widget build(BuildContext context) {
    final uid = myUid;

    final pickLockedByMe =
        uid != null &&
        line.lock != null &&
        !line.lock!.isExpired &&
        line.lock!.userId == uid;
    final pickLockedByOther =
        uid != null &&
        line.lock != null &&
        !line.lock!.isExpired &&
        line.lock!.userId != uid;

    final checkLockedByMe =
        uid != null &&
        line.checkedLock != null &&
        !line.checkedLock!.isExpired &&
        line.checkedLock!.userId == uid;
    final checkLockedByOther =
        uid != null &&
        line.checkedLock != null &&
        !line.checkedLock!.isExpired &&
        line.checkedLock!.userId != uid;

    final pickedDone = line.qtyPicked >= line.qtyPlanned;
    final checkedDone = line.qtyChecked >= line.qtyPlanned;

    final canPickPrepare =
        !busy &&
        uid != null &&
        !pickedDone &&
        !pickLockedByMe &&
        !pickLockedByOther;
    final canPickScan = !busy && uid != null && !pickedDone && pickLockedByMe;
    final canPickCancel = !busy && uid != null && !pickedDone && pickLockedByMe;

    final checkingMode = transferStatus == TransferStatus.checking;

    final canCheck =
        !busy &&
        uid != null &&
        isStorekeeperOrAdmin &&
        checkingMode &&
        pickedDone &&
        !checkedDone &&
        !checkLockedByOther;

    final canCheckCancel =
        !busy &&
        uid != null &&
        isStorekeeperOrAdmin &&
        checkingMode &&
        !checkedDone &&
        checkLockedByMe;

    final subtitle = StringBuffer()
      ..write(
        '${line.article} • Picked ${line.qtyPicked}/${line.qtyPlanned}',
      ); // TODO(l10n)

    if (isStorekeeperOrAdmin || checkingMode) {
      subtitle.write(
        ' • Checked ${line.qtyChecked}/${line.qtyPlanned}',
      ); // TODO(l10n)
    }

    if (pickLockedByOther) subtitle.write(' • Locked (pick)'); // TODO(l10n)
    if (checkLockedByOther) subtitle.write(' • Locked (check)'); // TODO(l10n)

    return ListTile(
      title: Text(line.name.isEmpty ? line.article : line.name),
      subtitle: Text(subtitle.toString()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DONE badge for loader-only view
          if (pickedDone && (!isStorekeeperOrAdmin && !checkingMode))
            Container(
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
          else ...[
            // Loader picking actions
            if (canPickCancel)
              IconButton(
                onPressed: onCancelPick,
                tooltip: 'Cancel', // TODO(l10n)
                icon: const Icon(Icons.close),
              ),
            FilledButton(
              onPressed: canPickPrepare ? onPrepare : null,
              child: const Text('Prepare'), // TODO(l10n)
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: canPickScan ? onScanPick : null,
              child: const Text('Scan'), // TODO(l10n)
            ),

            // Storekeeper checking actions (only while status=checking)
            if (isStorekeeperOrAdmin && checkingMode) ...[
              const SizedBox(width: 12),
              if (canCheckCancel)
                IconButton(
                  onPressed: onCancelCheck,
                  tooltip: 'Cancel check', // TODO(l10n)
                  icon: const Icon(Icons.close),
                ),
              FilledButton(
                onPressed: canCheck ? onCheck : null,
                child: const Text('Check'), // TODO(l10n)
              ),
            ],
          ],
        ],
      ),
    );
  }
}
