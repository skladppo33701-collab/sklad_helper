import '../l10n/app_localizations.dart';

class BarcodeValidationResult {
  final bool ok;
  final String? error;
  const BarcodeValidationResult.ok() : ok = true, error = null;
  const BarcodeValidationResult.fail(this.error) : ok = false;
}

class BarcodeValidator {
  static BarcodeValidationResult validate(String raw, AppLocalizations l10n) {
    final code = raw.trim();

    if (code.isEmpty) {
      return BarcodeValidationResult.fail(l10n.valEmpty);
    }

    if (!_isNumeric(code)) {
      return BarcodeValidationResult.fail(l10n.valNumericOnly);
    }

    if (code.length == 13) {
      if (!_isValidEan13(code)) {
        return BarcodeValidationResult.fail(l10n.valChecksum);
      }
      return const BarcodeValidationResult.ok();
    }

    if (code.length == 8) {
      return const BarcodeValidationResult.ok();
    }

    return BarcodeValidationResult.fail(l10n.valLength);
  }

  static bool _isNumeric(String s) => RegExp(r'^\d+$').hasMatch(s);

  static bool _isValidEan13(String ean) {
    if (ean.length != 13 || !_isNumeric(ean)) return false;
    final digits = ean.split('').map(int.parse).toList(growable: false);
    final checkDigit = digits[12];
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final d = digits[i];
      sum += (i % 2 == 1) ? d * 3 : d;
    }
    final mod = sum % 10;
    final computed = (mod == 0) ? 0 : (10 - mod);
    return computed == checkDigit;
  }
}
