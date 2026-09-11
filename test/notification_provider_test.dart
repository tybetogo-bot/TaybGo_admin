import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/models/app_notification.dart';
import 'package:taybgoadmin/core/providers/notification_provider.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  test('loads newest first and calculates the local unread count', () async {
    final provider = NotificationProvider(
      apiService: ApiService(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'title': 'Older',
                'body': '',
                'data': {},
                'is_read': false,
                'created_at': '2026-09-10T10:00:00Z',
              },
              {
                'id': '2',
                'title': 'Newest',
                'body': '',
                'data': {},
                'is_read': true,
                'created_at': '2026-09-11T10:00:00Z',
              },
            ]),
            200,
          );
        }),
      ),
    );

    await provider.loadNotifications();

    expect(provider.notifications.map((item) => item.id), [2, 1]);
    expect(provider.unreadCount, 1);
    provider.dispose();
  });

  test(
    'read, unread, and delete actions update the local list and backend',
    () async {
      final requests = <http.Request>[];
      final provider = NotificationProvider(
        apiService: ApiService(
          client: MockClient((request) async {
            requests.add(request);
            if (request.method == 'GET') {
              return http.Response(
                jsonEncode([
                  {
                    'id': 5,
                    'title': 'Unread',
                    'body': '',
                    'data': {},
                    'is_read': false,
                    'created_at': '2026-09-11T10:00:00Z',
                  },
                ]),
                200,
              );
            }
            return http.Response('', 204);
          }),
        ),
      );

      await provider.loadNotifications();
      expect(await provider.markRead(5), isTrue);
      expect(provider.unreadCount, 0);
      expect(await provider.markUnread(5), isTrue);
      expect(provider.unreadCount, 1);
      expect(await provider.deleteNotification(5), isTrue);
      expect(provider.notifications, isEmpty);
      expect(requests.map((request) => request.method), [
        'GET',
        'PATCH',
        'PATCH',
        'DELETE',
      ]);
      provider.dispose();
    },
  );

  test('defers an opened push while logged out', () async {
    final provider = NotificationProvider(
      apiService: ApiService(
        client: MockClient((_) async => http.Response('[]', 200)),
      ),
    );
    provider.isAuthenticated = () => false;

    await provider.handleOpenedPush(
      RemoteMessage(
        data: {'type': 'support_message_from_requester', 'ticket_id': '27'},
      ),
    );

    expect(provider.takePendingNavigation()?.path, '/support/27');
    provider.dispose();
  });

  test('marks a matching opened notification read before navigating', () async {
    final methods = <String>[];
    AppNotificationDestination? destination;
    final provider = NotificationProvider(
      apiService: ApiService(
        client: MockClient((request) async {
          methods.add(request.method);
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([
                {
                  'id': 8,
                  'title': 'Requester reply',
                  'body': 'Hello',
                  'data': {
                    'type': 'support_message_from_requester',
                    'ticket_id': '27',
                    'message_id': '91',
                  },
                  'is_read': false,
                  'created_at': '2026-09-11T10:00:00Z',
                },
              ]),
              200,
            );
          }
          return http.Response('', 204);
        }),
      ),
    );
    provider.isAuthenticated = () => true;
    provider.onNavigationRequested = (value) => destination = value;

    await provider.handleOpenedPush(
      RemoteMessage(
        data: {
          'notification_id': '8',
          'type': 'support_message_from_requester',
          'ticket_id': '27',
          'message_id': '91',
        },
      ),
    );

    expect(methods, ['GET', 'PATCH']);
    expect(provider.unreadCount, 0);
    expect(destination?.path, '/support/27');
    provider.dispose();
  });
}
