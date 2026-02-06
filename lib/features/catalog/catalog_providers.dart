import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router/providers.dart';
import '../../data/models/product.dart';
import '../../data/repos/product_repository.dart';
import '../../data/repos/barcode_repository.dart';
import '../../data/models/user_profile.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(firestoreProvider));
});

final barcodeRepositoryProvider = Provider<BarcodeRepository>((ref) {
  return BarcodeRepository(ref.watch(firestoreProvider));
});

final currentRoleProvider = Provider<UserRole>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.asData?.value?.role ?? UserRole.guest;
});

final canBindBarcodeProvider = Provider<bool>((ref) {
  final role = ref.watch(currentRoleProvider);
  return role == UserRole.admin || role == UserRole.storekeeper;
});

final catalogControllerProvider =
    AsyncNotifierProvider<CatalogController, List<Product>>(
      CatalogController.new,
    );

class CatalogController extends AsyncNotifier<List<Product>> {
  String? _lastArticle;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<Product>> build() async {
    _lastArticle = null;
    _hasMore = true;
    final items = await ref
        .read(productRepositoryProvider)
        .fetchCatalogPage(startAfterArticle: null, limit: 50);
    if (items.length < 50) _hasMore = false;
    _lastArticle = items.isNotEmpty ? items.last.article : null;
    return items;
  }

  Future<void> refreshFirstPage() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.value ?? const <Product>[];
    final next = await ref
        .read(productRepositoryProvider)
        .fetchCatalogPage(startAfterArticle: _lastArticle, limit: 50);
    if (next.isEmpty || next.length < 50) _hasMore = false;
    _lastArticle = next.isNotEmpty ? next.last.article : _lastArticle;
    state = AsyncValue.data([...current, ...next]);
  }

  /// Exact search by doc id (article). No full-catalog scan.
  Future<Product?> findByArticle(String article) async {
    final a = article.trim();
    if (a.isEmpty) return null;
    return ref.read(productRepositoryProvider).getByArticle(a);
  }
}

final productByArticleProvider = StreamProvider.family<Product?, String>((
  ref,
  article,
) {
  return ref.watch(productRepositoryProvider).watchByArticle(article);
});
