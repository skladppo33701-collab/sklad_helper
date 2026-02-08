// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/foundation.dart'; // для debugPrint
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cross_file/cross_file.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

// Импорт сервиса пушей
import '../../features/notifications/push_sender_service.dart';

final transferImportProvider = Provider((ref) => TransferImportController(ref));

class TransferImportController {
  TransferImportController(this.ref);
  final Ref ref;

  Future<void> pickAndUploadExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) throw Exception('Не удалось прочитать файл');

    await _parseAndSave(bytes, result.files.first.name);
  }

  Future<void> uploadDroppedFiles(List<XFile> files) async {
    for (var file in files) {
      if (!file.name.toLowerCase().endsWith('.xlsx')) continue;
      final bytes = await file.readAsBytes();
      await _parseAndSave(bytes, file.name);
    }
  }

  Future<void> _parseAndSave(Uint8List bytes, String filename) async {
    final decoder = SpreadsheetDecoder.decodeBytes(bytes);
    final table = decoder.tables.values.first;

    if (table.rows.isEmpty) throw Exception('Файл пуст');

    // Поиск заголовков
    int colArticle = -1;
    int colName = -1;
    int colQty = -1;
    int headerRowIndex = -1;

    for (var i = 0; i < table.maxRows && i < 20; i++) {
      final row = table.rows[i];
      for (var j = 0; j < row.length; j++) {
        final val = row[j]?.toString().toLowerCase().trim() ?? '';
        if (val.contains('артикул') || val.contains('код')) colArticle = j;
        if (val.contains('номенклатура') ||
            val.contains('товар') ||
            val.contains('наименование'))
          colName = j;
        if (val == 'количество' ||
            val == 'кол-во' ||
            val == 'к-во' ||
            val == 'остаток')
          colQty = j;
      }
      if (colArticle != -1 && colName != -1 && colQty != -1) {
        headerRowIndex = i;
        break;
      }
    }

    if (headerRowIndex == -1) {
      // Фолбэк, если заголовки не найдены (стандарт 1С)
      colArticle = 0; // A
      colName = 1; // B
      colQty = 3; // D
      headerRowIndex = 0;
    }

    final List<Map<String, dynamic>> lines = [];
    int totalQty = 0;

    for (var i = headerRowIndex + 1; i < table.maxRows; i++) {
      final row = table.rows[i];
      if (row.length <= colArticle || row.length <= colQty) continue;

      final article = row[colArticle]?.toString().trim() ?? '';
      if (article.isEmpty) continue;

      String name = 'Без названия';
      if (row.length > colName) {
        name = row[colName]?.toString().trim() ?? 'Без названия';
      }

      final qtyRaw = row[colQty];
      int qty = 0;

      if (qtyRaw is int)
        qty = qtyRaw;
      else if (qtyRaw is double)
        qty = qtyRaw.toInt();
      else if (qtyRaw is String) {
        final clean = qtyRaw.replaceAll(RegExp(r'[^0-9]'), '');
        qty = int.tryParse(clean) ?? 0;
      }

      if (qty > 0) {
        lines.add({
          'article': article,
          'name': name,
          'category': '', // Для сортировки
          'qtyPlanned': qty,
          'qtyPicked': 0,
          'qtyChecked': 0,
        });
        totalQty += qty;
      }
    }

    if (lines.isEmpty) throw Exception('Товары не найдены');

    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    final transferRef = db.collection('transfers').doc();

    batch.set(transferRef, {
      'transferId': transferRef.id,
      'title': filename.replaceAll('.xlsx', ''),
      'status': 'new',
      'itemsTotal': lines.length,
      'pcsTotal': totalQty,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (var line in lines) {
      final lineRef = transferRef.collection('lines').doc();
      batch.set(lineRef, {
        ...line,
        'id': lineRef.id,
        'transferId': transferRef.id,
      });
    }

    // Сохраняем в базу
    await batch.commit();

    // --- ОТПРАВКА ПУШ-УВЕДОМЛЕНИЯ ---
    try {
      await PushSenderService().sendNotification(
        topic: 'staff',
        title: '📦 Новое задание',
        body: 'Загружено перемещение: ${filename.replaceAll('.xlsx', '')}',
      );
    } catch (e) {
      debugPrint('Ошибка отправки пуша (Импорт): $e');
    }
    // --------------------------------
  }
}
