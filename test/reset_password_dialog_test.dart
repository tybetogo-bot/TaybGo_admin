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
import 'package:taybgoadmin/features/management/reset_password_dialog.dart';

Future<void> _pumpDialog(
  WidgetTester tester, {
  required MockClient client,
  int userId = 42,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AdminProvider(apiService: ApiService(client: client)),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ResetPasswordDialog(userId: userId)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  testWidgets('generated password patches the selected user', (tester) async {
    late http.Request captured;
    Map<String, dynamic>? posted;
    await _pumpDialog(
      tester,
      client: MockClient((request) async {
        captured = request;
        posted = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'detail': 'Password updated.'}), 200);
      }),
    );

    await tester.ensureVisible(
      find.byKey(const Key('reset-generate-password')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-generate-password')));
    await tester.pump();
    expect(find.byKey(const Key('reset-copy-password')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reset-password-submit')));
    await tester.pumpAndSettle();

    expect(captured.method, 'PATCH');
    expect(captured.url.path, '/api/admin/users/42/password/');
    expect(posted?.keys, ['password']);
    expect((posted?['password'] as String).length, 16);
  });

  testWidgets('manual passwords must match before reset is submitted', (
    tester,
  ) async {
    var posts = 0;
    await _pumpDialog(
      tester,
      client: MockClient((request) async {
        posts++;
        return http.Response('{}', 200);
      }),
    );

    await tester.enterText(
      find.byKey(const Key('reset-password-new')),
      'StrongPassword123!',
    );
    await tester.enterText(
      find.byKey(const Key('reset-password-confirm')),
      'DifferentPassword123!',
    );
    await tester.tap(find.byKey(const Key('reset-password-submit')));
    await tester.pump();

    expect(posts, 0);
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });
}
