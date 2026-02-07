import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router/providers.dart';
import '../../data/models/transfer_line.dart';
import '../../data/repos/transfer_lines_repository.dart';
import '../../utils/barcode_validator.dart';
import '../catalog/barcode_scanner_screen.dart'; // reuse existing scanner
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

  Future<void> _prepareLine(TransferLine line) async {
    if (_busyLineId != null) return;

    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() => _busyLineId = line.lineId);

    try {
      // 1) Acquire lock
      await ref
          .read(transferLinesRepositoryProvider)
          .tryAcquireLock(
            transferId: widget.transferId,
            lineId: line.lineId,
            userId: uid,
          );

      if (!mounted) return;

      // 2) Scan
      final scanned = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      );

      if (!mounted) return;

      if (scanned == null) return;

      // 3) Validate barcode format (EAN-8/13)
      final validation = BarcodeValidator.validate(scanned);
      if (!validation.ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(validation.error!)));
        return;
      }

      // 4) Validate barcode -> article via barcode_index, then increment picked (transaction)
      await ref
          .read(transferLinesRepositoryProvider)
          .validateAndIncrementPicked(
            transferId: widget.transferId,
            lineId: line.lineId,
            expectedArticle: line.article,
            barcode: scanned,
            userId: uid,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OK'))); // TODO(l10n)
    } on LockDeniedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on BarcodeMismatchException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e'))); // TODO(l10n)
    } finally {
      final uid2 = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid2 != null) {
        // best-effort lock release (no-op if not owner)
        await ref
            .read(transferLinesRepositoryProvider)
            .releaseLock(
              transferId: widget.transferId,
              lineId: line.lineId,
              userId: uid2,
            );
      }
      if (mounted) setState(() => _busyLineId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linesAsync = ref.watch(
      transferLinesStreamProvider(widget.transferId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer'), // TODO(l10n)
      ),
      body: linesAsync.when(
        data: (lines) {
          if (lines.isEmpty) {
            return const Center(child: Text('No lines')); // TODO(l10n)
          }

          // group by category
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
                onPrepare: _prepareLine,
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
    required this.onPrepare,
  });

  final String category;
  final List<TransferLine> lines;
  final String? busyLineId;
  final Future<void> Function(TransferLine) onPrepare;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(category),
      children: [
        for (final l in lines)
          ListTile(
            title: Text('${l.article} — ${l.name}'),
            subtitle: Text(
              'Planned: ${l.qtyPlanned} | Picked: ${l.qtyPicked}',
            ), // TODO(l10n) (details only)
            trailing: FilledButton(
              onPressed: busyLineId == null ? () => onPrepare(l) : null,
              child: Text(
                busyLineId == l.lineId ? '...' : 'Prepare',
              ), // TODO(l10n)
            ),
          ),
      ],
    );
  }
}
