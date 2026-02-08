import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transfer.dart';
import '../../data/models/transfer_line.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/exception_mapper.dart';
import 'transfers_providers.dart';
import 'transfer_picking_controller.dart';
import 'transfer_checking_controller.dart';

class TransferDetailScreen extends ConsumerStatefulWidget {
  const TransferDetailScreen({super.key, required this.transferId});
  final String transferId;

  @override
  ConsumerState<TransferDetailScreen> createState() =>
      _TransferDetailScreenState();
}

class _TransferDetailScreenState extends ConsumerState<TransferDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // Используем правильные имена провайдеров
    final transferAsync = ref.watch(transferStreamProvider(widget.transferId));
    final linesAsync = ref.watch(
      transferLinesStreamProvider(widget.transferId),
    );

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transferTitle)),
      body: transferAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric(e.toString()))),
        data: (transfer) {
          if (transfer == null) {
            return Center(child: Text(l10n.transferNotFound));
          }

          return Column(
            children: [
              _TransferHeader(transfer: transfer, l10n: l10n),
              const Divider(height: 1),

              Expanded(
                child: linesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Lines error: $e')),
                  data: (lines) {
                    if (lines.isEmpty) {
                      return Center(child: Text(l10n.listEmpty));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: lines.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final line = lines[i];
                        return _TransferLineTile(
                          line: line,
                          transfer: transfer,
                          l10n: l10n,
                          onPick: () => _handlePick(context, transfer, line),
                          onCheck: () => _handleCheck(context, transfer, line),
                          onCancel: () =>
                              _handleCancel(context, transfer, line),
                        );
                      },
                    );
                  },
                ),
              ),

              _BottomActions(
                transfer: transfer,
                l10n: l10n,
                lines: linesAsync.value ?? [],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handlePick(
    BuildContext context,
    Transfer t,
    TransferLine line,
  ) async {
    try {
      // Используем ref.read для вызова методов контроллера
      await ref
          .read(transferPickingControllerProvider.notifier)
          .prepareLine(transferId: t.transferId, lineId: line.id);
      if (!context.mounted) return;
      await ref
          .read(transferPickingControllerProvider.notifier)
          .processScan(
            context: context,
            transferId: t.transferId,
            lineId: line.id,
            expectedArticle: line.article,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ExceptionMapper.map(context, e)),
          backgroundColor: Colors.red,
        ),
      );
      // Откат блокировки
      ref
          .read(transferPickingControllerProvider.notifier)
          .cancelLine(transferId: t.transferId, lineId: line.id);
    }
  }

  Future<void> _handleCancel(
    BuildContext context,
    Transfer t,
    TransferLine line,
  ) async {
    await ref
        .read(transferPickingControllerProvider.notifier)
        .cancelLine(transferId: t.transferId, lineId: line.id);
  }

  Future<void> _handleCheck(
    BuildContext context,
    Transfer t,
    TransferLine line,
  ) async {
    try {
      await ref
          .read(transferCheckingControllerProvider.notifier)
          .processScan(context: context, transferId: t.transferId, line: line);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ExceptionMapper.map(context, e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _TransferLineTile extends StatelessWidget {
  final TransferLine line;
  final Transfer transfer;
  final AppLocalizations l10n;
  final VoidCallback onPick;
  final VoidCallback onCheck;
  final VoidCallback onCancel;

  const _TransferLineTile({
    required this.line,
    required this.transfer,
    required this.l10n,
    required this.onPick,
    required this.onCheck,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isPicking = transfer.status == TransferStatus.picking;
    final isChecking = transfer.status == TransferStatus.checking;

    Widget? trailing;
    // Логика иконок
    if (isPicking) {
      if (line.pickedUid != null) {
        trailing = const Icon(Icons.lock, color: Colors.orange);
      } else if (line.qtyPicked < line.qtyPlanned) {
        trailing = IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: onPick,
        );
      } else {
        trailing = const Icon(Icons.check, color: Colors.green);
      }
    } else if (isChecking) {
      if (line.qtyChecked < line.qtyPicked) {
        trailing = IconButton(
          icon: const Icon(Icons.fact_check),
          onPressed: onCheck,
        );
      } else {
        trailing = const Icon(Icons.done_all, color: Colors.blue);
      }
    }

    return ListTile(
      title: Text(line.name),
      subtitle: Text(
        // Используем .toString(), так как в ARB мы задали тип String для этих параметров
        isChecking
            ? l10n.subChecked(
                line.qtyChecked.toString(),
                line.qtyPlanned.toString(),
              )
            : l10n.subPicked(
                line.qtyPicked.toString(),
                line.qtyPlanned.toString(),
              ),
      ),
      isThreeLine: true,
      trailing: trailing,
    );
  }
}

class _TransferHeader extends StatelessWidget {
  final Transfer transfer;
  final AppLocalizations l10n;
  const _TransferHeader({required this.transfer, required this.l10n});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(transfer.title, style: Theme.of(context).textTheme.titleLarge),
          Text('${l10n.status}: ${transfer.status.name}'),
          Text('${l10n.items}: ${transfer.itemsTotal}'),
        ],
      ),
    );
  }
}

class _BottomActions extends ConsumerWidget {
  final Transfer transfer;
  final AppLocalizations l10n;
  final List<TransferLine> lines;
  const _BottomActions({
    required this.transfer,
    required this.l10n,
    required this.lines,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transfer.status == TransferStatus.picking) {
      final allPicked = lines.every((l) => l.qtyPicked >= l.qtyPlanned);
      if (allPicked) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => ref
                .read(transferPickingControllerProvider.notifier)
                .finishPicking(transfer.transferId),
            child: Text(l10n.btnFinishPicking), // Используем локализацию
          ),
        );
      }
    }

    if (transfer.status == TransferStatus.picked) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () => ref
              .read(transferCheckingControllerProvider.notifier)
              .startChecking(transferId: transfer.transferId),
          child: Text(l10n.btnStartChecking),
        ),
      );
    }

    if (transfer.status == TransferStatus.checking) {
      final allChecked = lines.every((l) => l.qtyChecked >= l.qtyPicked);
      if (allChecked) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => ref
                .read(transferCheckingControllerProvider.notifier)
                .finish(transferId: transfer.transferId, currentLines: lines),
            child: Text(l10n.btnFinish),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }
}
