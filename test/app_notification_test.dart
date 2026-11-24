import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taybgoadmin/core/models/app_notification.dart';

void main() {
  test('parses numeric and string notification identifiers', () {
    final numeric = AppNotification.fromJson({
      'id': 12,
      'title': 'Numeric',
      'body': '',
      'is_read': false,
      'created_at': '2026-09-11T10:00:00Z',
    });
    final string = AppNotification.fromJson({
      'id': '13',
      'title': 'String',
      'body': '',
      'is_read': 'true',
      'created_at': '2026-09-11T10:00:00Z',
    });

    expect(numeric.id, 12);
    expect(string.id, 13);
    expect(string.isRead, isTrue);
  });

  test('maps only approved support types with positive ticket ids', () {
    expect(
      AppNotificationDestination.fromData({
        'type': 'support_ticket_created',
        'ticket_id': '42',
      }).path,
      '/support/42',
    );
    expect(
      AppNotificationDestination.fromData({
        'type': 'support_message_from_requester',
        'ticket_id': 0,
      }).path,
      '/notifications',
    );
    expect(
      AppNotificationDestination.fromData({
        'type': 'unknown_type',
        'ticket_id': '42',
      }).path,
      '/notifications',
    );
  });

  test(
    'uses notification data when FCM puts title and body in the payload',
    () {
      final notification = AppNotification.fromRemoteMessage(
        RemoteMessage(
          data: {
            'id': '8',
            'title': 'Test notification',
            'body': 'Check the admin inbox',
            'type': 'admin_test_notification',
          },
        ),
      );

      expect(notification.id, 8);
      expect(notification.title, 'Test notification');
      expect(notification.body, 'Check the admin inbox');
      expect(notification.destination.path, '/notifications');
    },
  );
}
