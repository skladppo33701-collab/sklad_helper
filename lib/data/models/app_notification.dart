import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationSeverity { info, warning, critical }

AppNotificationSeverity appNotificationSeverityFromString(String? v) {
  switch (v) {
    case 'warning':
      return AppNotificationSeverity.warning;
    case 'critical':
      return AppNotificationSeverity.critical;
    case 'info':
    default:
      return AppNotificationSeverity.info;
  }
}

String appNotificationSeverityToString(AppNotificationSeverity s) => s.name;

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.severity,
    required this.audience,
    this.createdBy,
    this.transferId,
    this.expiresAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? createdBy;
  final String? transferId;
  final AppNotificationSeverity severity;
  final List<String> audience;
  final DateTime? expiresAt;

  Map<String, dynamic> toMap() => {
    'type': type,
    'title': title,
    'body': body,
    'createdAt': Timestamp.fromDate(createdAt),
    'createdBy': createdBy,
    'transferId': transferId,
    'severity': appNotificationSeverityToString(severity),
    'audience': audience,
    'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
  };

  static AppNotification fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    DateTime dt(dynamic v) =>
        (v is Timestamp) ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

    return AppNotification(
      id: doc.id,
      type: (d['type'] as String?) ?? 'system',
      title: (d['title'] as String?) ?? '',
      body: (d['body'] as String?) ?? '',
      createdAt: dt(d['createdAt']),
      createdBy: d['createdBy'] as String?,
      transferId: d['transferId'] as String?,
      severity: appNotificationSeverityFromString(d['severity'] as String?),
      audience:
          (d['audience'] as List?)?.whereType<String>().toList() ??
          const <String>['staff'],
      expiresAt: d['expiresAt'] is Timestamp
          ? (d['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }
}
