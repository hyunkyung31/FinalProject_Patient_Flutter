import '../../../core/network/api_client.dart';
import '../model/patient_notification.dart';

class NotificationRepository {
  NotificationRepository(this.client);
  final ApiClient client;
  static const path = '/api/patient/notifications/';

  Future<NotificationPage> list({int page = 1, bool unreadOnly = false}) async {
    final response = await client.dio.get<Map<String, dynamic>>(
      path,
      queryParameters: {'page': page, if (unreadOnly) 'read': false},
    );
    final data = response.data;
    if (data == null ||
        data['results'] is! List ||
        data['has_next'] is! bool ||
        data['page'] is! int) {
      throw const FormatException('알림 목록 응답이 올바르지 않아요.');
    }
    return NotificationPage(
      (data['results'] as List)
          .map(
            (row) => PatientNotification.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(),
      data['has_next'] as bool,
      data['page'] as int,
    );
  }

  Future<PatientNotification> markRead(int recipientId) async {
    final response = await client.dio.post<Map<String, dynamic>>(
      '$path$recipientId/read/',
      data: <String, dynamic>{},
    );
    if (response.data == null) throw const FormatException('읽음 처리 결과가 비어 있어요.');
    final result = PatientNotification.fromJson(response.data!);
    if (result.recipientId != recipientId || !result.isRead) {
      throw const FormatException('읽음 처리 결과를 확인하지 못했어요.');
    }
    return result;
  }

  Future<void> readAll() async {
    final response = await client.dio.post<Map<String, dynamic>>(
      '${path}read-all/',
      data: <String, dynamic>{},
    );
    if (response.data?['updated_count'] is! int) {
      throw const FormatException('전체 읽음 결과를 확인하지 못했어요.');
    }
  }

  Future<int> unreadCount() async {
    final response = await client.dio.get<Map<String, dynamic>>(
      '${path}unread-count/',
    );
    final count = response.data?['unread_count'];
    if (count is! int || count < 0) {
      throw const FormatException('미읽음 개수를 확인하지 못했어요.');
    }
    return count;
  }
}
