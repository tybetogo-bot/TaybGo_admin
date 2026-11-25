import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/l10n/app_localizations.dart';
import 'package:taybgoadmin/core/models/admin_order.dart';
import 'package:taybgoadmin/core/models/home_response.dart';
import 'package:taybgoadmin/core/providers/admin_provider.dart';
import 'package:taybgoadmin/core/providers/auth_provider.dart';
import 'package:taybgoadmin/core/router/app_router.dart';
import 'package:taybgoadmin/core/services/api_service.dart';
import 'package:taybgoadmin/features/exports/monthly_exports_screen.dart';
import 'package:taybgoadmin/features/gift_cards/admin_gift_cards_screen.dart';
import 'package:taybgoadmin/features/management/managed_entity_form_support.dart';
import 'package:taybgoadmin/features/restaurants/restaurant_detail_screen.dart';

class _Auth extends AuthProvider {
  @override
  bool get isAuthenticated => true;
}

Widget _wrapWithApp(AdminProvider provider, Widget home) {
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
      home: home,
    ),
  );
}

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  group('Phase 3 Admin models and email normalization', () {
    test('parses store_type, min_order_amount, pickup, splits, and attachments', () {
      final restaurant = HomeRestaurant.fromJson({
        'id': 5,
        'owner_user': 55,
        'name': 'Vienna Market',
        'phone': '+43123456',
        'status': 'ACTIVE',
        'store_type': 'GENERAL_MARKET',
        'min_order_amount': '18.50',
        'work_hours': {},
      });
      expect(restaurant.isGeneralMarket, isTrue);
      expect(restaurant.minOrderAmount, '18.50');
      expect(restaurant.formattedMinOrderAmount, '€18.50');

      final pending = PendingRestaurant.fromJson({
        'id': 6,
        'name': 'Pending Market',
        'status': 'PENDING',
        'store_type': 'GENERAL_MARKET',
        'min_order_amount': '12.00',
      });
      expect(pending.isGeneralMarket, isTrue);
      expect(pending.minOrderValue, 12.0);

      final order = AdminOrder.fromJson({
        'id': 300,
        'order_type': 'FOOD',
        'fulfillment_type': 'PICKUP',
        'payment_type': 'CASH',
        'status': 'ACCEPTED',
        'is_manual': false,
        'is_paid': false,
        'total_amount': '28.00',
        'gift_card_amount_applied': '10.00',
        'card_amount_due': '0.00',
        'cash_amount_due': '18.00',
        'attachments': [
          {
            'id': 'att-1',
            'file_name': 'list.pdf',
            'content_type': 'application/pdf',
            'byte_size': 1234,
            'download_url': 'https://cdn.example.com/signed.pdf',
          },
        ],
      });
      expect(order.isPickup, isTrue);
      expect(order.hasGiftCardApplied, isTrue);
      expect(order.hasCashDue, isTrue);
      expect(order.hasCardDue, isFalse);
      expect(order.attachments.single.downloadUrl, contains('signed.pdf'));
    });

    test('normalizes user email and supports long TLDs', () {
      final payload = buildManagedUserPayload(
        name: ' Owner ',
        phone: '+43660111222',
        email: '  Owner.Name@Domain.Museum  ',
      );
      expect(payload['email'], 'owner.name@domain.museum');

      final errs = ManagedEntityValidation.validateCommon(
        name: 'Owner',
        phone: '+43660111222',
        email: 'owner@domain.museum',
        label: 'Main',
        latitude: '48.2',
        longitude: '16.3',
        fullAddress: 'Street 1',
        city: 'Vienna',
        country: 'Austria',
        requiredMessage: 'req',
        invalidPhoneMessage: 'phone',
        invalidEmailMessage: 'email',
        invalidLatitudeMessage: 'lat',
        invalidLongitudeMessage: 'lng',
      );
      expect(errs, isEmpty);
    });
  });

  group('Phase 3 Admin ApiService contracts', () {
    test('monthly export list + generate and gift card endpoints match backend', () async {
      final requests = <http.Request>[];
      final api = ApiService(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/admin/exports/monthly/') {
            return http.Response(
              jsonEncode([
                {
                  'id': 1,
                  'restaurant': 7,
                  'restaurant_name': 'Market 7',
                  'restaurant_store_type': 'GENERAL_MARKET',
                  'year': 2026,
                  'month': 10,
                  'status': 'COMPLETED',
                  'file_format': 'PDF',
                  'row_count': 42,
                  'summary_json': {'gross_sales': '1420.50'},
                  'download_url': 'https://cdn.example.com/oct.pdf',
                },
              ]),
              200,
            );
          }
          if (request.url.path == '/api/admin/exports/monthly/generate/') {
            return http.Response(
              jsonEncode({
                'year': 2026,
                'month': 10,
                'created_count': 3,
                'skipped_count': 0,
              }),
              200,
            );
          }
          if (request.url.path == '/api/admin/gift-cards/') {
            return http.Response(
              jsonEncode({
                'count': 1,
                'results': [
                  {
                    'id': 9,
                    'masked_code': 'TBG-****-9999',
                    'initial_amount': '50.00',
                    'balance': '35.00',
                    'currency': 'EUR',
                    'status': 'ACTIVE',
                    'is_claimed': true,
                  },
                ],
              }),
              200,
            );
          }
          if (request.url.path == '/api/admin/gift-cards/issue/') {
            return http.Response(
              jsonEncode({
                'id': 10,
                'code': 'TBG-NEW-CODE-1234',
                'balance': '25.00',
                'currency': 'EUR',
                'status': 'ACTIVE',
                'owned_by': null,
              }),
              201,
            );
          }
          if (request.url.path == '/api/admin/gift-cards/9/adjust/') {
            return http.Response(
              jsonEncode({
                'id': 9,
                'status': 'ACTIVE',
                'balance': '40.00',
                'currency': 'EUR',
                'masked_code': 'TBG-****-9999',
              }),
              200,
            );
          }
          if (request.url.path == '/api/admin/gift-cards/9/void/') {
            return http.Response(
              jsonEncode({
                'id': 9,
                'status': 'VOID',
                'balance': '0.00',
                'currency': 'EUR',
                'masked_code': 'TBG-****-9999',
              }),
              200,
            );
          }
          return http.Response('{}', 200);
        }),
      );

      final exports = await api.getMonthlyStoreExports(
        year: 2026,
        month: 10,
        storeType: 'GENERAL_MARKET',
      );
      expect(exports.single.restaurantName, 'Market 7');
      expect(requests.last.url.queryParameters['store_type'], 'GENERAL_MARKET');

      final gen = await api.generateMonthlyStoreExports(year: 2026, month: 10);
      expect(gen.batchSummary?['created_count'], 3);

      final cards = await api.getAdminGiftCards(search: '9999', status: 'ACTIVE');
      expect(cards.single.balance, '35.00');

      final issued = await api.issueAdminGiftCard(amount: '25.00');
      expect(issued.code, 'TBG-NEW-CODE-1234');

      final adjusted = await api.adjustAdminGiftCard(
        9,
        deltaAmount: '5.00',
        reason: 'Support credit',
      );
      expect(adjusted.balance, '40.00');

      final voided = await api.voidAdminGiftCard(9, reason: 'Fraud');
      expect(voided.status, 'VOID');
    });
  });

  group('Phase 3 Admin screens and router', () {
    testWidgets('MonthlyExportsScreen lists exports and submits generate', (
      tester,
    ) async {
      Map<String, dynamic>? generatePayload;
      final provider = AdminProvider(
        apiService: ApiService(
          client: MockClient((request) async {
            if (request.url.path == '/api/admin/exports/monthly/') {
              return http.Response(
                jsonEncode([
                  {
                    'id': 1,
                    'restaurant': 7,
                    'restaurant_name': 'Market Seven',
                    'restaurant_store_type': 'GENERAL_MARKET',
                    'year': 2026,
                    'month': 10,
                    'status': 'COMPLETED',
                    'file_format': 'PDF',
                    'row_count': 12,
                    'summary_json': {'gross_sales': '320.00'},
                    'download_url': 'https://cdn.example.com/m7.pdf',
                  },
                ]),
                200,
              );
            }
            if (request.url.path == '/api/admin/exports/monthly/generate/') {
              generatePayload = jsonDecode(request.body) as Map<String, dynamic>;
              return http.Response(
                jsonEncode({'year': 2026, 'month': 10, 'created_count': 1}),
                200,
              );
            }
            return http.Response('{}', 200);
          }),
        ),
      );

      await tester.pumpWidget(
        _wrapWithApp(provider, const MonthlyExportsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Market Seven (#7)'), findsOneWidget);
      expect(find.text('Open PDF'), findsOneWidget);

      await tester.tap(find.byKey(const Key('generate-monthly-export-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('generate-monthly-export-confirm')));
      await tester.pumpAndSettle();

      expect(generatePayload, isNotNull);
    });

    testWidgets('AdminGiftCardsScreen lists cards and issues full code dialog', (
      tester,
    ) async {
      final provider = AdminProvider(
        apiService: ApiService(
          client: MockClient((request) async {
            if (request.url.path == '/api/admin/gift-cards/') {
              return http.Response(
                jsonEncode([
                  {
                    'id': 2,
                    'masked_code': 'TBG-****-2222',
                    'initial_amount': '30.00',
                    'balance': '30.00',
                    'currency': 'EUR',
                    'status': 'ACTIVE',
                    'is_claimed': false,
                  },
                ]),
                200,
              );
            }
            if (request.url.path == '/api/admin/gift-cards/issue/') {
              return http.Response(
                jsonEncode({
                  'id': 3,
                  'code': 'TBG-ISSUED-3333',
                  'balance': '25.00',
                  'currency': 'EUR',
                  'status': 'ACTIVE',
                  'owned_by': null,
                }),
                201,
              );
            }
            return http.Response('{}', 200);
          }),
        ),
      );

      await tester.pumpWidget(
        _wrapWithApp(provider, const AdminGiftCardsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('TBG-****-2222'), findsOneWidget);

      await tester.tap(find.byKey(const Key('issue-gift-card-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('issue-gift-card-submit')));
      await tester.pumpAndSettle();

      expect(find.text('TBG-ISSUED-3333'), findsOneWidget);
    });

    testWidgets('RestaurantDetailScreen edits store_type and min_order_amount', (
      tester,
    ) async {
      Map<String, dynamic>? patched;
      var currentType = 'RESTAURANT';
      var currentMin = '0.00';
      final provider = AdminProvider(
        apiService: ApiService(
          client: MockClient((request) async {
            if (request.url.path == '/api/admin/restaurants/7/' &&
                request.method == 'PATCH') {
              patched = jsonDecode(request.body) as Map<String, dynamic>;
              currentType = patched!['restaurant']['store_type'] as String;
              currentMin = patched!['restaurant']['min_order_amount'] as String;
            }
            if (request.url.path == '/api/admin/restaurants/7/') {
              return http.Response(
                jsonEncode({
                  'id': 7,
                  'owner_user': 70,
                  'name': 'Cafe Seven',
                  'phone': '+4300000007',
                  'status': 'ACTIVE',
                  'is_active': true,
                  'store_type': currentType,
                  'min_order_amount': currentMin,
                  'work_hours': {},
                }),
                200,
              );
            }
            return http.Response('{}', 200);
          }),
        ),
      );

      await tester.pumpWidget(
        _wrapWithApp(provider, const RestaurantDetailScreen(restaurantId: 7)),
      );
      await tester.pumpAndSettle();

      final editBtn = find.byKey(const Key('restaurant-edit-store-settings'));
      await tester.ensureVisible(editBtn);
      await tester.pumpAndSettle();
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit-min-order-input')),
        '15.00',
      );
      await tester.tap(find.byKey(const Key('edit-store-settings-save')));
      await tester.pumpAndSettle();

      expect(patched?['restaurant']['min_order_amount'], '15.00');
      expect(find.text('€15.00'), findsWidgets);
    });

    test('router registers /exports and /gift-cards routes', () {
      final auth = _Auth();
      final router = AppRouter(authProvider: auth).router;

      router.go('/exports?restaurant_id=7');
      expect(router.routeInformationProvider.value.uri.path, '/exports');

      router.go('/gift-cards');
      expect(router.routeInformationProvider.value.uri.path, '/gift-cards');

      router.dispose();
      auth.dispose();
    });
  });
}
