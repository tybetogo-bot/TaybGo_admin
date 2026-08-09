import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/admin_provider.dart';
import 'core/providers/country_filter_provider.dart';
import 'core/providers/pricing_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Default to prod if main.dart is run directly
  try {
    EnvConfig.baseUrl;
  } catch (_) {
    EnvConfig.init(env: Environment.prod);
  }

  final apiService = ApiService();
  final countryFilterProvider = CountryFilterProvider(apiService: apiService);
  final adminProvider = AdminProvider(
    apiService: apiService,
    countryFilter: countryFilterProvider,
  );
  final pricingProvider = PricingProvider(
    apiService: apiService,
    countryFilter: countryFilterProvider,
  );
  final authProvider = AuthProvider(apiService: apiService);
  authProvider.onSignedOut = () {
    adminProvider.clearAll();
    pricingProvider.clearAll();
    countryFilterProvider.clearAll();
  };
  apiService.onUnauthorized = () => authProvider.signOut();
  final settingsProvider = SettingsProvider();
  await Future.wait([
    authProvider.tryRestoreSession(),
    settingsProvider.loadSettings(),
  ]);

  runApp(
    TaybGoAdminApp(
      apiService: apiService,
      adminProvider: adminProvider,
      countryFilterProvider: countryFilterProvider,
      pricingProvider: pricingProvider,
      authProvider: authProvider,
      settingsProvider: settingsProvider,
    ),
  );
}

class TaybGoAdminApp extends StatefulWidget {
  final ApiService apiService;
  final AdminProvider adminProvider;
  final CountryFilterProvider countryFilterProvider;
  final PricingProvider pricingProvider;
  final AuthProvider authProvider;
  final SettingsProvider settingsProvider;

  const TaybGoAdminApp({
    super.key,
    required this.apiService,
    required this.adminProvider,
    required this.countryFilterProvider,
    required this.pricingProvider,
    required this.authProvider,
    required this.settingsProvider,
  });

  @override
  State<TaybGoAdminApp> createState() => _TaybGoAdminAppState();
}

class _TaybGoAdminAppState extends State<TaybGoAdminApp>
    with WidgetsBindingObserver {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appRouter = AppRouter(authProvider: widget.authProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.authProvider.validateSession(forceRemote: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider.value(value: widget.adminProvider),
        ChangeNotifierProvider.value(value: widget.countryFilterProvider),
        ChangeNotifierProvider.value(value: widget.pricingProvider),
        ChangeNotifierProvider.value(value: widget.settingsProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: EnvConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
