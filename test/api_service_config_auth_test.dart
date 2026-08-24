import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

void main() {
  setUp(() => EnvConfig.init(env: Environment.prod));

  test(
    'public config passes semantic version and parses auth policy',
    () async {
      late http.Request captured;
      final api = ApiService(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'auth.otp_enabled_roles': ['customer'],
              'auth.password_only_roles': ['seller', 'driver', 'admin'],
              'app.latest_version': '1.0.0',
              'app.min_supported_version': '1.0.0',
              'app.force_update': false,
              'app.update_url': null,
              'legal.privacy_url': '/privacy-policy/',
              'legal.terms_url': '/terms-and-conditions/',
              'legal.support_url': '/contact/',
            }),
            200,
          );
        }),
      );

      final config = await api.getPublicConfig(currentVersion: '1.0.9');

      expect(captured.url.path, '/api/config/public');
      expect(captured.url.queryParameters['current_version'], '1.0.9');
      expect(captured.headers.containsKey('Cache-Control'), isFalse);
      expect(config.usesOtpFor('admin'), isFalse);
      expect(config.passwordOnlyRoles, contains('admin'));
    },
  );

  test('password login posts credentials and returns tokens', () async {
    late http.Request captured;
    final api = ApiService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'access': 'access-token', 'refresh': 'refresh-token'}),
          200,
        );
      }),
    );

    final tokens = await api.loginWithPassword(
      phone: '+15550000100',
      password: 'secret',
    );

    expect(captured.url.path, '/api/auth/token/');
    expect(jsonDecode(captured.body), {
      'phone': '+15550000100',
      'password': 'secret',
    });
    expect(tokens['access'], 'access-token');
  });

  test('OTP-disabled response preserves its machine-readable code', () async {
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail': 'OTP authentication is not enabled for this user type.',
            'code': 'otp_disabled_for_role',
          }),
          403,
        ),
      ),
    );

    expect(
      () => api.requestOtp('+15550000100', targetRole: 'admin'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'otp_disabled_for_role',
        ),
      ),
    );
  });

  test('admin settings list and patch use the documented endpoints', () async {
    final requests = <http.Request>[];
    final api = ApiService(
      client: MockClient((request) async {
        requests.add(request);
        final setting = {
          'key': 'app.force_update',
          'value': request.method == 'PATCH' ? true : false,
          'default_value': false,
          'description': 'Require clients to update.',
          'is_public': true,
          'is_overridden': request.method == 'PATCH',
        };
        return http.Response(
          jsonEncode(request.method == 'PATCH' ? setting : [setting]),
          200,
        );
      }),
    );
    api.setAuthToken('admin-token');

    final settings = await api.getAppSettings();
    final updated = await api.updateAppSetting('app.force_update', true);

    expect(settings.single.value, isFalse);
    expect(updated.value, isTrue);
    expect(requests.first.url.path, '/api/admin/app-settings/');
    expect(requests.last.url.path, '/api/admin/app-settings/app.force_update/');
    expect(requests.last.headers['Authorization'], 'Bearer admin-token');
    expect(jsonDecode(requests.last.body), {'value': true});
  });
}
