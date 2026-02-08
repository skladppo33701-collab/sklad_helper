import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catalogImportProvider = Provider((ref) => CatalogImportController(ref));

class CatalogImportController {
  CatalogImportController(this.ref);
  final Ref ref;

  Future<int> pickAndUploadCatalog() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return 0;

    // Проверка расширения
    final name = result.files.first.name.toLowerCase();
    if (!name.endsWith('.xlsx')) {
      throw Exception(
        'Ошибка: Файл должен быть в формате .xlsx (Excel 2007+). Пожалуйста, пересохраните файл из 1С или Excel.',
      );
    }

    final bytes = result.files.first.bytes;
    if (bytes == null) throw Exception('Не удалось прочитать файл');

    return await _parseAndSaveCatalog(bytes);
  }

  Future<int> _parseAndSaveCatalog(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) throw Exception('Файл Excel пуст');

    final table = excel.tables.values.first;

    // Индексы колонок (подстраиваем под ваш файл Остатки 33701.xls)
    // В вашем CSV видно:
    // Col 0: Пусто
    // Col 1 (B): Номенклатура (или Бренд)
    // Col 2 (C): Артикул (Код)
    int colName = -1;
    int colArticle = -1;

    // 1. Поиск заголовков (ищем строку, где есть "Номенклатура" и "Артикул")
    int headerRowIndex = -1;
    for (var i = 0; i < table.maxRows && i < 50; i++) {
      final row = table.rows[i];
      for (var j = 0; j < row.length; j++) {
        final val = row[j]?.value?.toString().toLowerCase().trim() ?? '';

        if (val.contains('артикул') || val.contains('код')) colArticle = j;
        // Иногда колонка называется "Номенклатура", иногда "Товар"
        if (val.contains('номенклатура') || val.contains('наименование')) {
          colName = j;
        }
      }

      if (colArticle != -1 && colName != -1) {
        headerRowIndex = i;
        break;
      }
    }

    if (headerRowIndex == -1) {
      // Фолбэк: если заголовки не найдены, пробуем стандартные колонки 1С (B=Name, C=Article)
      // В библиотеке excel индексы с 0, значит B=1, C=2.
      colName = 1;
      colArticle = 2;
      headerRowIndex = 8; // Пропускаем шапку наугад
    }

    final db = FirebaseFirestore.instance;
    var batch = db.batch();
    int count = 0;
    int batchCount = 0;

    // Состояние парсера
    String currentCategory = 'Общее';

    // 2. Итерация строк
    for (var i = headerRowIndex + 1; i < table.maxRows; i++) {
      final row = table.rows[i];

      String getVal(int idx) {
        if (idx < 0 || idx >= row.length) return '';
        return row[idx]?.value?.toString().trim() ?? '';
      }

      final rawName = getVal(colName);
      final rawArticle = getVal(colArticle);

      // --- ЛОГИКА ФИЛЬТРАЦИИ МУСОРА ---

      // 1. Если нет имени - пропускаем
      if (rawName.isEmpty) continue;

      // 2. Фильтр системных строк 1С
      if (rawName.startsWith('Склад') ||
          rawName.startsWith('Итого') ||
          rawName.contains('Ведомость') ||
          rawName.contains('33701_')) {
        continue;
      }

      // 3. ОПРЕДЕЛЕНИЕ: ЭТО БРЕНД ИЛИ ТОВАР?

      // В 1С у Групп (Брендов) обычно нет Артикула в этой колонке.
      // А у Товаров Артикул есть и он обычно цифровой.

      // Проверяем, является ли артикул числом (или похож на него, напр. 000123)
      final isArticleNumeric = RegExp(r'^\d+$').hasMatch(rawArticle);

      if (!isArticleNumeric) {
        // Если артикула нет (или это текст), значит эта строка - ЗАГОЛОВОК ГРУППЫ (Бренд)
        // Но только если это не мусор типа "Кон. остаток"
        if (rawName.length > 2 && !rawName.contains('остаток')) {
          currentCategory = rawName; // Запоминаем текущий бренд
        }
        continue; // Не сохраняем саму строку бренда как товар
      }

      // Если мы здесь, значит есть и Имя, и Цифровой Артикул -> ЭТО ТОВАР

      // Очистка названия от лишних пробелов
      final name = rawName.replaceAll(RegExp(r'\s+'), ' ');
      final article = rawArticle;

      final docRef = db.collection('products').doc(article);

      batch.set(docRef, {
        'article': article,
        'name': name,
        'category': currentCategory, // Используем запомненный бренд
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      count++;
      batchCount++;

      if (batchCount >= 450) {
        await batch.commit();
        batch = db.batch(); // Новый батч
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    return count;
  }
}
