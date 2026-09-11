import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/providers/admin_provider.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  test(
    'keeps support pagination links and requests the selected page',
    () async {
      final requestedPages = <String?>[];
      final provider = AdminProvider(
        apiService: ApiService(
          client: MockClient((request) async {
            final page = request.url.queryParameters['page'];
            requestedPages.add(page);
            return http.Response(
              jsonEncode({
                'count': 2,
                'next': page == '1' ? '?page=2' : null,
                'previous': page == '2' ? '?page=1' : null,
                'results': [_ticketJson(page == '1' ? 1 : 2)],
              }),
              200,
            );
          }),
        ),
      );

      await provider.fetchTickets(page: 1);
      expect(provider.ticketsPage, 1);
      expect(provider.ticketsNext, '?page=2');
      expect(provider.ticketsPrevious, isNull);

      await provider.fetchTickets(page: 2);
      expect(provider.ticketsPage, 2);
      expect(provider.ticketsNext, isNull);
      expect(provider.ticketsPrevious, '?page=1');
      expect(requestedPages, ['1', '2']);

      provider.dispose();
    },
  );
}

Map<String, dynamic> _ticketJson(int id) {
  return {
    'id': id,
    'subject': 'Ticket $id',
    'category': 'OTHER',
    'priority': 'MEDIUM',
    'status': 'OPEN',
    'requester': 7,
    'requester_name': 'Admin User',
    'created_at': '2026-09-11T10:00:00Z',
    'updated_at': '2026-09-11T10:00:00Z',
    'last_activity_at': '2026-09-11T10:00:00Z',
    'messages': [],
  };
}
