import 'package:flutter_test/flutter_test.dart';
import 'package:taybgoadmin/core/providers/auth_provider.dart';
import 'package:taybgoadmin/core/router/app_router.dart';

class _AuthenticatedAuthProvider extends AuthProvider {
  _AuthenticatedAuthProvider() : super();

  @override
  bool get isAuthenticated => true;
}

class _UnauthenticatedAuthProvider extends AuthProvider {
  _UnauthenticatedAuthProvider() : super();

  @override
  bool get isAuthenticated => false;
}

void main() {
  test('driver detail route preserves management search state', () {
    final authProvider = _AuthenticatedAuthProvider();
    final router = AppRouter(authProvider: authProvider).router;

    router.go(
      '/management/drivers/42?tab=drivers&driver_filter=online&search=Jane%20Doe',
    );

    expect(
      router.routeInformationProvider.value.uri.path,
      '/management/drivers/42',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['search'],
      'Jane Doe',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['tab'],
      'drivers',
    );

    router.dispose();
    authProvider.dispose();
  });

  test('restaurant detail route is reachable as a nested management route', () {
    final authProvider = _AuthenticatedAuthProvider();
    final router = AppRouter(authProvider: authProvider).router;

    router.go(
      '/management/restaurants/7?tab=restaurants&search=Green%20Bistro',
    );

    expect(
      router.routeInformationProvider.value.uri.path,
      '/management/restaurants/7',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['search'],
      'Green Bistro',
    );

    router.dispose();
    authProvider.dispose();
  });

  test(
    'unknown notification destinations cannot become external redirects',
    () {
      final authProvider = _UnauthenticatedAuthProvider();
      final router = AppRouter(authProvider: authProvider).router;

      router.go('/sign-in?return_to=https%3A%2F%2Fevil.example');

      expect(router.routeInformationProvider.value.uri.path, '/sign-in');
      expect(router.routeInformationProvider.value.uri.queryParameters, {
        'return_to': 'https://evil.example',
      });

      router.dispose();
      authProvider.dispose();
    },
  );
}
