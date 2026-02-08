// Перенесите сюда все исключения из transfer_lines_repository.dart и barcode_repository.dart

class NotSignedInException implements Exception {}

class ScanCancelledException implements Exception {}

class UnknownBarcodeException implements Exception {}

class WrongItemException implements Exception {
  final String expectedArticle;
  final String actualArticle;
  WrongItemException({
    required this.expectedArticle,
    required this.actualArticle,
  });
}

// --- Новые исключения для трансферов ---
class LineNotFoundException implements Exception {
  @override
  String toString() => 'Line not found';
}

class LockTakenException implements Exception {
  LockTakenException({required this.lockUserId});
  final String lockUserId;
  @override
  String toString() => 'Locked by other';
}

class AlreadyHoldingLockException implements Exception {
  AlreadyHoldingLockException({required this.lineId});
  final String lineId;
  @override
  String toString() => 'Already holding lock';
}

class LockExpiredException implements Exception {
  @override
  String toString() => 'Lock expired';
}

class NotLockOwnerException implements Exception {
  @override
  String toString() => 'Not lock owner';
}

class OverPickException implements Exception {
  @override
  String toString() => 'Over-pick prevented';
}

class OverCheckException implements Exception {
  @override
  String toString() => 'Over-check prevented';
}

// --- Исключения сканера ---
class BarcodeConflictException implements Exception {
  BarcodeConflictException(this.article);
  final String article;
}

class ProductAlreadyBoundException implements Exception {
  ProductAlreadyBoundException(this.barcode);
  final String barcode;
}

class ProductNotFoundException implements Exception {
  ProductNotFoundException(this.article);
  final String article;
}
