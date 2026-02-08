import 'dart:convert';
import 'package:flutter/foundation.dart'; // Для debugPrint
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class PushSenderService {
  // ID вашего проекта из service_account.json
  static const _projectId = 'skladhelper';

  // Получаем доступ к API Google с помощью вашего файла ключа
  Future<String> _getAccessToken() async {
    final jsonString = await rootBundle.loadString(
      'assets/service_account.json',
    );
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(accountCredentials, scopes);

    return client.credentials.accessToken.data;
  }

  // Метод отправки сообщения
  Future<void> sendNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final token = await _getAccessToken();

      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': {
            'topic': topic,
            'notification': {'title': title, 'body': body},
            'data': data ?? {},
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Пуш успешно отправлен на тему $topic');
      } else {
        debugPrint('❌ Ошибка отправки пуша: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Ошибка push_sender: $e');
    }
  }
}
