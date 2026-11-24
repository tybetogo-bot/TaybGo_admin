import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:taybgoadmin/core/l10n/app_localizations.dart';
import 'package:taybgoadmin/core/models/pricing_policy.dart';
import 'package:taybgoadmin/core/providers/pricing_provider.dart';
import 'package:taybgoadmin/core/services/api_service.dart';
import 'package:taybgoadmin/features/pricing/pricing_screen.dart';

ApiService _testApi() {
  return ApiService(
    client: MockClient((request) async {
      if (request.url.path.endsWith('/countries/')) {
        return http.Response(
          jsonEncode({
            'count': 1,
            'next': null,
            'previous': null,
            'results': [
              {'id': 7, 'name': 'Belgium', 'iso_code': 'BE', 'is_active': true},
            ],
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/cities/')) {
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
                'name': 'Brussels',
                'is_active': true,
              },
            ],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({'count': 0, 'next': null, 'previous': null, 'results': []}),
        200,
      );
    }),
  );
}

Future<void> _pumpForm(WidgetTester tester, {PricingPolicy? policy}) async {
  final provider = PricingProvider(apiService: _testApi());

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
        home: PricingPolicyFormPage(initialPolicy: policy),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the add pricing policy page', (tester) async {
    await _pumpForm(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Create pricing policy'), findsOneWidget);
    expect(find.text('Global'), findsNothing);
    expect(find.text('Shipping'), findsNothing);
    expect(find.text('Bike'), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.text('EUR'), findsWidgets);
    expect(find.text('Version'), findsNothing);
  });

  testWidgets('renders the edit pricing policy page', (tester) async {
    await _pumpForm(
      tester,
      policy: PricingPolicy(
        id: 1,
        name: 'Brussels bike pricing',
        scope: 'CITY',
        cityId: 4,
        orderType: 'SHIPPING',
        vehicleType: 'BIKE',
        baseAmount: '5.00',
        baseDistance: '2.00',
        perKmRate: '1.25',
        weightMultiplier: '0.50',
        currency: 'EUR',
        version: 1,
        isActive: true,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Edit pricing policy'), findsOneWidget);
  });
}
