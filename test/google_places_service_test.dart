import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/services/google_places_service.dart';

void main() {
  test(
    'autocomplete uses Places API New with session token and field mask',
    () async {
      late http.Request captured;
      final service = GooglePlacesService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'suggestions': [
                {
                  'placePrediction': {
                    'placeId': 'place-1',
                    'text': {'text': 'Grand Place, Brussels, Belgium'},
                    'structuredFormat': {
                      'mainText': {'text': 'Grand Place'},
                      'secondaryText': {'text': 'Brussels, Belgium'},
                    },
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final results = await service.autocomplete(
        input: 'Grand Place',
        sessionToken: 'session-123',
        languageCode: 'en',
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, '/v1/places:autocomplete');
      expect(captured.headers['X-Goog-Api-Key'], 'test-key');
      expect(
        captured.headers['X-Goog-FieldMask'],
        contains('placePrediction.placeId'),
      );
      expect(jsonDecode(captured.body), {
        'input': 'Grand Place',
        'sessionToken': 'session-123',
        'languageCode': 'en',
      });
      expect(results, hasLength(1));
      expect(results.single.placeId, 'place-1');
      expect(results.single.primaryText, 'Grand Place');
      expect(results.single.secondaryText, 'Brussels, Belgium');
    },
  );

  test(
    'place details maps coordinates and structured address fields',
    () async {
      late http.Request captured;
      final service = GooglePlacesService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'formattedAddress': 'Grand Place 1, 1000 Brussels, Belgium',
              'location': {'latitude': 50.8467, 'longitude': 4.3525},
              'addressComponents': [
                {
                  'longText': 'Grand Place',
                  'types': ['route'],
                },
                {
                  'longText': '1',
                  'types': ['street_number'],
                },
                {
                  'longText': 'Brussels',
                  'types': ['locality'],
                },
                {
                  'longText': '1000',
                  'types': ['postal_code'],
                },
                {
                  'longText': 'Belgium',
                  'types': ['country'],
                },
              ],
            }),
            200,
          );
        }),
      );

      final result = await service.resolveAddress(
        suggestion: const GooglePlaceSuggestion(
          placeId: 'place-1',
          fullText: 'Grand Place, Brussels, Belgium',
          primaryText: 'Grand Place',
        ),
        sessionToken: 'session-123',
        languageCode: 'en',
      );

      expect(captured.method, 'GET');
      expect(captured.url.path, '/v1/places/place-1');
      expect(captured.url.queryParameters['sessionToken'], 'session-123');
      expect(result.fullAddress, 'Grand Place 1, 1000 Brussels, Belgium');
      expect(result.latitude, '50.846700');
      expect(result.longitude, '4.352500');
      expect(result.streetName, 'Grand Place');
      expect(result.houseNumber, '1');
      expect(result.city, 'Brussels');
      expect(result.postalCode, '1000');
      expect(result.country, 'Belgium');
    },
  );

  test('Google errors are exposed as typed exceptions', () async {
    final service = GooglePlacesService(
      apiKey: 'test-key',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'API key is not authorized'},
          }),
          403,
        ),
      ),
    );

    expect(
      () =>
          service.autocomplete(input: 'Brussels', sessionToken: 'session-123'),
      throwsA(
        isA<GooglePlacesException>()
            .having((error) => error.statusCode, 'status code', 403)
            .having(
              (error) => error.message,
              'message',
              contains('not authorized'),
            ),
      ),
    );
  });
}
