import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/product.dart';
import '../../l10n/app_localizations.dart';
import '../../app/theme/app_dimens.dart';
import 'catalog_providers.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _search = TextEditingController();
  Product? _searchResult;
  bool _searching = false;
  bool _hasActiveSearch = false;

  @override
  void initState() {
    super.initState();
    _hasActiveSearch = _search.text.trim().isNotEmpty;
    _search.addListener(() {
      final next = _search.text.trim().isNotEmpty;
      if (next == _hasActiveSearch) return;
      setState(() => _hasActiveSearch = next);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final q = _search.text.trim();
    if (q.isEmpty) {
      setState(() => _searchResult = null);
      return;
    }
    setState(() {
      _searching = true;
      _searchResult = null;
    });
    try {
      final p = await ref
          .read(catalogControllerProvider.notifier)
          .findByArticle(q);
      if (!mounted) return;
      setState(() => _searchResult = p);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogControllerProvider);
    final controller = ref.read(catalogControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogTitle),
        // Кнопка импорта удалена
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  labelText: l10n.searchByArticle,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _search.clear();
                      setState(() => _searchResult = null);
                    },
                    icon: const Icon(Icons.clear),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _doSearch(),
              ),
            ),
            if (_searching) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _hasActiveSearch
                  ? _buildSearchResult(context, l10n)
                  : catalogAsync.when(
                      data: (items) =>
                          _buildList(context, items, controller.hasMore, l10n),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          Center(child: Text(l10n.errorGeneric(e.toString()))),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResult(BuildContext context, AppLocalizations l10n) {
    if (_searching) return const SizedBox.shrink();
    final p = _searchResult;
    if (p == null) {
      return Center(child: Text(l10n.productNotFound('')));
    }
    return ListView(
      padding: const EdgeInsets.all(AppDimens.x16),
      children: [
        _ProductCard(
          product: p,
          onTap: () => context.push('/product/${p.article}'),
          l10n: l10n,
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Product> items,
    bool hasMore,
    AppLocalizations l10n,
  ) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(catalogControllerProvider.notifier).refreshFirstPage(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppDimens.x16),
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i == items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: hasMore
                    ? OutlinedButton(
                        onPressed: () => ref
                            .read(catalogControllerProvider.notifier)
                            .loadMore(),
                        child: Text(l10n.loadMore),
                      )
                    : Text(
                        l10n.listEnd,
                        style: const TextStyle(color: Colors.grey),
                      ),
              ),
            );
          }
          final p = items[i];
          return _ProductCard(
            product: p,
            onTap: () => context.push('/product/${p.article}'),
            l10n: l10n,
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.l10n,
  });

  final Product product;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBarcode = (product.barcode != null && product.barcode!.isNotEmpty);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.category.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  if (hasBarcode)
                    Icon(
                      Icons.qr_code,
                      size: 18,
                      color: theme.colorScheme.primary,
                    )
                  else
                    Icon(
                      Icons.qr_code_2,
                      size: 18,
                      color: theme.colorScheme.error.withValues(alpha: 0.5),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                product.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.tag, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    product.article,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
