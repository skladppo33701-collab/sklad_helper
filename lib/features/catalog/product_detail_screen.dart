import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/providers.dart';
import '../../data/repos/barcode_repository.dart';
import '../../utils/barcode_validator.dart';
import 'barcode_scanner_screen.dart';
import 'catalog_providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.article});
  final String article;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _binding = false;

  Future<void> _bind(BuildContext context) async {
    if (_binding) return;

    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() => _binding = true);
    try {
      final scanned = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      );

      if (!mounted) return;

      if (scanned == null) return;

      final validation = BarcodeValidator.validate(scanned);
      if (!validation.ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(validation.error!)));
        return;
      }

      await ref
          .read(barcodeRepositoryProvider)
          .bindBarcode(
            article: widget.article,
            barcode: scanned,
            createdByUid: uid,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcode bound')), // TODO(l10n)
      );
    } on BarcodeConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on ProductAlreadyBoundException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')), // TODO(l10n)
      );
    } finally {
      if (!mounted) return;
      setState(() => _binding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canBind = ref.watch(canBindBarcodeProvider);
    final productAsync = ref.watch(productByArticleProvider(widget.article));

    return Scaffold(
      appBar: AppBar(
        title: Text('Product: ${widget.article}'), // TODO(l10n)
        actions: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close', // TODO(l10n)
          ),
        ],
      ),
      body: productAsync.when(
        data: (p) {
          if (p == null) {
            return const Center(child: Text('Not found')); // TODO(l10n)
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(p.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Article: ${p.article}'), // TODO(l10n)
                Text('Category: ${p.category}'), // TODO(l10n)
                const SizedBox(height: 12),
                Text('Barcode: ${p.barcode ?? '—'}'), // TODO(l10n)
                const Spacer(),
                if (canBind)
                  FilledButton.icon(
                    onPressed: _binding ? null : () => _bind(context),
                    icon: _binding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.qr_code_scanner),
                    label: Text(
                      _binding ? 'Binding…' : 'Bind barcode', // TODO(l10n)
                    ),
                  )
                else
                  const Text(
                    'Not allowed.', // TODO(l10n)
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')), // TODO(l10n)
      ),
    );
  }
}
