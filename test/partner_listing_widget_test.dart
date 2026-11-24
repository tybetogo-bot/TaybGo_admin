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
import 'package:taybgoadmin/features/drivers/drivers_screen.dart';

Map<String, dynamic> _homeResponse() => {
  'drivers_with_locations': {
    'count': 1,
    'next': null,
    'previous': null,
    'results': [
      {
        'id': 1,
        'name': 'Online Driver',
        'phone': '+4300000001',
        'status': 'APPROVED',
        'is_online': true,
      },
    ],
  },
  'restaurants': {'count': 0, 'next': null, 'previous': null, 'results': []},
  'pending_drivers': {'count': 0, 'results': []},
  'pending_restaurants': {'count': 0, 'results': []},
  'orders_count_by_status': {},
  'drivers_count': {'online': 1, 'offline': 0},
};

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  testWidgets('uses a no-results message for an unmatched driver search', (
    tester,
  ) async {
    final provider = AdminProvider(
      apiService: ApiService(
        client: MockClient((request) async {
          if (request.url.path == '/api/admin/drivers/') {
            return http.Response(
              jsonEncode({
                'count': 1,
                'next': null,
                'previous': null,
                'results': [
                  {
                    'id': 1,
                    'user': {
                      'id': 1,
                      'name': 'Online Driver',
                      'phone': '+4300000001',
                    },
                    'status': 'APPROVED',
                    'is_online': true,
                  },
                ],
              }),
              200,
            );
          }
          return http.Response(jsonEncode(_homeResponse()), 200);
        }),
      ),
    );
    await provider.fetchHome();

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
          home: const DriversScreen(
            showHeader: false,
            showSearchToolbar: false,
            searchQuery: 'Restaurant',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No drivers match your filters'), findsOneWidget);
    expect(find.text('All drivers are currently offline'), findsNothing);

    provider.dispose();
  });
}
