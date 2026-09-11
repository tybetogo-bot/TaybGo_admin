import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  test(
    'activate sends an empty POST and accepts an empty 200 response',
    () async {
      late http.Request request;
      final api = ApiService(
        client: MockClient((captured) async {
          request = captured;
          return http.Response('', 200);
        }),
      )..setAuthToken('admin-token');

      await api.activateRestaurant(42);

      expect(request.method, 'POST');
      expect(request.url.path, '/api/admin/restaurants/42/activate/');
      expect(request.body, isEmpty);
      expect(request.headers['authorization'], 'Bearer admin-token');

      api.dispose();
    },
  );

  test(
    'deactivate sends an empty POST and accepts an empty 200 response',
    () async {
      late http.Request request;
      final api = ApiService(
        client: MockClient((captured) async {
          request = captured;
          return http.Response('', 200);
        }),
      );

      await api.deactivateRestaurant(42);

      expect(request.method, 'POST');
      expect(request.url.path, '/api/admin/restaurants/42/deactivate/');
      expect(request.body, isEmpty);

      api.dispose();
    },
  );

  test('status action errors keep backend detail and status code', () async {
    final api = ApiService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'detail': 'Restaurant is already inactive.',
            'code': 'CONFLICT',
          }),
          409,
        );
      }),
    );

    await expectLater(
      api.deactivateRestaurant(42),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status code', 409)
            .having(
              (error) => error.message,
              'message',
              'Restaurant is already inactive.',
            )
            .having((error) => error.code, 'code', 'CONFLICT'),
      ),
    );

    api.dispose();
  });
}
