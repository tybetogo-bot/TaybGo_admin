import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/providers/admin_provider.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

Map<String, dynamic> _restaurant({required String status}) => {
  'id': 7,
  'owner_user': 70,
  'name': 'Cafe Seven',
  'phone': '+4300000007',
  'status': status,
  'is_active': status == 'ACTIVE',
  'work_hours': {},
};

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  test(
    'status action refetches detail and refreshes the current filtered list',
    () async {
      final requests = <http.Request>[];
      var listCalls = 0;
      final api = ApiService(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/admin/restaurants/') {
            listCalls++;
            return http.Response(
              jsonEncode({
                'count': listCalls == 1 ? 1 : 0,
                'next': null,
                'previous': null,
                'results': listCalls == 1
                    ? [_restaurant(status: 'ACTIVE')]
                    : [],
              }),
              200,
            );
          }
          if (request.url.path == '/api/admin/restaurants/7/deactivate/') {
            return http.Response('', 200);
          }
          if (request.url.path == '/api/admin/restaurants/7/') {
            return http.Response(
              jsonEncode(_restaurant(status: 'INACTIVE')),
              200,
            );
          }
          return http.Response('{}', 200);
        }),
      );
      final provider = AdminProvider(apiService: api);

      await provider.fetchManagementRestaurants(
        search: 'Cafe Seven',
        status: 'ACTIVE',
      );
      final updated = await provider.deactivateRestaurantFromDetail(7);

      expect(updated.effectiveStatus, 'INACTIVE');
      expect(provider.restaurantProfile?.effectiveStatus, 'INACTIVE');
      expect(provider.managementRestaurants, isEmpty);
      expect(listCalls, 2);
      expect(
        requests
            .where((request) => request.url.path == '/api/admin/restaurants/')
            .map((request) => request.url.queryParameters),
        [
          {'page': '1', 'search': 'Cafe Seven', 'status': 'ACTIVE'},
          {'page': '1', 'search': 'Cafe Seven', 'status': 'ACTIVE'},
        ],
      );
      expect(requests.map((request) => request.url.path), [
        '/api/admin/restaurants/',
        '/api/admin/restaurants/7/deactivate/',
        '/api/admin/restaurants/7/',
        '/api/admin/restaurants/',
      ]);

      provider.dispose();
    },
  );

  test(
    'a conflict refetches the restaurant before surfacing the error',
    () async {
      final paths = <String>[];
      final api = ApiService(
        client: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path == '/api/admin/restaurants/7/deactivate/') {
            return http.Response(
              jsonEncode({'detail': 'Already changed.'}),
              409,
            );
          }
          if (request.url.path == '/api/admin/restaurants/7/') {
            return http.Response(
              jsonEncode(_restaurant(status: 'INACTIVE')),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'count': 0,
              'next': null,
              'previous': null,
              'results': [],
            }),
            200,
          );
        }),
      );
      final provider = AdminProvider(apiService: api);

      await provider.fetchManagementRestaurants();
      await expectLater(
        provider.deactivateRestaurantFromDetail(7),
        throwsA(isA<ApiException>()),
      );

      expect(paths, [
        '/api/admin/restaurants/',
        '/api/admin/restaurants/7/deactivate/',
        '/api/admin/restaurants/7/',
        '/api/admin/restaurants/',
      ]);
      expect(provider.restaurantProfile?.effectiveStatus, 'INACTIVE');

      provider.dispose();
    },
  );
}
