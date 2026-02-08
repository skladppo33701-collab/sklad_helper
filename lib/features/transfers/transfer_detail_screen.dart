import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/providers.dart';
import '../../app/theme/app_dimens.dart';
import '../../data/models/transfer.dart';
import '../../data/models/transfer_line.dart';
import '../../data/models/user_profile.dart';
import '../../l10n/app_localizations.dart'; // Ensure import matches your project
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
    final transferAsync = ref.watch(transferDocProvider(widget.transferId));
    final linesAsync = ref.watch(transferLinesProvider(widget.transferId));
    final isStorekeeperOrAdmin = _isStorekeeperOrAdmin(ref);

    final picking = ref.read(transferPickingControllerProvider.notifier);
    final checking = ref.read(transferCheckingControllerProvider.notifier);

    final pickingState = ref.watch(transferPickingControllerProvider);
    final checkingState = ref.watch(transferCheckingControllerProvider);
    final controllerBusy = pickingState.isLoading || checkingState.isLoading;

    // Localization
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        // Используем новый ключ локализации
        title: Text(l10n.transferDetails),
      ),
      body: transferAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric(e.toString()))),
        data: (transfer) {
          return Column(
            children: [
              // 1. Elevated Header
              _TransferHeaderCard(
                transfer: transfer,
                l10n: l10n,
                isStorekeeperOrAdmin: isStorekeeperOrAdmin,
                controllerBusy: controllerBusy,
                onStartChecking: () async {
                  try {
                    await checking.startChecking(transferId: widget.transferId);
                    _snack(l10n.msgCheckingStarted);
                  } catch (e) {
                    _snack('$e');
                  }
                },
                onFinish: () async {
                  try {
                    final lines = linesAsync.value ?? [];
                    await checking.finish(
                      transferId: widget.transferId,
                      currentLines: lines,
                    );
                    _snack(l10n.msgFinished);
                  } catch (e) {
                    _snack('$e');
                  }
                },
              ),

              // 2. Lines List
              Expanded(
                child: linesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text(l10n.errorGeneric(e.toString()))),
                  data: (lines) {
                    if (lines.isEmpty) {
                      return _buildEmptyState(context, l10n);
                    }
                    return _buildLinesList(
                      context,
                      l10n,
                      lines,
                      transfer.status,
                      isStorekeeperOrAdmin,
                      controllerBusy,
                      picking,
                      checking,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppDimens.x16),
          Text(
            l10n.labelNoLines,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinesList(
    BuildContext context,
    AppLocalizations l10n,
    List<TransferLine> lines,
    TransferStatus status,
    bool isAdmin,
    bool busy,
    pick.TransferPickingController picking,
    check.TransferCheckingController checking,
  ) {
    final grouped = <String, List<TransferLine>>{};
    for (final l in lines) {
      final cat = l.category.isEmpty ? '—' : l.category;
      (grouped[cat] ??= []).add(l);
    }
    final cats = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.x16),
      itemCount: cats.length,
      itemBuilder: (context, i) {
        final cat = cats[i];
        final catLines = grouped[cat]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.x8,
                  vertical: AppDimens.x8,
                ),
                child: Text(
                  cat.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: catLines
                      .map(
                        (line) => _LineItem(
                          line: line,
                          l10n: l10n,
                          myUid: _uid,
                          transferStatus: status,
                          isStorekeeperOrAdmin: isAdmin,
                          busy: busy,
                          onPrepare: () async => picking.prepareLine(
                            transferId: widget.transferId,
                            lineId: line.id,
                          ),
                          onCancelPick: () async => picking.cancelLine(
                            transferId: widget.transferId,
                            lineId: line.id,
                          ),
                          onScanPick: () async => picking.scanAndPick(
                            context,
                            transferId: widget.transferId,
                            lineId: line.id,
                            expectedArticle: line.article,
                          ),
                          onCheck: () async => checking.checkLine(
                            context,
                            transferId: widget.transferId,
                            line: line,
                          ),
                          onCancelCheck: () async => checking.cancelCheckLine(
                            transferId: widget.transferId,
                            lineId: line.id,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TransferHeaderCard extends StatelessWidget {
  final Transfer transfer;
  final AppLocalizations l10n;
  final bool isStorekeeperOrAdmin;
  final bool controllerBusy;
  final VoidCallback onStartChecking;
  final VoidCallback onFinish;

  const _TransferHeaderCard({
    required this.transfer,
    required this.l10n,
    required this.isStorekeeperOrAdmin,
    required this.controllerBusy,
    required this.onStartChecking,
    required this.onFinish,
  });

  String _statusLabel(TransferStatus s) {
    switch (s) {
      case TransferStatus.new_:
        return l10n.statusNew;
      case TransferStatus.picking:
        return l10n.statusPicking;
      case TransferStatus.picked:
        return l10n.statusPicked;
      case TransferStatus.checking:
        return l10n.statusChecking;
      case TransferStatus.done:
        return l10n.statusDone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    switch (transfer.status) {
      case TransferStatus.new_:
        statusColor = Colors.blue;
        break;
      case TransferStatus.picking:
        statusColor = Colors.orange;
        break;
      case TransferStatus.picked:
        statusColor = Colors.purple;
        break;
      case TransferStatus.checking:
        statusColor = Colors.indigo;
        break;
      case TransferStatus.done:
        statusColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.x20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        // Fixed: .withOpacity -> .withValues
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.title.isNotEmpty
                          ? transfer.title
                          : 'Transfer #${transfer.transferId.substring(0, 6)}',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        // Fixed: .withOpacity -> .withValues
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _statusLabel(transfer.status).toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isStorekeeperOrAdmin)
                if (transfer.status == TransferStatus.picked)
                  FilledButton.icon(
                    onPressed: controllerBusy ? null : onStartChecking,
                    icon: const Icon(Icons.fact_check),
                    label: Text(l10n.btnStartChecking),
                  )
                else if (transfer.status == TransferStatus.checking)
                  FilledButton.icon(
                    onPressed: controllerBusy ? null : onFinish,
                    icon: const Icon(Icons.check_circle),
                    label: Text(l10n.btnFinish),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  final TransferLine line;
  final String? myUid;
  final AppLocalizations l10n;
  final TransferStatus? transferStatus;
  final bool isStorekeeperOrAdmin;
  final bool busy;
  final VoidCallback onPrepare,
      onScanPick,
      onCancelPick,
      onCheck,
      onCancelCheck;

  const _LineItem({
    required this.line,
    required this.l10n,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = myUid;

    final pickedDone = line.qtyPicked >= line.qtyPlanned;
    final checkedDone = line.qtyChecked >= line.qtyPlanned;
    final pickLockedByMe =
        uid != null &&
        line.lock?.userId == uid &&
        !(line.lock?.isExpired ?? true);
    final pickLockedByOther =
        uid != null &&
        line.lock?.userId != uid &&
        !(line.lock?.isExpired ?? true);
    final checkingMode = transferStatus == TransferStatus.checking;

    final double pickProgress = line.qtyPlanned > 0
        ? line.qtyPicked / line.qtyPlanned
        : 0;

    return Container(
      decoration: BoxDecoration(
        // Fixed: .withOpacity -> .withValues
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.x16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.name.isNotEmpty ? line.name : 'Unknown Item',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        line.article,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'Monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                if (pickLockedByOther)
                  Icon(Icons.lock, size: 16, color: theme.colorScheme.error),
              ],
            ),

            const SizedBox(height: AppDimens.x12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Picked', style: theme.textTheme.labelSmall),
                          Text(
                            '${line.qtyPicked}/${line.qtyPlanned}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pickProgress,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: pickedDone
                            ? Colors.green
                            : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                if (isStorekeeperOrAdmin || checkingMode) ...[
                  const SizedBox(width: AppDimens.x16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Checked', style: theme.textTheme.labelSmall),
                            Text(
                              '${line.qtyChecked}/${line.qtyPlanned}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: line.qtyPlanned > 0
                              ? line.qtyChecked / line.qtyPlanned
                              : 0,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: checkedDone ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppDimens.x12),

            if (!pickedDone || checkingMode)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!pickedDone && uid != null && !pickLockedByOther) ...[
                    if (pickLockedByMe) ...[
                      IconButton.filledTonal(
                        onPressed: onCancelPick,
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.errorContainer,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onScanPick,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(l10n.btnScan),
                      ),
                    ] else
                      OutlinedButton(
                        onPressed: onPrepare,
                        child: Text(l10n.btnPrepare),
                      ),
                  ],

                  if (checkingMode &&
                      pickedDone &&
                      !checkedDone &&
                      isStorekeeperOrAdmin) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onCheck,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(l10n.btnCheck),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                    ),
                  ],
                ],
              )
            else if (pickedDone && !checkingMode)
              Align(
                alignment: Alignment.centerRight,
                // Fixed: .withOpacity -> .withValues
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
