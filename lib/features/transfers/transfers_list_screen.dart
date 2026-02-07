import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/transfer.dart';
import 'transfers_providers.dart';

class TransfersListScreen extends ConsumerWidget {
  const TransfersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(transfersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'), // TODO(l10n)
      ),
      body: transfersAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No transfers')); // TODO(l10n)
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = items[i];
              return ListTile(
                title: Text(t.title),
                trailing: _StatusBadge(status: t.status),
                onTap: () => context.push('/transfer/${t.transferId}'),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TransferStatus status;

  String get _label {
    switch (status) {
      case TransferStatus.new_:
        return 'NEW'; // TODO(l10n)
      case TransferStatus.picking:
        return 'PICKING'; // TODO(l10n)
      case TransferStatus.picked:
        return 'PICKED'; // TODO(l10n)
      case TransferStatus.checking:
        return 'CHECKING'; // TODO(l10n)
      case TransferStatus.done:
        return 'DONE'; // TODO(l10n)
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(_label, style: theme.textTheme.labelSmall),
    );
  }
}
