import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

Map<String, dynamic> _address() => {
  'id': 9,
  'label': 'Default',
  'is_default': true,
  'lat': '33.5000',
  'lng': '36.3000',
  'full_address': 'Main Street',
  'street_name': 'Main Street',
  'house_number': '1',
  'city': 'Damascus',
  'postal_code': '00000',
  'country': 'Syria',
};

Map<String, dynamic> _driverJson() => {
  'id': 42,
  'profile_id': 99,
  'user': {
    'id': 42,
    'name': 'Driver Forty Two',
    'phone': '+963900000042',
    'email': 'driver@example.test',
  },
  'address': _address(),
  'status': 'APPROVED',
  'vehicle_type': 'CAR',
  'vehicle_plate_number': 'D-42',
  'is_online': false,
  'created_at': '2026-09-10T12:00:00Z',
};

Map<String, dynamic> _restaurantJson() => {
  'id': 7,
  'user': {'id': 71, 'name': 'Owner Seven', 'phone': '+963900000071'},
  'seller_profile': {},
  'address': _address(),
  'name': 'Restaurant Seven',
  'logo': null,
  'phone': '+963900000007',
  'work_hours': {},
  'delivery_enabled': true,
  'status': 'ACTIVE',
  'created_at': '2026-09-10T12:00:00Z',
};

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  test(
    'admin list requests follow contract query names and response shape',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/admin/drivers/') {
            return http.Response(
              jsonEncode({
                'count': 1,
                'next': null,
                'previous': null,
                'results': [_driverJson()],
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'count': 1,
              'next': null,
              'previous': null,
              'results': [_restaurantJson()],
            }),
            200,
          );
        }),
      );

      final drivers = await api.getAdminDrivers(
        page: 2,
        search: 'Driver Forty Two',
        status: 'approved',
        isOnline: false,
        countryId: 3,
      );
      final restaurants = await api.getAdminRestaurants(
        page: 2,
        search: 'Restaurant Seven',
        status: 'active',
        countryId: 3,
      );

      expect(drivers.count, 1);
      expect(drivers.results.single.id, 42);
      expect(drivers.results.single.name, 'Driver Forty Two');
      expect(drivers.results.single.email, 'driver@example.test');
      expect(drivers.results.single.latitude, '33.5000');
      expect(restaurants.results.single.id, 7);
      expect(restaurants.results.single.ownerUser, 71);
      expect(restaurants.results.single.ownerName, 'Owner Seven');
      expect(restaurants.results.single.isActive, isTrue);

      expect(requests[0].url.queryParameters, {
        'page': '2',
        'search': 'Driver Forty Two',
        'status': 'APPROVED',
        'is_online': 'false',
        'country_id': '3',
      });
      expect(requests[1].url.queryParameters, {
        'page': '2',
        'search': 'Restaurant Seven',
        'status': 'ACTIVE',
        'country_id': '3',
      });

      api.dispose();
    },
  );

  test(
    'admin detail requests use user id for drivers and entity id for restaurants',
    () async {
      final paths = <String>[];
      final api = ApiService(
        client: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.startsWith('/api/admin/drivers/')) {
            return http.Response(jsonEncode(_driverJson()), 200);
          }
          return http.Response(jsonEncode(_restaurantJson()), 200);
        }),
      );

      final driver = await api.getAdminDriver(42);
      final restaurant = await api.getAdminRestaurant(7);

      expect(driver.id, 42);
      expect(driver.name, 'Driver Forty Two');
      expect(driver.phone, '+963900000042');
      expect(restaurant.id, 7);
      expect(restaurant.ownerUser, 71);
      expect(paths, ['/api/admin/drivers/42/', '/api/admin/restaurants/7/']);

      api.dispose();
    },
  );
}
