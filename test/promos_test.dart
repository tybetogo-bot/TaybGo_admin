import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:taybgoadmin/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/l10n/app_localizations.dart';
import 'package:taybgoadmin/core/providers/country_filter_provider.dart';
import 'package:taybgoadmin/core/providers/promos_provider.dart';
import 'package:taybgoadmin/core/services/api_service.dart';
import 'package:taybgoadmin/features/promos/promos_screen.dart';

Map<String, dynamic> promo({String status = 'PENDING'}) => {
  'id': 7,
  'restaurant': 3,
  'restaurant_name': 'Test Kitchen',
  'title': 'Lunch offer',
  'description': 'Fresh lunch',
  'image_url': '',
  'status': status,
  'is_active': false,
  'priority': 2,
  'restaurant_active_promos_count': 1,
};
void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));
  test('promo list sends server filters and parses pagination', () async {
    final api = ApiService(
      client: MockClient((r) async {
        expect(r.headers['Authorization'], 'Bearer test');
        expect(r.url.queryParameters, {
          'page': '2',
          'status': 'PENDING',
          'country_id': '4',
          'city': 'Vienna',
          'restaurant_id': '3',
          'is_active': 'false',
        });
        return http.Response(
          jsonEncode({
            'count': 20,
            'next': null,
            'previous': '?page=1',
            'results': [promo()],
          }),
          200,
        );
      }),
    )..setAuthToken('test');
    final result = await api.getPromos(
      page: 2,
      status: 'PENDING',
      countryId: 4,
      city: ' Vienna ',
      restaurantId: 3,
      isActive: false,
    );
    expect(result.count, 20);
    expect(result.results.single.activeRestaurantPromos, 1);
  });
  test(
    'moderation sends exact approval, rejection and disable contracts',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        client: MockClient((r) async {
          requests.add(r);
          return http.Response(jsonEncode(promo(status: 'APPROVED')), 200);
        }),
      );
      await api.moderatePromo(7, action: 'approve', priority: 5);
      await api.moderatePromo(
        7,
        action: 'reject',
        reason: 'Please replace image',
      );
      await api.moderatePromo(7, action: 'disable');
      expect(requests.map((r) => r.url.path), [
        '/api/admin/promos/7/approve/',
        '/api/admin/promos/7/reject/',
        '/api/admin/promos/7/disable/',
      ]);
      expect(requests.map((r) => jsonDecode(r.body)), [
        {'priority': 5},
        {'reason': 'Please replace image'},
        {},
      ]);
    },
  );
  test('newer filter response wins over stale requests', () async {
    final api = ApiService(
      client: MockClient((r) async {
        if (r.url.queryParameters['status'] == 'PENDING') {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }
        final status = r.url.queryParameters['status']!;
        return http.Response(jsonEncode([promo(status: status)]), 200);
      }),
    );
    final country = CountryFilterProvider(apiService: api);
    final provider = PromosProvider(api: api, country: country);
    final old = provider.load();
    provider.status = 'APPROVED';
    await provider.load();
    await old;
    expect(provider.items.single.status, 'APPROVED');
    provider.dispose();
    country.dispose();
  });
  testWidgets('mobile review keeps actions visible and validates rejection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requests = <http.Request>[];
    final api = ApiService(
      client: MockClient((r) async {
        requests.add(r);
        if (r.method == 'POST') {
          return http.Response(jsonEncode(promo(status: 'REJECTED')), 200);
        }
        if (r.url.path == '/api/admin/promos/7/') {
          return http.Response(jsonEncode(promo()), 200);
        }
        return http.Response(jsonEncode([promo()]), 200);
      }),
    );
    final country = CountryFilterProvider(apiService: api);
    final provider = PromosProvider(api: api, country: country);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: country),
        ],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: const PromosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Restaurant ID (optional)'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Review promo'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review promo').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Request changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reject promo'));
    await tester.pumpAndSettle();
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
    await tester.enterText(
      find.byType(TextFormField).last,
      'Please replace the image',
    );
    await tester.tap(find.text('Reject promo'));
    await tester.pumpAndSettle();
    expect(jsonDecode(requests.singleWhere((r) => r.method == 'POST').body), {
      'reason': 'Please replace the image',
    });
    expect(find.text('Promo updated'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
    country.dispose();
  });

  test('queue counts partition approved visibility and follow scope', () async {
    final requests = <http.Request>[];
    final api = ApiService(
      client: MockClient((r) async {
        requests.add(r);
        final count = r.url.queryParameters['status'] == 'PENDING' ? 3 : 2;
        return http.Response(
          jsonEncode({'count': count, 'results': [], 'next': null}),
          200,
        );
      }),
    );
    final country = CountryFilterProvider(apiService: api);
    final provider = PromosProvider(api: api, country: country);
    await provider.applyScope(
      city: 'Vienna',
      restaurantId: 3,
      restaurantName: 'Kitchen',
    );
    expect(provider.counts[PromoQueue.pending], 3);
    expect(provider.counts[PromoQueue.all], 9);
    expect(
      requests.every(
        (r) =>
            r.url.queryParameters['city'] == 'Vienna' &&
            r.url.queryParameters['restaurant_id'] == '3',
      ),
      isTrue,
    );
    await provider.selectQueue(PromoQueue.live);
    expect(requests.last.url.queryParameters['status'], 'APPROVED');
    expect(requests.last.url.queryParameters['is_active'], 'true');
    provider.dispose();
    country.dispose();
  });
  for (final spec in [
    (const Size(1440, 1000), const Locale('en'), ThemeMode.light),
    (const Size(390, 844), const Locale('ar'), ThemeMode.dark),
  ]) {
    testWidgets('workspace and detail fit ${spec.$1} ${spec.$2}', (
      tester,
    ) async {
      tester.view.physicalSize = spec.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ApiService(
        client: MockClient(
          (r) async => http.Response(
            jsonEncode(r.url.path.endsWith('/7/') ? promo() : [promo()]),
            200,
          ),
        ),
      );
      final country = CountryFilterProvider(apiService: api);
      final provider = PromosProvider(api: api, country: country);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: country),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: spec.$3,
            locale: spec.$2,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const PromosScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations(spec.$2);
      await tester.scrollUntilVisible(
        find.text(l.promoViewDetails),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.promoViewDetails).first);
      await tester.pumpAndSettle();
      expect(find.text(l.promoPreview), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      provider.dispose();
      country.dispose();
    });
  }
  testWidgets('filter edits stay local until Apply', (tester) async {
    final requests = <http.Request>[];
    final api = ApiService(
      client: MockClient((r) async {
        requests.add(r);
        if (r.url.path.contains('/countries/')) {
          return http.Response(jsonEncode([]), 200);
        }
        return http.Response(jsonEncode([promo()]), 200);
      }),
    );
    final country = CountryFilterProvider(apiService: api);
    final provider = PromosProvider(api: api, country: country);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: country),
        ],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: const PromosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Vienna');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(provider.city, isEmpty);
    expect(
      requests.any((r) => r.url.queryParameters['city'] == 'Vienna'),
      isFalse,
    );
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Vienna');
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(provider.city, 'Vienna');
    expect(requests.last.url.queryParameters['city'], 'Vienna');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
    country.dispose();
  });
}
