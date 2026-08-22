import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/l10n/app_localizations.dart';
import 'package:taybgoadmin/core/providers/admin_provider.dart';
import 'package:taybgoadmin/core/services/api_service.dart';
import 'package:taybgoadmin/core/services/cloudinary_service.dart';
import 'package:taybgoadmin/core/services/google_places_service.dart';
import 'package:taybgoadmin/features/management/create_driver_screen.dart';
import 'package:taybgoadmin/features/management/create_restaurant_screen.dart';
import 'package:taybgoadmin/features/management/managed_file_picker.dart';

Map<String, dynamic> _emptyHome() => {
  'drivers_with_locations': {
    'count': 0,
    'next': null,
    'previous': null,
    'results': [],
  },
  'restaurants': {'count': 0, 'next': null, 'previous': null, 'results': []},
  'pending_drivers': {
    'count': 0,
    'next': null,
    'previous': null,
    'results': [],
  },
  'pending_restaurants': {
    'count': 0,
    'next': null,
    'previous': null,
    'results': [],
  },
  'orders_count_by_status': <String, int>{},
  'drivers_count': {'online': 0, 'offline': 0},
};

Future<void> _pumpForm(
  WidgetTester tester, {
  required Widget form,
  required MockClient client,
}) async {
  final provider = AdminProvider(apiService: ApiService(client: client));
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: '/form',
        routes: {
          '/': (_) => const Scaffold(body: Text('Done')),
          '/form': (_) => form,
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String value) {
  return tester.enterText(find.byKey(Key(key)), value);
}

GooglePlacesService _testPlacesService() {
  return GooglePlacesService(
    apiKey: 'test-key',
    client: MockClient((request) async {
      if (request.url.path.endsWith('/places:autocomplete')) {
        return http.Response(
          jsonEncode({
            'suggestions': [
              {
                'placePrediction': {
                  'placeId': 'test-place',
                  'text': {'text': 'Grand Place, 1000 Brussels, Belgium'},
                  'structuredFormat': {
                    'mainText': {'text': 'Grand Place'},
                    'secondaryText': {'text': '1000 Brussels, Belgium'},
                  },
                },
              },
            ],
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/places/test-place')) {
        return http.Response(
          jsonEncode({
            'id': 'test-place',
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
      }
      return http.Response('{}', 404);
    }),
  );
}

CloudinaryService _testCloudinaryService() {
  return CloudinaryService(
    cloudName: 'test-cloud',
    uploadPreset: 'test-preset',
    client: MockClient(
      (_) async => http.Response(
        jsonEncode({'secure_url': 'https://res.cloudinary.com/test/file.pdf'}),
        200,
      ),
    ),
  );
}

Future<ManagedPickedFile?> _testFilePicker({required bool imagesOnly}) async {
  return ManagedPickedFile(
    bytes: Uint8List.fromList([1, 2, 3]),
    fileName: imagesOnly ? 'logo.png' : 'document.pdf',
    isImage: imagesOnly,
  );
}

Future<void> _tapUpload(WidgetTester tester, String key) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: field, matching: find.byType(OutlinedButton)),
  );
  await tester.pumpAndSettle();
}

Future<void> _uploadRequiredDriverDocuments(WidgetTester tester) async {
  for (final key in [
    'profile.driving_license',
    'profile.id_document',
    'profile.health_insurance_document',
    'profile.address_document',
    'profile.bank_document',
  ]) {
    await _tapUpload(tester, 'driver-upload-$key');
  }
}

Future<void> _selectTestAddress(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('google-places-search')),
    'Grand Place',
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  final suggestion = find.widgetWithText(ListTile, 'Grand Place');
  await tester.ensureVisible(suggestion);
  await tester.pumpAndSettle();
  await tester.tap(suggestion);
  await tester.pumpAndSettle();
  expect(find.text('Address selected'), findsOneWidget);
}

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  testWidgets('driver form reports missing required fields without posting', (
    tester,
  ) async {
    var posts = 0;
    await _pumpForm(
      tester,
      form: CreateDriverScreen(
        placesService: _testPlacesService(),
        cloudinaryService: _testCloudinaryService(),
        filePicker: _testFilePicker,
      ),
      client: MockClient((request) async {
        if (request.method == 'POST') posts++;
        return http.Response(jsonEncode(_emptyHome()), 200);
      }),
    );

    await tester.tap(find.byKey(const Key('managed-form-submit')));
    await tester.pump();

    expect(posts, 0);
    expect(find.text('Please correct the highlighted fields.'), findsOneWidget);
    expect(find.text('This field is required.'), findsWidgets);
  });

  testWidgets('driver form sends a valid creation payload', (tester) async {
    Map<String, dynamic>? posted;
    await _pumpForm(
      tester,
      form: CreateDriverScreen(
        placesService: _testPlacesService(),
        cloudinaryService: _testCloudinaryService(),
        filePicker: _testFilePicker,
      ),
      client: MockClient((request) async {
        if (request.url.path == '/api/admin/drivers/') {
          posted = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'id': 12}), 201);
        }
        return http.Response(jsonEncode(_emptyHome()), 200);
      }),
    );

    await _enter(tester, 'driver-name', 'Alex Driver');
    await _enter(tester, 'driver-phone', '470000000');
    await _selectTestAddress(tester);
    await _uploadRequiredDriverDocuments(tester);
    await tester.tap(find.byKey(const Key('managed-form-submit')));
    await tester.pumpAndSettle();

    expect(posted?['user']['name'], 'Alex Driver');
    expect(posted?['profile']['status'], 'APPROVED');
    expect(posted?['profile']['vehicle_type'], 'BIKE');
    expect(posted?['profile']['accepts_taxi'], isFalse);
    expect(posted?['profile']['driving_license'], startsWith('https://'));
    expect(posted?['user']['phone'], '+32470000000');
    expect(posted?['address']['city'], 'Brussels');
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('car exposes mandatory details, bounded years, and taxi', (
    tester,
  ) async {
    await _pumpForm(
      tester,
      form: CreateDriverScreen(
        placesService: _testPlacesService(),
        cloudinaryService: _testCloudinaryService(),
        filePicker: _testFilePicker,
      ),
      client: MockClient(
        (_) async => http.Response(jsonEncode(_emptyHome()), 200),
      ),
    );

    expect(find.text('Taxi'), findsNothing);
    final vehicleType = find.byKey(const Key('driver-vehicle-type'));
    await tester.ensureVisible(vehicleType);
    await tester.pumpAndSettle();
    await tester.tap(vehicleType);
    await tester.pumpAndSettle();
    expect(find.text('Motorcycle'), findsNothing);
    expect(find.text('Van'), findsNothing);
    await tester.tap(find.text('Car').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('driver-vehicle-plate')), findsOneWidget);
    expect(find.byKey(const Key('driver-vehicle-color')), findsOneWidget);
    expect(find.byKey(const Key('driver-vehicle-make')), findsOneWidget);
    expect(find.byKey(const Key('driver-vehicle-model')), findsOneWidget);
    expect(find.text('Taxi'), findsOneWidget);

    final year = find.byKey(const Key('driver-vehicle-year'));
    await tester.ensureVisible(year);
    await tester.pumpAndSettle();
    await tester.tap(year);
    await tester.pumpAndSettle();
    expect(find.text('${DateTime.now().year + 1}'), findsOneWidget);
  });

  testWidgets('restaurant form sends account, schedule, and active status', (
    tester,
  ) async {
    Map<String, dynamic>? posted;
    await _pumpForm(
      tester,
      form: CreateRestaurantScreen(
        placesService: _testPlacesService(),
        cloudinaryService: _testCloudinaryService(),
        filePicker: _testFilePicker,
      ),
      client: MockClient((request) async {
        if (request.url.path == '/api/admin/restaurants/') {
          posted = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'id': 21}), 201);
        }
        return http.Response(jsonEncode(_emptyHome()), 200);
      }),
    );

    await _enter(tester, 'restaurant-owner-name', 'Sam Owner');
    await _enter(tester, 'restaurant-owner-phone', '471111111');
    await _enter(tester, 'restaurant-name', 'Green Table');
    await _enter(tester, 'restaurant-phone', '20000000');
    await _selectTestAddress(tester);
    await _tapUpload(tester, 'restaurant-upload-logo');
    await _tapUpload(tester, 'restaurant-upload-license');
    await tester.tap(find.byKey(const Key('managed-form-submit')));
    await tester.pumpAndSettle();

    expect(posted?['user']['name'], 'Sam Owner');
    expect(posted?['restaurant']['name'], 'Green Table');
    expect(posted?['restaurant']['status'], 'ACTIVE');
    expect(posted?['restaurant']['delivery_enabled'], isTrue);
    expect(posted?['restaurant']['logo'], startsWith('https://'));
    expect(
      posted?['seller_profile']['restaurant_registration_license_document'],
      startsWith('https://'),
    );
    expect(posted?['restaurant']['work_hours']['monday'], isA<List>());
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('nested server errors appear on the matching field', (
    tester,
  ) async {
    await _pumpForm(
      tester,
      form: CreateDriverScreen(
        placesService: _testPlacesService(),
        cloudinaryService: _testCloudinaryService(),
        filePicker: _testFilePicker,
      ),
      client: MockClient((request) async {
        if (request.url.path == '/api/admin/drivers/') {
          return http.Response(
            jsonEncode({
              'user': {
                'phone': ['This phone is already registered.'],
              },
            }),
            400,
          );
        }
        return http.Response(jsonEncode(_emptyHome()), 200);
      }),
    );

    await _enter(tester, 'driver-name', 'Alex Driver');
    await _enter(tester, 'driver-phone', '470000000');
    await _selectTestAddress(tester);
    await _uploadRequiredDriverDocuments(tester);
    await tester.tap(find.byKey(const Key('managed-form-submit')));
    await tester.pumpAndSettle();

    expect(find.text('This phone is already registered.'), findsOneWidget);
    expect(
      find.text('The server rejected one or more fields.'),
      findsOneWidget,
    );
  });
}
