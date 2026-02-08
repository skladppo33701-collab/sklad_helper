import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../app/router/providers.dart';
import '../../utils/barcode_validator.dart';
import '../../utils/exception_mapper.dart';
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

  Future<void> _bind() async {
    if (_binding) return;
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (!mounted || scanned == null) return;

    final l10n = AppLocalizations.of(context);
    final validation = BarcodeValidator.validate(scanned, l10n);

    if (!validation.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.error ?? 'Invalid barcode'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _binding = true);
    try {
      await ref
          .read(barcodeRepositoryProvider)
          .bindBarcode(
            article: widget.article,
            barcode: scanned,
            createdByUid: uid,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.successBound)));
      ref.invalidate(productByArticleProvider(widget.article));
    } catch (e) {
      if (!mounted) return;
      final msg = ExceptionMapper.map(context, e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _binding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByArticleProvider(widget.article));
    final canBind = ref.watch(canBindBarcodeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.article)),
      body: productAsync.when(
        data: (p) {
          if (p == null) {
            return Center(child: Text(l10n.productNotFound(widget.article)));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(p.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${l10n.labelArticle}: ${p.article}'),
                Text('${l10n.labelCategory}: ${p.category}'),
                const SizedBox(height: 12),
                Text('${l10n.labelBarcode}: ${p.barcode ?? '—'}'),
                const Spacer(),
                if (canBind)
                  FilledButton.icon(
                    onPressed: _binding ? null : _bind,
                    icon: _binding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.qr_code_scanner),
                    label: Text(
                      _binding ? l10n.statusBinding : l10n.actionBindBarcode,
                    ),
                  )
                else
                  Text(
                    l10n.errorNotAllowed,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric(e.toString()))),
      ),
    );
  }
}
