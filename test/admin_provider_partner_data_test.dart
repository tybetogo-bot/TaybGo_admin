import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/providers/admin_provider.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

Map<String, dynamic> _driver(int id, {required bool online}) => {
  'id': id,
  'name': 'Driver $id',
  'phone': '+43000000$id',
  'status': 'APPROVED',
  'is_online': online,
};

Map<String, dynamic> _restaurant(int id, {required bool active}) => {
  'id': id,
  'owner_user': id + 1000,
  'name': 'Restaurant $id',
  'phone': '+43100000$id',
  'status': active ? 'ACTIVE' : 'INACTIVE',
  'is_active': active,
  'work_hours': {},
};

Map<String, dynamic> _adminDriver(int id) => {
  'id': id,
  'profile_id': id + 100,
  'user': {
    'id': id,
    'name': 'Admin Driver $id',
    'phone': '+43000000$id',
    'email': 'driver$id@example.test',
  },
  'status': 'APPROVED',
  'vehicle_type': 'CAR',
  'is_online': id.isEven,
};

Map<String, dynamic> _adminRestaurant(int id) => {
  'id': id,
  'user': {'id': id + 1000, 'name': 'Owner $id', 'phone': '+43100000$id'},
  'name': 'Admin Restaurant $id',
  'phone': '+43100000$id',
  'status': 'ACTIVE',
  'work_hours': {},
};

Map<String, dynamic> _homeResponse({
  required int driversPage,
  required int restaurantsPage,
}) {
  final firstDriverPage = driversPage == 1;
  final firstRestaurantPage = restaurantsPage == 1;
  return {
    'drivers_with_locations': {
      'count': 2,
      'next': firstDriverPage ? 'https://example.test/drivers?page=2' : null,
      'previous': null,
      'results': [_driver(firstDriverPage ? 1 : 2, online: firstDriverPage)],
    },
    'restaurants': {
      'count': 2,
      'next': firstRestaurantPage
          ? 'https://example.test/restaurants?page=2'
          : null,
      'previous': null,
      'results': [
        _restaurant(firstRestaurantPage ? 10 : 11, active: firstRestaurantPage),
      ],
    },
    'pending_drivers': {'count': 0, 'results': []},
    'pending_restaurants': {'count': 0, 'results': []},
    'orders_count_by_status': {},
    'drivers_count': {'online': 1, 'offline': 1},
  };
}

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  test('loads every driver and restaurant page for management data', () async {
    final requests = <http.Request>[];
    final api = ApiService(
      client: MockClient((request) async {
        requests.add(request);
        final driversPage =
            int.tryParse(request.url.queryParameters['drivers_page'] ?? '1') ??
            1;
        final restaurantsPage =
            int.tryParse(
              request.url.queryParameters['restaurants_page'] ?? '1',
            ) ??
            1;
        return http.Response(
          jsonEncode(
            _homeResponse(
              driversPage: driversPage,
              restaurantsPage: restaurantsPage,
            ),
          ),
          200,
        );
      }),
    );
    final provider = AdminProvider(apiService: api);

    await provider.fetchHome();

    expect(provider.drivers.map((driver) => driver.id), [1, 2]);
    expect(provider.restaurants.map((restaurant) => restaurant.id), [10, 11]);
    expect(provider.driversTotal, 2);
    expect(provider.restaurantsTotal, 2);
    expect(
      requests.where(
        (request) => request.url.queryParameters['drivers_page'] == '2',
      ),
      hasLength(1),
    );
    expect(
      requests.where(
        (request) => request.url.queryParameters['restaurants_page'] == '2',
      ),
      hasLength(1),
    );

    provider.dispose();
  });

  test(
    'loads direct admin partner collections with server-side filters',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        client: MockClient((request) async {
          requests.add(request);
          final page = request.url.queryParameters['page'] ?? '1';
          final isDriver = request.url.path == '/api/admin/drivers/';
          final result = isDriver
              ? (page == '1' ? [_adminDriver(1)] : [_adminDriver(2)])
              : (page == '1' ? [_adminRestaurant(10)] : [_adminRestaurant(11)]);
          return http.Response(
            jsonEncode({
              'count': 2,
              'next': page == '1' ? '?page=2' : null,
              'previous': null,
              'results': result,
            }),
            200,
          );
        }),
      );
      final provider = AdminProvider(apiService: api);

      await provider.fetchManagementDrivers(
        search: 'Admin Driver',
        status: 'approved',
        isOnline: true,
      );
      await provider.fetchManagementRestaurants(
        search: 'Admin Restaurant',
        status: 'active',
      );

      expect(provider.managementDrivers.map((driver) => driver.id), [1, 2]);
      expect(
        provider.managementRestaurants.map((restaurant) => restaurant.id),
        [10, 11],
      );
      expect(
        requests.where(
          (request) =>
              request.url.path == '/api/admin/drivers/' &&
              request.url.queryParameters['search'] == 'Admin Driver',
        ),
        hasLength(2),
      );
      expect(
        requests.where(
          (request) =>
              request.url.path == '/api/admin/restaurants/' &&
              request.url.queryParameters['status'] == 'ACTIVE',
        ),
        hasLength(2),
      );

      provider.dispose();
    },
  );

  test(
    'normalizes formatted phone searches before calling admin endpoints',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        client: MockClient((request) async {
          requests.add(request);
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

      await provider.fetchManagementDrivers(search: ' +43 000-0001 ');
      await provider.fetchManagementRestaurants(search: ' +43 100-0001 ');

      expect(requests[0].url.queryParameters['search'], '430000001');
      expect(requests[1].url.queryParameters['search'], '431000001');

      provider.dispose();
    },
  );

  test('loads all pending approval pages from the direct contracts', () async {
    final requests = <http.Request>[];
    final api = ApiService(
      client: MockClient((request) async {
        requests.add(request);
        final page = request.url.queryParameters['page'] ?? '1';
        if (request.url.path == '/api/admin/drivers/verification-queue/') {
          return http.Response(
            jsonEncode({
              'count': 2,
              'next': page == '1' ? '?page=2' : null,
              'previous': null,
              'results': [
                {..._adminDriver(page == '1' ? 1 : 2), 'status': 'PENDING'},
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'count': 2,
            'next': page == '1' ? '?page=2' : null,
            'previous': null,
            'results': [
              {..._adminRestaurant(page == '1' ? 10 : 11), 'status': 'PENDING'},
            ],
          }),
          200,
        );
      }),
    );
    final provider = AdminProvider(apiService: api);

    await provider.fetchApprovals();

    expect(provider.pendingDrivers.map((driver) => driver.id), [1, 2]);
    expect(provider.pendingRestaurants.map((restaurant) => restaurant.id), [
      10,
      11,
    ]);
    expect(provider.pendingDriversTotal, 2);
    expect(provider.pendingRestaurantsTotal, 2);
    expect(
      requests.where(
        (request) =>
            request.url.path == '/api/admin/restaurants/' &&
            request.url.queryParameters['status'] == 'PENDING',
      ),
      hasLength(2),
    );

    provider.dispose();
  });
}
