import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// Импорт локализации
import '../../l10n/app_localizations.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    // Получаем l10n
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanTitle), // ИСПРАВЛЕНО
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: MobileScanner(
        fit: BoxFit.cover,
        onDetect: (capture) {
          if (_handled) return;

          final raw = capture.barcodes.isNotEmpty
              ? capture.barcodes.first.rawValue?.trim()
              : null;

          if (raw == null || raw.isEmpty) return;

          _handled = true;

          if (!mounted) return;
          Navigator.of(context).pop(raw);
        },
      ),
    );
  }
}
