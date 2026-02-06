class BarcodeValidationResult {
  final bool ok;
  final String? error;
  const BarcodeValidationResult.ok() : ok = true, error = null;
  const BarcodeValidationResult.fail(this.error) : ok = false;
}

class BarcodeValidator {
  /// Allow ONLY:
  /// - EAN-13 numeric (with checksum)
  /// - EAN-8 numeric (length + numeric only)
  static BarcodeValidationResult validate(String raw) {
    final code = raw.trim();

    if (code.isEmpty) {
      return const BarcodeValidationResult.fail(
        'Пустой штрихкод',
      ); // TODO(l10n)
    }

    if (!_isNumeric(code)) {
      return const BarcodeValidationResult.fail(
        'Разрешены только цифры (EAN-8 / EAN-13)', // TODO(l10n)
      );
    }

    if (code.length == 13) {
      if (!_isValidEan13(code)) {
        return const BarcodeValidationResult.fail(
          'Неверная контрольная сумма EAN-13', // TODO(l10n)
        );
      }
      return const BarcodeValidationResult.ok();
    }

    if (code.length == 8) {
      // Requirement: numeric + length check (no EAN-8 checksum requested).
      return const BarcodeValidationResult.ok();
    }

    return const BarcodeValidationResult.fail(
      'Разрешены только EAN-8 (8 цифр) или EAN-13 (13 цифр)', // TODO(l10n)
    );
  }

  static bool _isNumeric(String s) => RegExp(r'^\d+$').hasMatch(s);

  /// EAN-13 checksum:
  /// sum(odd positions) + 3*sum(even positions), check digit makes total % 10 == 0
  static bool _isValidEan13(String ean) {
    if (ean.length != 13 || !_isNumeric(ean)) return false;

    final digits = ean.split('').map(int.parse).toList(growable: false);
    final checkDigit = digits[12];

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final d = digits[i];
      final isEvenPosition = (i % 2 == 1); // 0-based: index1 is position2
      sum += isEvenPosition ? d * 3 : d;
    }

    final mod = sum % 10;
    final computed = (mod == 0) ? 0 : (10 - mod);
    return computed == checkDigit;
  }
}
