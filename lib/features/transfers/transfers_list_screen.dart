import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../data/models/transfer.dart';
import 'transfers_providers.dart';
import '../../l10n/app_localizations.dart';
import 'transfer_import_controller.dart';
import '../../app/widgets/glass_card.dart';

class TransfersListScreen extends ConsumerStatefulWidget {
  const TransfersListScreen({super.key});

  @override
  ConsumerState<TransfersListScreen> createState() =>
      _TransfersListScreenState();
}

class _TransfersListScreenState extends ConsumerState<TransfersListScreen> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final transfersAsync = ref.watch(transfersStreamProvider);
    final l10n = AppLocalizations.of(context);

    return DropTarget(
      onDragDone: (detail) async {
        setState(() => _dragging = false);
        final messenger = ScaffoldMessenger.of(context);
        try {
          await ref
              .read(transferImportProvider)
              .uploadDroppedFiles(detail.files);
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Импорт завершен')),
          );
        } catch (e) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
          );
        }
      },
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      child: Scaffold(
        body: Stack(
          children: [
            // ИСПРАВЛЕНО: Фоновый градиент через BoxShadow (правильный способ)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),

            transfersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Ошибка: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.listEmpty,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 120),
                  itemCount: list.length,
                  // ИСПРАВЛЕНО: удалены лишние подчеркивания
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final t = list[i];
                    return _TransferGlassCard(transfer: t, l10n: l10n);
                  },
                );
              },
            ),

            // Кнопка импорта (FAB)
            Positioned(
              right: 16,
              bottom: 100,
              child: FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
                child: const Icon(Icons.upload_file),
                onPressed: () =>
                    ref.read(transferImportProvider).pickAndUploadExcel(),
              ),
            ),

            if (_dragging)
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Icon(
                    Icons.cloud_upload,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TransferGlassCard extends StatelessWidget {
  const _TransferGlassCard({required this.transfer, required this.l10n});
  final Transfer transfer;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push('/transfer/${transfer.transferId}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusBadge(status: transfer.status, l10n: l10n),
              Text(
                _formatDate(transfer.createdAt),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            transfer.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),

          _buildProgressBar(context),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoStat(
                icon: Icons.list,
                label: '${transfer.itemsTotal} ${l10n.items}',
              ),
              _InfoStat(icon: Icons.layers, label: '${transfer.pcsTotal} pcs'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    const double progress = 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress > 0 ? progress : null,
        backgroundColor: Colors.white10,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
        minHeight: 6,
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.l10n});
  final TransferStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case TransferStatus.newTx:
        color = Colors.blueGrey;
        label = l10n.statusNew;
        icon = Icons.new_label;
        break;
      case TransferStatus.picking:
        color = const Color(0xFFFFB74D);
        label = l10n.statusPicking;
        icon = Icons.move_to_inbox;
        break;
      case TransferStatus.picked:
        color = const Color(0xFF29B6F6);
        label = l10n.statusPicked;
        icon = Icons.check_circle_outline;
        break;
      case TransferStatus.checking:
        color = const Color(0xFFAB47BC);
        label = l10n.statusChecking;
        icon = Icons.fact_check_outlined;
        break;
      case TransferStatus.done:
        color = const Color(0xFF66BB6A);
        label = l10n.statusDone;
        icon = Icons.done_all;
        break;
      case TransferStatus.cancelled:
        color = const Color(0xFFEF5350);
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
