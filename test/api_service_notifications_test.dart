import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  test(
    'registerDeviceToken posts the FCM token for the authenticated admin',
    () async {
      late http.Request captured;
      final api = ApiService(
        client: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode({'id': 7, 'is_active': true}), 200);
        }),
      )..setAuthToken('admin-token');

      await api.registerDeviceToken(token: 'fcm-token', deviceType: 'web');

      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/notifications/device');
      expect(captured.headers['authorization'], 'Bearer admin-token');
      expect(jsonDecode(captured.body), {
        'token': 'fcm-token',
        'device_type': 'web',
      });
    },
  );

  test('getNotifications decodes the backend plain array response', () async {
    late http.Request captured;
    final api = ApiService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode([
            {
              'id': '17',
              'title': 'Ticket updated',
              'body': 'A requester replied',
              'data': {
                'type': 'support_message_from_requester',
                'ticket_id': '9',
              },
              'is_read': false,
              'read_at': null,
              'created_at': '2026-09-11T10:00:00Z',
            },
          ]),
          200,
        );
      }),
    )..setAuthToken('admin-token');

    final notifications = await api.getNotifications();

    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/notifications');
    expect(captured.headers['authorization'], 'Bearer admin-token');
    expect(notifications.single.id, 17);
    expect(notifications.single.ticketId, 9);
    expect(notifications.single.isRead, isFalse);
  });

  test(
    'notification read and delete mutations use the exact contract paths',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('', 204);
        }),
      )..setAuthToken('admin-token');

      await api.updateNotificationRead(17, isRead: true);
      await api.deleteNotification(17);

      expect(requests.map((request) => request.method), ['PATCH', 'DELETE']);
      expect(requests.map((request) => request.url.path), [
        '/api/notifications/17',
        '/api/notifications/17',
      ]);
      expect(jsonDecode(requests.first.body), {'is_read': true});
      expect(
        requests.every(
          (request) => request.headers['authorization'] == 'Bearer admin-token',
        ),
        isTrue,
      );
    },
  );
}
