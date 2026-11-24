import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  test('creates a support ticket with the exact atomic payload', () async {
    late http.Request request;
    final api = ApiService(
      client: MockClient((captured) async {
        request = captured;
        return http.Response(jsonEncode(_ticketJson()), 201);
      }),
    )..setAuthToken('admin-token');

    final ticket = await api.createAdminSupportTicket(
      subject: 'Driver cannot go online',
      category: 'DELIVERY',
      priority: 'HIGH',
      target: {'type': 'DRIVER', 'id': 17},
      relatedOrderId: 42,
      recipientUserId: 17,
      body: 'Please check the driver account.',
      attachments: const [
        {
          'file_url': 'https://res.cloudinary.com/example/support.png',
          'mime_type': 'image/png',
        },
      ],
      idempotencyKey: '550e8400-e29b-41d4-a716-446655440000',
    );

    expect(request.method, 'POST');
    expect(request.url.path, '/api/admin/support/tickets/');
    expect(request.headers['authorization'], 'Bearer admin-token');
    expect(jsonDecode(request.body), {
      'subject': 'Driver cannot go online',
      'category': 'DELIVERY',
      'priority': 'HIGH',
      'target': {'type': 'DRIVER', 'id': 17},
      'related_order_id': 42,
      'recipient_user_id': 17,
      'body': 'Please check the driver account.',
      'attachments': [
        {
          'file_url': 'https://res.cloudinary.com/example/support.png',
          'mime_type': 'image/png',
        },
      ],
      'idempotency_key': '550e8400-e29b-41d4-a716-446655440000',
    });
    expect(ticket.id, 91);
    expect(ticket.messages, hasLength(1));
  });

  test(
    'accepts a general ticket response with HTTP 200 and omits its target',
    () async {
      late http.Request request;
      final api = ApiService(
        client: MockClient((captured) async {
          request = captured;
          return http.Response(jsonEncode(_ticketJson()), 200);
        }),
      );

      await api.createAdminSupportTicket(
        subject: 'General question',
        category: 'OTHER',
        priority: 'MEDIUM',
        target: null,
        recipientUserId: 9,
        body: 'A general support message.',
        idempotencyKey: '550e8400-e29b-41d4-a716-446655440001',
      );

      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['target'], isNull);
      expect(payload.containsKey('related_order_id'), isFalse);
      expect(payload.keys, {
        'subject',
        'category',
        'priority',
        'target',
        'recipient_user_id',
        'body',
        'attachments',
        'idempotency_key',
      });
    },
  );

  test('preserves API business code and field errors', () async {
    final api = ApiService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'code': 'ticket_target_mismatch',
            'subject': ['Subject is not allowed.'],
          }),
          400,
        );
      }),
    );

    await expectLater(
      api.createAdminSupportTicket(
        subject: 'Bad ticket',
        category: 'OTHER',
        priority: 'MEDIUM',
        target: null,
        recipientUserId: 9,
        body: 'Message',
        idempotencyKey: '550e8400-e29b-41d4-a716-446655440002',
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'ticket_target_mismatch')
            .having(
              (error) => error.fieldErrors['subject'],
              'subject error',
              'Subject is not allowed.',
            ),
      ),
    );
  });
}

Map<String, dynamic> _ticketJson() {
  return {
    'id': 91,
    'subject': 'Created ticket',
    'category': 'OTHER',
    'priority': 'MEDIUM',
    'status': 'OPEN',
    'requester': 7,
    'requester_name': 'Admin User',
    'order': null,
    'restaurant': null,
    'restaurant_name': null,
    'driver': null,
    'driver_name': null,
    'assigned_to': null,
    'assigned_to_name': null,
    'created_at': '2026-09-11T10:00:00Z',
    'updated_at': '2026-09-11T10:00:00Z',
    'last_activity_at': '2026-09-11T10:00:00Z',
    'closed_at': null,
    'messages': [
      {
        'id': 501,
        'author': 7,
        'author_name': 'Admin User',
        'author_role': 'STAFF',
        'body': 'Initial message',
        'created_at': '2026-09-11T10:00:00Z',
        'attachments': [],
      },
    ],
  };
}
