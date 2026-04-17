import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/auth/auth_error_keys.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

void main() {
  setUp(() {
    EnvConfig.init(env: Environment.prod);
  });

  test('requestOtp sends target_role=admin', () async {
    Uri? capturedUri;
    Map<String, dynamic>? capturedBody;

    final api = ApiService(
      client: MockClient((request) async {
        capturedUri = request.url;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'otp': '123456'}), 200);
      }),
    );

    final response = await api.requestOtp('555123456', targetRole: 'admin');

    expect(capturedUri?.path, '/api/auth/otp/request/');
    expect(
      capturedBody,
      equals({'phone': '555123456', 'target_role': 'admin'}),
    );
    expect(response, equals({'otp': '123456'}));
  });

  test('verifyOtp sends target_role=admin', () async {
    Uri? capturedUri;
    Map<String, dynamic>? capturedBody;

    final api = ApiService(
      client: MockClient((request) async {
        capturedUri = request.url;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'refresh': 'refresh-token', 'access': 'access-token'}),
          200,
        );
      }),
    );

    final tokens = await api.verifyOtp(
      '555123456',
      '999999',
      targetRole: 'admin',
    );

    expect(capturedUri?.path, '/api/auth/otp/verify/');
    expect(
      capturedBody,
      equals({'phone': '555123456', 'code': '999999', 'target_role': 'admin'}),
    );
    expect(
      tokens,
      equals({'refresh': 'refresh-token', 'access': 'access-token'}),
    );
  });

  test('requestOtp maps backend conflict detail to the generic key', () async {
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail':
                'A user with this phone number already exists for another role.',
          }),
          409,
        ),
      ),
    );

    expect(
      () => api.requestOtp('555123456', targetRole: 'admin'),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.message,
              'message',
              AuthErrorKeys.phoneAlreadyRegistered,
            )
            .having((error) => error.statusCode, 'statusCode', 409),
      ),
    );
  });
}
