import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/providers/country_filter_provider.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  test('supported list requests include country_id when selected', () async {
    final uris = <Uri>[];
    final api = ApiService(
      client: MockClient((request) async {
        uris.add(request.url);
        switch (request.url.path) {
          case '/api/admin/home/':
            return http.Response('{}', 200);
          case '/api/admin/drivers/verification-queue/':
            return http.Response(
              jsonEncode({'count': 0, 'next': null, 'results': []}),
              200,
            );
          case '/api/admin/orders/':
          case '/api/admin/pricing-policies/':
            return http.Response(
              jsonEncode({'count': 0, 'next': null, 'results': []}),
              200,
            );
          case '/api/admin/support/tickets/':
            return http.Response(
              jsonEncode({'count': 0, 'next': null, 'results': []}),
              200,
            );
          case '/api/admin/cities/':
            return http.Response(
              jsonEncode({'count': 0, 'next': null, 'results': []}),
              200,
            );
          default:
            return http.Response('{}', 200);
        }
      }),
    );

    await api.getHome(countryId: 2);
    await api.getAdminOrders(countryId: 2);
    await api.getVerificationQueue(countryId: 2);
    await api.getTickets(countryId: 2);
    await api.getPricingPolicies(countryId: 2);
    await api.getAdminCities(countryId: 2);

    expect(uris, hasLength(6));
    expect(
      uris.map((uri) => uri.queryParameters['country_id']),
      everyElement('2'),
    );
  });

  test('All countries omits country_id', () async {
    Uri? captured;
    final api = ApiService(
      client: MockClient((request) async {
        captured = request.url;
        return http.Response(
          jsonEncode({'count': 0, 'next': null, 'results': []}),
          200,
        );
      }),
    );

    await api.getAdminOrders();

    expect(captured?.queryParameters.containsKey('country_id'), isFalse);
  });

  test('country selector loads active countries across pages', () async {
    final requestedPages = <String?>[];
    final provider = CountryFilterProvider(
      apiService: ApiService(
        client: MockClient((request) async {
          requestedPages.add(request.url.queryParameters['page']);
          final page = request.url.queryParameters['page'] ?? '1';
          return http.Response(
            jsonEncode({
              'count': 2,
              'next': page == '1' ? '?page=2' : null,
              'previous': null,
              'results': [
                {
                  'id': page == '1' ? 2 : 3,
                  'name': page == '1' ? 'Belgium' : 'France',
                  'iso_code': page == '1' ? 'BE' : 'FR',
                  'is_active': true,
                },
              ],
            }),
            200,
          );
        }),
      ),
    );

    await provider.loadCountries();
    provider.selectCountry(3);

    expect(requestedPages, [null, '2']);
    expect(provider.countries.map((country) => country.isoCode), ['BE', 'FR']);
    expect(provider.selectedCountryId, 3);
  });
}
