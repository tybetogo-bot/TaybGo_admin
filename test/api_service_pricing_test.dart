import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/models/pricing_policy.dart';
import 'package:taybgoadmin/core/providers/pricing_provider.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

Map<String, dynamic> _policyJson({int id = 1}) {
  return {
    'id': id,
    'name': 'Brussels bike pricing',
    'scope': 'CITY',
    'country': null,
    'country_name': null,
    'country_iso_code': null,
    'city': 4,
    'city_name': 'Brussels',
    'order_type': 'SHIPPING',
    'vehicle_type': 'BIKE',
    'base_amount': '5.00',
    'base_distance': '2.00',
    'per_km_rate': '1.25',
    'driver_base_amount': '3.00',
    'driver_base_distance': '2.00',
    'driver_price_per_km': '0.80',
    'weight_multiplier': '0.50',
    'average_speed_kmh': 20,
    'currency': 'EUR',
    'version': 1,
    'effective_from': '2026-08-06T10:00:00Z',
    'effective_to': null,
    'is_active': true,
    'created_at': '2026-08-06T09:00:00Z',
    'updated_at': '2026-08-06T09:00:00Z',
  };
}

void main() {
  setUp(() {
    EnvConfig.init(env: Environment.dev);
  });

  test(
    'getPricingPolicies sends authenticated filters and parses pagination',
    () async {
      Uri? capturedUri;
      Map<String, String>? capturedHeaders;

      final api = ApiService(
        client: MockClient((request) async {
          capturedUri = request.url;
          capturedHeaders = request.headers;
          return http.Response(
            jsonEncode({
              'count': 1,
              'next': null,
              'previous': null,
              'results': [_policyJson()],
            }),
            200,
          );
        }),
      );
      api.setAuthToken('access-token');

      final response = await api.getPricingPolicies(
        page: 2,
        search: 'Brussels',
        scope: 'city',
        countryId: 7,
        cityId: 4,
        orderType: 'food',
        vehicleType: 'bike',
        isActive: true,
        currency: 'eur',
      );

      expect(capturedUri?.path, '/api/admin/pricing-policies/');
      expect(capturedUri?.queryParameters, {
        'page': '2',
        'search': 'Brussels',
        'scope': 'CITY',
        'country_id': '7',
        'city_id': '4',
        'order_type': 'FOOD',
        'vehicle_type': 'BIKE',
        'is_active': 'true',
        'currency': 'EUR',
      });
      expect(capturedHeaders?['authorization'], 'Bearer access-token');
      expect(response.count, 1);
      expect(response.results.single.cityName, 'Brussels');
      expect(response.results.single.driverPricePerKm, '0.80');
    },
  );

  test('createPricingPolicy sends writable fields and parses 201', () async {
    Map<String, dynamic>? capturedBody;
    final api = ApiService(
      client: MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(_policyJson()), 201);
      }),
    );

    final created = await api.createPricingPolicy({
      'name': 'Brussels bike pricing',
      'scope': 'CITY',
      'country': null,
      'city': 4,
      'order_type': 'SHIPPING',
      'vehicle_type': 'BIKE',
      'base_amount': '5.00',
      'base_distance': '2.00',
      'per_km_rate': '1.25',
      'weight_multiplier': '0.50',
      'average_speed_kmh': 20,
      'currency': 'EUR',
      'version': 1,
      'effective_from': '2026-08-06T10:00:00Z',
      'effective_to': null,
      'is_active': true,
    });

    expect(created.id, 1);
    expect(capturedBody?['city'], 4);
    expect(capturedBody?.containsKey('id'), isFalse);
    expect(capturedBody?.containsKey('city_name'), isFalse);
    expect(capturedBody?.containsKey('created_at'), isFalse);
  });

  test('pricing target preflight loads all matching pages', () async {
    var requestCount = 0;
    final api = ApiService(
      client: MockClient((request) async {
        requestCount++;
        expect(request.url.queryParameters['scope'], 'GLOBAL');
        expect(request.url.queryParameters['order_type'], 'FOOD');
        expect(request.url.queryParameters['vehicle_type'], 'BIKE');

        final hasNextPage = requestCount == 1;
        return http.Response(
          jsonEncode({
            'count': 2,
            'next': hasNextPage ? '?page=2' : null,
            'previous': null,
            'results': [_policyJson(id: requestCount)],
          }),
          200,
        );
      }),
    );
    final provider = PricingProvider(apiService: api);

    final policies = await provider.findPoliciesForTarget(
      scope: 'GLOBAL',
      orderType: 'FOOD',
      vehicleType: 'BIKE',
    );

    expect(requestCount, 2);
    expect(policies.map((policy) => policy.id), [1, 2]);
  });

  test('detail, patch, put, and delete use the detail endpoint', () async {
    final methods = <String>[];
    final paths = <String>[];
    final api = ApiService(
      client: MockClient((request) async {
        methods.add(request.method);
        paths.add(request.url.path);
        if (request.method == 'DELETE') return http.Response('', 204);
        return http.Response(jsonEncode(_policyJson(id: 8)), 200);
      }),
    );

    await api.getPricingPolicy(8);
    await api.patchPricingPolicy(8, {'name': 'Updated'});
    await api.putPricingPolicy(8, {'name': 'Replaced'});
    await api.deletePricingPolicy(8);

    expect(methods, ['GET', 'PATCH', 'PUT', 'DELETE']);
    expect(paths, everyElement('/api/admin/pricing-policies/8/'));
  });

  test('pricing API exposes field-keyed validation errors', () async {
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'base_amount': ['Ensure this value is greater than or equal to 0.'],
            'effective_to': ['Must be later than effective_from.'],
          }),
          400,
        ),
      ),
    );

    await expectLater(
      () => api.createPricingPolicy({}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having(
              (e) => e.fieldErrors['base_amount'],
              'base_amount error',
              contains('greater than or equal'),
            )
            .having(
              (e) => e.fieldErrors['effective_to'],
              'effective_to error',
              contains('later'),
            ),
      ),
    );
  });

  test('country and city selectors use admin list APIs', () async {
    final paths = <String>[];
    final api = ApiService(
      client: MockClient((request) async {
        paths.add(request.url.toString());
        if (request.url.path.endsWith('/countries/')) {
          return http.Response(
            jsonEncode({
              'count': 1,
              'next': null,
              'previous': null,
              'results': [
                {
                  'id': 7,
                  'name': 'Belgium',
                  'iso_code': 'BE',
                  'is_active': true,
                  'created_at': '2026-08-06T09:00:00Z',
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'count': 1,
            'next': null,
            'previous': null,
            'results': [
              {
                'id': 4,
                'country': 7,
                'country_name': 'Belgium',
                'country_iso_code': 'BE',
                'name': 'Brussels',
                'is_active': true,
                'created_at': '2026-08-06T09:00:00Z',
              },
            ],
          }),
          200,
        );
      }),
    );

    final countries = await api.getAdminCountries(isActive: true);
    final cities = await api.getAdminCities(countryId: 7, isActive: true);

    expect(countries.results.single.isoCode, 'BE');
    expect(cities.results.single.displayName, 'Brussels, Belgium');
    expect(paths[0], contains('/api/admin/countries/?is_active=true'));
    expect(
      paths[1],
      contains('/api/admin/cities/?country_id=7&is_active=true'),
    );
  });

  test(
    'policy validation enforces scope, nonnegative rates, currency, and dates',
    () {
      final errors = PricingPolicyValidation.validate(
        name: '',
        scope: 'CITY',
        orderType: 'SHIPPING',
        vehicleType: 'BIKE',
        baseAmount: '-1',
        baseDistance: '2',
        perKmRate: '1.25',
        weightMultiplier: '0.5',
        averageSpeedKmh: '0',
        currency: 'EURO',
        version: '1',
        effectiveFrom: DateTime(2026, 8, 7),
        effectiveTo: DateTime(2026, 8, 6),
      );

      expect(
        errors.keys,
        containsAll([
          'name',
          'city',
          'base_amount',
          'average_speed_kmh',
          'currency',
          'effective_to',
        ]),
      );
    },
  );
}
