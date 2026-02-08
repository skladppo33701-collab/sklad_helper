import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../data/models/transfer.dart';
import 'transfers_providers.dart';
import 'transfer_import_controller.dart';

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
            const SnackBar(content: Text('Файлы успешно загружены!')),
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
        appBar: AppBar(title: const Text('Transfers')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ref.read(transferImportProvider).pickAndUploadExcel();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Файл загружен')),
              );
            } catch (e) {
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Ошибка: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.upload_file),
          label: const Text('Import Excel'),
        ),
        body: Stack(
          children: [
            transfersAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No transfers.\nDrag & Drop .xlsx files here!'),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = items[i];

                    // --- СВАЙП ДЛЯ УДАЛЕНИЯ ---
                    return Dismissible(
                      key: Key(t.transferId), // Уникальный ключ обязателен
                      direction:
                          DismissDirection.endToStart, // Свайп справа налево
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        // 1. Запоминаем ID и мессенджер
                        final id = t.transferId;
                        final repo = ref.read(transferRepositoryProvider);
                        final messenger = ScaffoldMessenger.of(context);

                        // 2. Удаляем (Soft Delete)
                        repo.deleteTransfer(id);

                        // 3. Показываем SnackBar с таймером (duration) и отменой
                        messenger.clearSnackBars();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Перемещение "${t.title}" удалено'),
                            duration: const Duration(
                              seconds: 4,
                            ), // Таймер 4 сек
                            action: SnackBarAction(
                              label: 'ОТМЕНА',
                              textColor: Colors.yellow,
                              onPressed: () {
                                // 4. Восстанавливаем, если нажали
                                repo.restoreTransfer(id);
                              },
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(t.title),
                        subtitle: Text(
                          'Items: ${t.itemsTotal} | Pcs: ${t.pcsTotal}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: _StatusBadge(status: t.status),
                        onTap: () => context.push('/transfer/${t.transferId}'),
                      ),
                    );
                    // ---------------------------
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
            if (_dragging)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_upload, size: 80, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Drop Excel files here',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TransferStatus status;

  String get _label {
    switch (status) {
      case TransferStatus.new_:
        return 'New';
      case TransferStatus.picking:
        return 'In progress';
      case TransferStatus.picked:
        return 'Picked';
      case TransferStatus.checking:
        return 'Checking';
      case TransferStatus.done:
        return 'Done';
    }
  }

  Color _color(BuildContext context) {
    switch (status) {
      case TransferStatus.new_:
        return Colors.blueGrey;
      case TransferStatus.picking:
        return Colors.orange;
      case TransferStatus.picked:
        return Colors.blue;
      case TransferStatus.checking:
        return Colors.purple;
      case TransferStatus.done:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        _label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
