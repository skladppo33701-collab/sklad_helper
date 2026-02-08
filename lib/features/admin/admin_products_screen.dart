import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_dimens.dart';
import '../../data/models/product.dart';
import '../catalog/barcode_scanner_screen.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _search = TextEditingController();
  String _query = '';

  String? _filterCategory;
  String? _filterBrand;

  final List<String> _categories = [
    'Холодильники',
    'Морозильники',
    'Стиральные машины',
    'Сушильные машины',
    'Посудомоечные машины',
    'Газовые плиты',
    'Электрические плиты',
    'Духовые шкафы',
    'Варочные панели',
    'Микроволновые печи',
    'Вытяжки',
    'Кондиционеры',
    'Вентиляторы',
    'Обогреватели',
    'Водонагреватели',
    'Телевизоры',
    'Саундбары',
    'Пылесосы',
    'Роботы-пылесосы',
    'Утюги',
    'Парогенераторы',
    'Чайники',
    'Кофемашины',
    'Блендеры',
    'Миксеры',
    'Мясорубки',
    'Мультиварки',
    'Фены',
    'Стайлеры',
    'Электробритвы',
    'Встраиваемая техника',
    'Ноутбуки',
    'Мониторы',
    'Смартфоны',
    'Планшеты',
    'Смарт-часы',
    'Аксессуары',
    'Другое',
  ];

  final List<String> _defaultBrands = [
    'Samsung',
    'LG',
    'Bosch',
    'Indesit',
    'Beko',
    'Haier',
    'Midea',
    'Electrolux',
    'Gorenje',
    'Hansa',
    'Artel',
    'Arg',
    'Dauscher',
    'Philips',
    'Tefal',
    'Braun',
    'Sony',
    'Xiaomi',
    'Apple',
    'HP',
    'Lenovo',
    'Asus',
    'Acer',
    'Canon',
    'Epson',
    'Другой',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _deleteAllProducts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ОПАСНО: Удалить ВСЮ базу?'),
        content: const Text(
          'Вы собираетесь удалить ВСЕ товары. Это действие необратимо.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('УДАЛИТЬ ВСЁ'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Начало удаления...')));

    try {
      final collection = FirebaseFirestore.instance.collection('products');
      var snapshots = await collection.limit(500).get();

      while (snapshots.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshots.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        snapshots = await collection.limit(500).get();
      }
      messenger.showSnackBar(const SnackBar(content: Text('База очищена.')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot<Map<String, dynamic>>> stream = FirebaseFirestore
        .instance
        .collection('products')
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .withConverter(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (Map<String, dynamic> value, _) => value,
        )
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Товары'),
        actions: [
          IconButton(
            onPressed: _deleteAllProducts,
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Очистить базу',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimens.x16),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    labelText: 'Поиск по названию / артикулу',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_filterCategory != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text('Категория: $_filterCategory'),
                            onDeleted: () =>
                                setState(() => _filterCategory = null),
                          ),
                        ),
                      if (_filterBrand != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text('Бренд: $_filterBrand'),
                            onDeleted: () =>
                                setState(() => _filterBrand = null),
                          ),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.filter_list, size: 16),
                        label: const Text('Фильтры'),
                        onPressed: _showFilterDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                final filtered = docs.where((d) {
                  final data = d.data();
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final art = (data['article'] ?? '').toString().toLowerCase();
                  final bc = (data['barcode'] ?? '').toString().toLowerCase();
                  final cat = (data['category'] ?? '').toString();
                  final brand = (data['brand'] ?? '').toString();

                  bool matchQuery = true;
                  if (_query.isNotEmpty) {
                    matchQuery =
                        name.contains(_query) ||
                        art.contains(_query) ||
                        bc.contains(_query);
                  }

                  bool matchCat = true;
                  if (_filterCategory != null) {
                    matchCat = cat == _filterCategory;
                  }

                  bool matchBrand = true;
                  if (_filterBrand != null) {
                    matchBrand = brand == _filterBrand;
                  }

                  return matchQuery && matchCat && matchBrand;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Товары не найдены'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  // Исправлено: _ вместо __
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    final p = Product.fromDoc(doc);
                    final brand = (doc.data()['brand'] as String?) ?? '—';

                    return ListTile(
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '$brand • ${p.category}\nАрт: ${p.article}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showProductDialog(
                          context,
                          docRef: doc.reference,
                          product: p,
                          docData: doc.data(),
                        ),
                      ),
                      onLongPress: () => _deleteProduct(context, doc.reference),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showProductDialog(context),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ИСПРАВЛЕНО: InputDecorator вместо DropdownButtonFormField для избежания deprecation
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Категория',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterCategory,
                  hint: const Text('Все'),
                  isExpanded: true,
                  isDense: true,
                  items: _categories
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _filterCategory = val);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Бренд',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterBrand,
                  hint: const Text('Все'),
                  isExpanded: true,
                  isDense: true,
                  items: _defaultBrands
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _filterBrand = val);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProductDialog(
    BuildContext context, {
    DocumentReference? docRef,
    Product? product,
    Map<String, dynamic>? docData,
  }) async {
    final isEditing = product != null;
    final oldArticle = product?.article;

    final artCtrl = TextEditingController(text: product?.article ?? '');
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final newBrandCtrl = TextEditingController();

    String selectedCategory = product?.category ?? _categories.first;
    if (!_categories.contains(selectedCategory)) {
      selectedCategory = _categories.first;
    }

    String currentBrand =
        (docData?['brand'] as String?) ?? _defaultBrands.first;
    String selectedBrand = currentBrand;
    bool isCustomBrand = !_defaultBrands.contains(currentBrand);

    // Исправлено: фигурные скобки
    if (isCustomBrand) {
      selectedBrand = 'Другой';
      newBrandCtrl.text = currentBrand;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> scanBarcode() async {
            final scanned = await Navigator.of(context).push<String>(
              MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
            );
            // Исправлено: фигурные скобки
            if (scanned != null) {
              setStateDialog(() => barcodeCtrl.text = scanned);
            }
          }

          return AlertDialog(
            title: Text(isEditing ? 'Редактировать' : 'Новый товар'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: artCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Артикул (ID) *',
                      hintText: 'Уникальный код',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nameCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Наименование *',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ИСПРАВЛЕНО: InputDecorator вместо DropdownButtonFormField
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Категория *',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        isDense: true,
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          // Исправлено: фигурные скобки
                          if (val != null) {
                            setStateDialog(() => selectedCategory = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ИСПРАВЛЕНО: InputDecorator вместо DropdownButtonFormField
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Бренд *',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBrand,
                        isExpanded: true,
                        isDense: true,
                        items: [
                          ..._defaultBrands.map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              selectedBrand = val;
                              isCustomBrand = (val == 'Другой');
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  if (isCustomBrand)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: newBrandCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Введите название бренда',
                          prefixIcon: Icon(Icons.edit),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: barcodeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Штрихкод',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner),
                        tooltip: 'Сканировать',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () async {
                  final newArt = artCtrl.text.trim();
                  final name = nameCtrl.text.trim();

                  if (newArt.isEmpty || name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Артикул и Название обязательны'),
                      ),
                    );
                    return;
                  }

                  final finalBrand = isCustomBrand
                      ? newBrandCtrl.text.trim()
                      : selectedBrand;
                  if (finalBrand.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Укажите бренд')),
                    );
                    return;
                  }

                  final data = {
                    'article': newArt,
                    'name': name,
                    'category': selectedCategory,
                    'brand': finalBrand,
                    'barcode': barcodeCtrl.text.trim().isEmpty
                        ? null
                        : barcodeCtrl.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  final db = FirebaseFirestore.instance;

                  if (isEditing && oldArticle != null && oldArticle != newArt) {
                    final batch = db.batch();

                    batch.set(db.collection('products').doc(newArt), {
                      ...data,
                      'createdAt':
                          docData?['createdAt'] ?? FieldValue.serverTimestamp(),
                    });

                    if (docRef != null) batch.delete(docRef);

                    await batch.commit();
                  } else if (isEditing && docRef != null) {
                    await docRef.update(data);
                  } else {
                    data['createdAt'] = FieldValue.serverTimestamp();
                    await db.collection('products').doc(newArt).set(data);
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteProduct(
    BuildContext context,
    DocumentReference ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить товар?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.delete();
    }
  }
}
