import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/admin_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final authProvider = AuthProvider(apiService: apiService);
  final settingsProvider = SettingsProvider();
  await Future.wait([
    authProvider.tryRestoreSession(),
    settingsProvider.loadSettings(),
  ]);

  runApp(TaybGoAdminApp(
    apiService: apiService,
    authProvider: authProvider,
    settingsProvider: settingsProvider,
  ));
}

class TaybGoAdminApp extends StatefulWidget {
  final ApiService apiService;
  final AuthProvider authProvider;
  final SettingsProvider settingsProvider;

  const TaybGoAdminApp({
    super.key,
    required this.apiService,
    required this.authProvider,
    required this.settingsProvider,
  });

  @override
  State<TaybGoAdminApp> createState() => _TaybGoAdminAppState();
}

class _TaybGoAdminAppState extends State<TaybGoAdminApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(authProvider: widget.authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider(
            create: (_) => AdminProvider(apiService: widget.apiService)),
        ChangeNotifierProvider.value(value: widget.settingsProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: 'TaybGo Admin',
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
