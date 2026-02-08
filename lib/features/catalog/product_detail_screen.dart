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
    // ignore: unused_local_variable
    final validation = BarcodeValidator.validate(scanned, l10n);

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // Чистый фон
      appBar: AppBar(title: const Text('Карточка товара'), centerTitle: true),
      body: productAsync.when(
        data: (p) {
          if (p == null) {
            return Center(child: Text(l10n.productNotFound(widget.article)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Блок Категории (Чип по центру)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.category.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Название товара (Крупно и по центру)
                Text(
                  p.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 32),

                // 3. Блок Технических данных (Карточка)
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.tag,
                          label: l10n.labelArticle,
                          value: p.article,
                          isMono: true,
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.qr_code,
                          label: l10n.labelBarcode,
                          value: p.barcode ?? '—',
                          isMono: true,
                          valueColor: p.barcode == null
                              ? Colors.grey
                              : theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 4. Кнопка "Привязать штрихкод"
                if (canBind)
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _binding ? null : _bind,
                      icon: _binding
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.qr_code_scanner),
                      label: Text(
                        _binding ? l10n.statusBinding : l10n.actionBindBarcode,
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                if (!canBind)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        l10n.errorNotAllowed,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMono = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isMono;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: isMono ? 'Monospace' : null,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
