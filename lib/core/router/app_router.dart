import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/otp_verify_screen.dart';
import '../../features/shell/admin_shell.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/approvals/approvals_screen.dart';
import '../../features/approvals/driver_request_detail_screen.dart';
import '../../features/approvals/restaurant_request_detail_screen.dart';
import '../../features/management/management_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/restaurants/restaurant_detail_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/support/ticket_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/preferences_screen.dart';
import '../../features/profile/version_control_screen.dart';
import '../../core/models/pricing_policy.dart';
import '../../features/pricing/pricing_screen.dart';
import '../../features/pricing/pricing_policy_detail_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter({required this.authProvider});

  late final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/sign-in' || loc == '/verify-otp';

      if (!isAuthenticated && !isAuthRoute) return '/sign-in';
      if (isAuthenticated && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => const OtpVerifyScreen(),
      ),
      GoRoute(
        path: '/drivers',
        redirect: (context, state) {
          final filter = state.uri.queryParameters['filter'] ?? 'all';
          return '/management?tab=drivers&driver_filter=$filter';
        },
      ),
      GoRoute(
        path: '/restaurants',
        redirect: (context, state) {
          final filter = state.uri.queryParameters['filter'] ?? 'all';
          return '/management?tab=restaurants&restaurant_filter=$filter';
        },
        routes: [
          GoRoute(
            path: ':id',
            redirect: (context, state) =>
                '/management/restaurants/${state.pathParameters['id']}',
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/approvals',
                builder: (context, state) => const ApprovalsScreen(),
                routes: [
                  GoRoute(
                    path: 'driver/:id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      final name = state.uri.queryParameters['name'] ?? '';
                      final phone = state.uri.queryParameters['phone'] ?? '';
                      return DriverRequestDetailScreen(
                        driverId: id,
                        driverName: name,
                        driverPhone: phone,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'restaurant/:id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      final name = state.uri.queryParameters['name'] ?? '';
                      return RestaurantRequestDetailScreen(
                        restaurantId: id,
                        restaurantName: name,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/management',
                builder: (context, state) => ManagementScreen(
                  initialTab: state.uri.queryParameters['tab'] ?? 'drivers',
                  driverFilter:
                      state.uri.queryParameters['driver_filter'] ??
                      state.uri.queryParameters['filter'] ??
                      'all',
                  restaurantFilter:
                      state.uri.queryParameters['restaurant_filter'] ??
                      state.uri.queryParameters['filter'] ??
                      'all',
                ),
                routes: [
                  GoRoute(
                    path: 'restaurants/:id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return RestaurantDetailScreen(restaurantId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return OrderDetailScreen(orderId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'pricing-policies',
                    builder: (context, state) =>
                        const PricingScreen(showBackButton: true),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) =>
                            const PricingPolicyFormPage(),
                      ),
                      GoRoute(
                        path: ':id/edit',
                        builder: (context, state) {
                          final id = int.parse(state.pathParameters['id']!);
                          final extra = state.extra;
                          return PricingPolicyFormPage(
                            policyId: id,
                            initialPolicy: extra is PricingPolicy
                                ? extra
                                : null,
                          );
                        },
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = int.parse(state.pathParameters['id']!);
                          return PricingPolicyDetailScreen(policyId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'preferences',
                    builder: (context, state) => const PreferencesScreen(),
                    routes: [
                      GoRoute(
                        path: 'version-control',
                        builder: (context, state) =>
                            const VersionControlScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/support',
                builder: (context, state) => const SupportScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return TicketDetailScreen(ticketId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
