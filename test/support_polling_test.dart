import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/providers/admin_provider.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

Map<String, dynamic> _ticketJson(int messageCount) {
  return {
    'id': 7,
    'subject': 'Delivery issue',
    'category': 'DELIVERY',
    'priority': 'HIGH',
    'status': 'OPEN',
    'requester': 21,
    'requester_name': 'Requester',
    'created_at': '2026-09-11T10:00:00Z',
    'updated_at': messageCount > 1
        ? '2026-09-11T10:00:03Z'
        : '2026-09-11T10:00:00Z',
    'last_activity_at': messageCount > 1
        ? '2026-09-11T10:00:03Z'
        : '2026-09-11T10:00:00Z',
    'messages': List.generate(
      messageCount,
      (index) => {
        'id': index + 1,
        'author': 21,
        'author_name': 'Requester',
        'author_role': 'CUSTOMER',
        'body': index == 0 ? 'Original message' : 'New message',
        'created_at': index == 0
            ? '2026-09-11T10:00:00Z'
            : '2026-09-11T10:00:03Z',
      },
    ),
  };
}

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  testWidgets('active ticket polling retrieves new messages every 3 seconds', (
    tester,
  ) async {
    var detailCalls = 0;
    final provider = AdminProvider(
      apiService: ApiService(
        client: MockClient((request) async {
          expectSync(request.url.path, '/api/admin/support/tickets/7/');
          detailCalls++;
          return http.Response(
            jsonEncode(_ticketJson(detailCalls > 1 ? 2 : 1)),
            200,
          );
        }),
      ),
    );

    await provider.fetchTicketDetail(7);
    expect(provider.selectedTicket?.messages, hasLength(1));

    provider.startSupportPolling(ticketId: 7);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(detailCalls, 2);
    expect(provider.selectedTicket?.messages, hasLength(2));

    provider.stopSupportPolling();
    provider.dispose();
  });
}
