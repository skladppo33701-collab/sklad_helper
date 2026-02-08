// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cross_file/cross_file.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

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
    final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);
    if (decoder.tables.isEmpty) throw Exception('Файл Excel пуст');

    SpreadsheetTable? table;
    int headerRowIndex = -1;
    int colArticle = -1;
    int colName = -1;
    int colQty = -1;

    // Поиск заголовков
    for (var tableName in decoder.tables.keys) {
      final t = decoder.tables[tableName]!;
      for (var i = 0; i < t.maxRows && i < 100; i++) {
        final row = t.rows[i];
        int tempArticle = -1;
        int tempName = -1;
        int tempQty = -1;

        for (var j = 0; j < row.length; j++) {
          final val = row[j]?.toString().toLowerCase().trim() ?? '';
          if (val.contains('артикул')) tempArticle = j;
          if (val.contains('товар') || val.contains('наименование'))
            tempName = j;
          if (val == 'количество' ||
              (val.contains('количество') && !val.contains('мест')))
            tempQty = j;
        }

        if (tempArticle != -1 && tempQty != -1) {
          headerRowIndex = i;
          colArticle = tempArticle;
          colName = tempName;
          colQty = tempQty;
          table = t;
          break;
        }
      }
      if (table != null) break;
    }

    if (table == null || headerRowIndex == -1) {
      throw Exception('Не найдены колонки "Артикул" и "Количество"');
    }

    final lines = <Map<String, dynamic>>[];
    int totalQty = 0;

    for (var i = headerRowIndex + 1; i < table.maxRows; i++) {
      final row = table.rows[i];
      if (row.length <= colQty) continue;

      final rawArticle = row[colArticle];
      if (rawArticle == null || rawArticle.toString().trim().isEmpty) continue;

      final article = rawArticle.toString().trim();
      String name = 'Без названия';
      if (colName != -1 && row.length > colName) {
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
          // ВАЖНО: Добавляем category, чтобы работал orderBy('category') в Firestore!
          'category': '',
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
      'from': 'Excel Import',
      'isDeleted': false,
    });

    for (var line in lines) {
      final lineRef = transferRef.collection('lines').doc();
      batch.set(lineRef, {...line, 'lineId': lineRef.id});
    }

    await batch.commit();
  }
}
