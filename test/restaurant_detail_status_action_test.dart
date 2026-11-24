import 'dart:convert';

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
import 'package:taybgoadmin/features/restaurants/restaurant_detail_screen.dart';

Map<String, dynamic> _restaurant(String status) => {
  'id': 7,
  'owner_user': 70,
  'name': 'Cafe Seven',
  'phone': '+4300000007',
  'status': status,
  'is_active': status == 'ACTIVE',
  'work_hours': {},
};

Widget _app(AdminProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RestaurantDetailScreen(restaurantId: 7),
    ),
  );
}

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  testWidgets(
    'active restaurant confirms before disabling and refetches its status',
    (tester) async {
      final requests = <http.Request>[];
      var detailCalls = 0;
      final provider = AdminProvider(
        apiService: ApiService(
          client: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/api/admin/restaurants/7/') {
              detailCalls++;
              return http.Response(
                jsonEncode(
                  _restaurant(detailCalls == 1 ? 'ACTIVE' : 'INACTIVE'),
                ),
                200,
              );
            }
            if (request.url.path == '/api/admin/restaurants/7/deactivate/') {
              return http.Response('', 200);
            }
            return http.Response('{}', 200);
          }),
        ),
      );

      await tester.pumpWidget(_app(provider));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('restaurant-disable-button')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('restaurant-disable-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('restaurant-disable-confirm')),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Existing orders will not be cancelled automatically.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('restaurant-disable-confirm')));
      await tester.pumpAndSettle();

      expect(requests.map((request) => request.url.path), [
        '/api/admin/restaurants/7/',
        '/api/admin/restaurants/7/deactivate/',
        '/api/admin/restaurants/7/',
      ]);
      expect(find.byKey(const Key('restaurant-enable-button')), findsOneWidget);
      expect(find.byKey(const Key('restaurant-disable-button')), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );

  testWidgets(
    'pending restaurant follows onboarding and has no toggle action',
    (tester) async {
      final provider = AdminProvider(
        apiService: ApiService(
          client: MockClient((request) async {
            if (request.url.path == '/api/admin/restaurants/7/') {
              return http.Response(jsonEncode(_restaurant('PENDING')), 200);
            }
            return http.Response('{}', 200);
          }),
        ),
      );

      await tester.pumpWidget(_app(provider));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsWidgets);
      expect(find.byKey(const Key('restaurant-disable-button')), findsNothing);
      expect(find.byKey(const Key('restaurant-enable-button')), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );
}
