class TransferLine {
  final String id;
  final String transferId;
  final String article;
  final String name;
  final int qtyPlanned;
  final int qtyPicked;
  final int qtyChecked;
  // Поле может называться pickedByUid или просто pickedUid
  final String? pickedUid;

  const TransferLine({
    required this.id,
    required this.transferId,
    required this.article,
    required this.name,
    required this.qtyPlanned,
    required this.qtyPicked,
    required this.qtyChecked,
    this.pickedUid,
  });

  factory TransferLine.fromMap(String id, Map<String, dynamic> map) {
    return TransferLine(
      id: id,
      transferId: map['transferId'] ?? '',
      article: map['article'] ?? '',
      name: map['name'] ?? '',
      qtyPlanned: (map['qtyPlanned'] as num?)?.toInt() ?? 0,
      qtyPicked: (map['qtyPicked'] as num?)?.toInt() ?? 0,
      qtyChecked: (map['qtyChecked'] as num?)?.toInt() ?? 0,
      pickedUid:
          map['pickedUid'], // Убедитесь, что в базе это поле так и называется
    );
  }
}
