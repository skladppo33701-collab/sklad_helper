import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router/providers.dart';
import '../../data/models/transfer_line.dart';
import '../../data/repos/transfer_lines_repository.dart';
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

  Future<void> _prepare(TransferLine line) async {
    final uid = _uid;
    if (uid == null) return;
    if (_busyLineId != null) return;

    setState(() => _busyLineId = line.id);
    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .acquireLock(
            transferId: widget.transferId,
            lineId: line.id,
            userId: uid,
          );
    } on LockTakenException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Locked by ${e.lockUserId}')), // TODO(l10n)
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')), // TODO(l10n)
      );
    } finally {
      if (mounted) setState(() => _busyLineId = null);
    }
  }

  Future<void> _release(TransferLine line) async {
    final uid = _uid;
    if (uid == null) return;
    if (_busyLineId != null) return;

    setState(() => _busyLineId = line.id);
    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .releaseLock(
            transferId: widget.transferId,
            lineId: line.id,
            userId: uid,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')), // TODO(l10n)
      );
    } finally {
      if (mounted) setState(() => _busyLineId = null);
    }
  }

  Future<void> _scanTemp(TransferLine line) async {
    // Sprint 3: temporary scan button -> just increments.
    final uid = _uid;
    if (uid == null) return;
    if (_busyLineId != null) return;

    setState(() => _busyLineId = line.id);
    try {
      await ref
          .read(transferLinesRepositoryProvider)
          .incrementPicked(
            transferId: widget.transferId,
            lineId: line.id,
            userId: uid,
          );
    } on LockExpiredException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lock expired, prepare again.'),
        ), // TODO(l10n)
      );
    } on NotLockOwnerException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prepare first.')), // TODO(l10n)
      );
    } on OverPickException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already completed.')), // TODO(l10n)
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')), // TODO(l10n)
      );
    } finally {
      if (mounted) setState(() => _busyLineId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    final linesAsync = ref.watch(transferLinesProvider(widget.transferId));

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
          final categories = grouped.keys.toList()..sort();

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              final catLines = grouped[cat]!;
              return ExpansionTile(
                title: Text(cat),
                children: [
                  for (final line in catLines)
                    _LineTile(
                      line: line,
                      myUid: uid,
                      busy: _busyLineId == line.id,
                      lockedByMe: uid != null && _lockedByMe(line, uid),
                      lockedByOther: uid != null && _lockedByOther(line, uid),
                      onPrepare: () => _prepare(line),
                      onScan: () => _scanTemp(line),
                      onRelease: () => _release(line),
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
    required this.busy,
    required this.lockedByMe,
    required this.lockedByOther,
    required this.onPrepare,
    required this.onScan,
    required this.onRelease,
  });

  final TransferLine line;
  final String? myUid;
  final bool busy;
  final bool lockedByMe;
  final bool lockedByOther;
  final VoidCallback onPrepare;
  final VoidCallback onScan;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final completed = line.isCompleted;

    final lockLabel = completed
        ? 'Done' // TODO(l10n)
        : lockedByMe
        ? 'Locked by me' // TODO(l10n)
        : lockedByOther
        ? 'Locked' // TODO(l10n)
        : 'Available'; // TODO(l10n)

    final lockIcon = completed
        ? Icons.check_circle_outline
        : lockedByMe || lockedByOther
        ? Icons.lock_outline
        : Icons.lock_open;

    final canPrepare =
        !completed && !busy && !lockedByOther && !lockedByMe && myUid != null;
    final canScan = !completed && !busy && lockedByMe && myUid != null;
    final canRelease = !completed && !busy && lockedByMe && myUid != null;

    return ListTile(
      title: Text(line.name.isEmpty ? line.article : line.name),
      subtitle: Text(
        '${line.qtyPicked} / ${line.qtyPlanned} • $lockLabel',
      ), // TODO(l10n)
      leading: Icon(lockIcon),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completed)
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
            if (canRelease)
              IconButton(
                onPressed: onRelease,
                tooltip: 'Release', // TODO(l10n)
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
        ],
      ),
    );
  }
}
