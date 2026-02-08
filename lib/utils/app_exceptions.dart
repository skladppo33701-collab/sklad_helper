class CheckingNotAllowedException implements Exception {
  @override
  String toString() => 'Not allowed';
}

class NotFullyPickedException implements Exception {
  @override
  String toString() => 'Not fully picked';
}

class UnknownBarcodeException implements Exception {
  @override
  String toString() => 'Unknown barcode';
}

class ScanCancelledException implements Exception {
  @override
  String toString() => 'Scan cancelled';
}

class NotSignedInException implements Exception {
  @override
  String toString() => 'Not signed in';
}

class WrongItemException implements Exception {
  WrongItemException({
    required this.expectedArticle,
    required this.actualArticle,
  });
  final String expectedArticle;
  final String actualArticle;

  @override
  String toString() => 'Wrong item';
}
