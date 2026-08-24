import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taybgoadmin/core/config/env_config.dart';
import 'package:taybgoadmin/core/services/api_service.dart';

void main() {
  setUp(() => EnvConfig.init(env: Environment.dev));

  test('createDriver posts the admin payload and parses 201', () async {
    late http.Request captured;
    final api = ApiService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'id': 41, 'status': 'APPROVED'}), 201);
      }),
    )..setAuthToken('admin-token');
    final payload = {
      'user': {'name': 'Alex Driver', 'phone': '+32470000000'},
      'address': {
        'label': 'home',
        'lat': '50.850346',
        'lng': '4.351721',
        'full_address': 'Central Brussels',
        'city': 'Brussels',
        'country': 'Belgium',
      },
      'profile': {'vehicle_type': 'BIKE'},
    };

    final result = await api.createDriver(payload);

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/admin/drivers/');
    expect(captured.headers['authorization'], 'Bearer admin-token');
    expect(jsonDecode(captured.body), payload);
    expect(result['id'], 41);
  });

  test('createRestaurant posts the admin payload and parses 201', () async {
    late http.Request captured;
    final api = ApiService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'id': 73, 'status': 'ACTIVE'}), 201);
      }),
    );
    final payload = {
      'user': {'name': 'Sam Owner', 'phone': '+32471111111'},
      'address': {
        'label': 'restaurant',
        'lat': '50.850346',
        'lng': '4.351721',
        'full_address': 'Grand Place',
        'city': 'Brussels',
        'country': 'Belgium',
      },
      'restaurant': {'name': 'Green Table', 'phone': '+3220000000'},
    };

    final result = await api.createRestaurant(payload);

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/admin/restaurants/');
    expect(jsonDecode(captured.body), payload);
    expect(result['id'], 73);
  });

  test('createUser posts the account payload and parses 201', () async {
    late http.Request captured;
    final api = ApiService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'id': 91,
            'name': 'Green Table',
            'phone': '+32472222222',
            'roles': ['seller'],
          }),
          201,
        );
      }),
    )..setAuthToken('admin-token');
    final payload = {
      'phone': '+32472222222',
      'password': 'StrongPassword123!',
      'role': 'seller',
      'name': 'Green Table',
    };

    final result = await api.createUser(payload);

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/admin/users/');
    expect(captured.headers['authorization'], 'Bearer admin-token');
    expect(jsonDecode(captured.body), payload);
    expect(result['roles'], ['seller']);
  });

  test('createUser exposes duplicate-phone conflicts', () async {
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'A user with this phone already exists.'}),
          409,
        ),
      ),
    );

    await expectLater(
      api.createUser(const {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having(
              (error) => error.message,
              'message',
              contains('already exists'),
            ),
      ),
    );
  });

  test('resetUserPassword patches the user password endpoint', () async {
    late http.Request captured;
    final api = ApiService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'detail': 'Password updated.'}), 200);
      }),
    )..setAuthToken('admin-token');

    await api.resetUserPassword(userId: 42, password: 'NewStrongPassword123!');

    expect(captured.method, 'PATCH');
    expect(captured.url.path, '/api/admin/users/42/password/');
    expect(captured.headers['authorization'], 'Bearer admin-token');
    expect(jsonDecode(captured.body), {'password': 'NewStrongPassword123!'});
  });

  test('nested API validation errors are flattened for form fields', () async {
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'user': {
              'phone': ['A user with this phone already exists.'],
            },
            'address': {
              'lat': ['Ensure this value is valid.'],
            },
          }),
          400,
        ),
      ),
    );

    try {
      await api.createDriver(const {});
      fail('Expected ApiException');
    } on ApiException catch (error) {
      expect(error.statusCode, 400);
      expect(
        error.fieldErrors['user.phone'],
        'A user with this phone already exists.',
      );
      expect(error.fieldErrors['address.lat'], 'Ensure this value is valid.');
    }
  });

  test('create endpoints trigger unauthorized callback on 401', () async {
    var unauthorized = false;
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail': 'Authentication credentials were not provided.',
          }),
          401,
        ),
      ),
    )..onUnauthorized = () => unauthorized = true;

    await expectLater(
      api.createRestaurant(const {}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
    expect(unauthorized, isTrue);
  });
}
