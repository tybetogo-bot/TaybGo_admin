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
import 'package:taybgoadmin/features/management/add_user_screen.dart';

Future<void> _pumpScreen(
  WidgetTester tester, {
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
        initialRoute: '/add-user',
        routes: {
          '/': (_) => const Scaffold(body: Text('Done')),
          '/add-user': (_) => const AddUserScreen(),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _textFieldInside(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  testWidgets('requires an account type and mandatory user details', (
    tester,
  ) async {
    var posts = 0;
    await _pumpScreen(
      tester,
      client: MockClient((request) async {
        posts++;
        return http.Response('{}', 500);
      }),
    );

    await tester.tap(find.byKey(const Key('managed-form-submit')));
    await tester.pump();

    expect(posts, 0);
    expect(find.text('Select Driver or Restaurant.'), findsOneWidget);
    expect(find.text('This field is required.'), findsNWidgets(3));
  });

  testWidgets('shows compact driver and restaurant choices on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpScreen(
      tester,
      client: MockClient((_) async => http.Response('{}', 500)),
    );

    expect(find.byKey(const Key('add-user-role-driver')), findsOneWidget);
    expect(find.byKey(const Key('add-user-role-restaurant')), findsOneWidget);
    expect(find.text('Customer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('driver selection sends the driver API role', (tester) async {
    Map<String, dynamic>? posted;
    await _pumpScreen(
      tester,
      client: MockClient((request) async {
        posted = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 13,
            'name': 'Alex Driver',
            'phone': '+32470000001',
            'roles': ['driver'],
          }),
          201,
        );
      }),
    );

    await tester.tap(find.byKey(const Key('add-user-role-driver')));
    await tester.enterText(_textFieldInside('add-user-name'), 'Alex Driver');
    await tester.enterText(_textFieldInside('add-user-phone'), '+32470000001');
    await tester.ensureVisible(find.byKey(const Key('generate-password')));
    await tester.tap(find.byKey(const Key('generate-password')));
    await tester.ensureVisible(find.byKey(const Key('managed-form-submit')));
    await tester.tap(find.byKey(const Key('managed-form-submit')));
    await tester.pumpAndSettle();

    expect(posted?['role'], 'driver');
  });

  testWidgets('restaurant selection sends the seller API role', (tester) async {
    Map<String, dynamic>? posted;
    await _pumpScreen(
      tester,
      client: MockClient((request) async {
        posted = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 12,
            'name': 'Green Table',
            'phone': '+32470000000',
            'roles': ['seller'],
          }),
          201,
        );
      }),
    );

    await tester.tap(find.byKey(const Key('add-user-role-restaurant')));
    await tester.enterText(_textFieldInside('add-user-name'), 'Green Table');
    await tester.enterText(_textFieldInside('add-user-phone'), '+32470000000');
    await tester.ensureVisible(find.byKey(const Key('generate-password')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('generate-password')));
    await tester.pump();

    expect(find.byKey(const Key('copy-password')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('managed-form-submit')));
    await tester.tap(find.byKey(const Key('managed-form-submit')));
    await tester.pumpAndSettle();

    expect(posted?['name'], 'Green Table');
    expect(posted?['phone'], '+32470000000');
    expect(posted?['role'], 'seller');
    expect((posted?['password'] as String).length, 16);
  });
}
