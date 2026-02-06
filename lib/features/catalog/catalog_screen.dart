import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/product.dart';
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
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogControllerProvider);
    final controller = ref.read(catalogControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Catalog')), // TODO(l10n)
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  labelText: 'Search by article (exact)', // TODO(l10n)
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _search.clear();
                      setState(() => _searchResult = null);
                    },
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear', // TODO(l10n)
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _doSearch(),
              ),
              const SizedBox(height: 12),
              if (_searching) const LinearProgressIndicator(),
              Expanded(
                child: _hasActiveSearch
                    ? _buildSearchResult(context)
                    : catalogAsync.when(
                        data: (items) =>
                            _buildList(context, items, controller.hasMore),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) =>
                            Center(child: Text('Error: $e')), // TODO(l10n)
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResult(BuildContext context) {
    if (_searching) return const SizedBox.shrink();

    final p = _searchResult;
    if (p == null) {
      return const Center(child: Text('Not found')); // TODO(l10n)
    }

    return ListView(
      children: [
        _ProductTile(
          product: p,
          onTap: () => context.push('/product/${p.article}'),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<Product> items, bool hasMore) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(catalogControllerProvider.notifier).refreshFirstPage(),
      child: ListView.separated(
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const Divider(height: 1),
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
                        child: const Text('Load more'), // TODO(l10n)
                      )
                    : const Text('End'), // TODO(l10n)
              ),
            );
          }

          final p = items[i];
          return _ProductTile(
            product: p,
            onTap: () => context.push('/product/${p.article}'),
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasBarcode = (product.barcode != null && product.barcode!.isNotEmpty);

    final badge = hasBarcode
        ? _Badge(text: product.barcode!, icon: Icons.check_circle_outline)
        : const _Badge(
            text: 'NO BARCODE', // TODO(l10n)
            icon: Icons.qr_code_2_outlined,
          );

    return ListTile(
      title: Text('${product.article} — ${product.name}'),
      subtitle: Text(product.category),
      trailing: badge,
      onTap: onTap,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
