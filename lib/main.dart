import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/admin_provider.dart';
import 'core/providers/country_filter_provider.dart';
import 'core/providers/pricing_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/public_config_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/models/app_notification.dart';
import 'core/router/app_router.dart';
import 'core/l10n/app_localizations.dart';
import 'core/widgets/required_update_gate.dart';
import 'firebase_options.dart';

Future<bool> _initializeFirebase() async {
  // The supplied Firebase project currently has Web and Android apps. Keep
  // unsupported native targets functional until their Firebase app config is
  // added rather than crashing during startup.
  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
    return false;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Firebase] TaybGo Admin Firebase initialized');
    return true;
  } catch (error, stackTrace) {
    debugPrint('[Firebase] Initialization failed (non-fatal): $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseEnabled = await _initializeFirebase();

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
  final notificationProvider = NotificationProvider(apiService: apiService);
  final pushNotificationService = firebaseEnabled
      ? PushNotificationService(apiService: apiService)
      : null;

  notificationProvider.isAuthenticated = () => authProvider.isAuthenticated;
  if (pushNotificationService != null) {
    pushNotificationService.onForegroundMessage =
        notificationProvider.handleForegroundPush;
    pushNotificationService.onNotificationOpened =
        notificationProvider.handleOpenedPush;
    await pushNotificationService.initialize();
  }
  authProvider.onAuthenticated = () async {
    await pushNotificationService?.registerCurrentToken();
    await notificationProvider.refresh();
  };

  authProvider.onSignedOut = () {
    adminProvider.clearAll();
    pricingProvider.clearAll();
    countryFilterProvider.clearAll();
    notificationProvider.clear();
  };
  apiService.onUnauthorized = () => authProvider.signOut();
  final settingsProvider = SettingsProvider();
  final publicConfigProvider = PublicConfigProvider(apiService: apiService);
  await Future.wait([
    authProvider.tryRestoreSession(),
    settingsProvider.loadSettings(),
    publicConfigProvider.load(notify: false),
  ]);

  // Session restoration does not pass through _completeAuthentication, so
  // explicitly register the browser/device token for an existing session.
  if (pushNotificationService != null && authProvider.isAuthenticated) {
    unawaited(pushNotificationService.registerCurrentToken());
  }
  if (authProvider.isAuthenticated) {
    unawaited(notificationProvider.loadNotifications());
  }

  runApp(
    TaybGoAdminApp(
      apiService: apiService,
      adminProvider: adminProvider,
      countryFilterProvider: countryFilterProvider,
      pricingProvider: pricingProvider,
      authProvider: authProvider,
      notificationProvider: notificationProvider,
      pushNotificationService: pushNotificationService,
      settingsProvider: settingsProvider,
      publicConfigProvider: publicConfigProvider,
    ),
  );
}

class TaybGoAdminApp extends StatefulWidget {
  final ApiService apiService;
  final AdminProvider adminProvider;
  final CountryFilterProvider countryFilterProvider;
  final PricingProvider pricingProvider;
  final AuthProvider authProvider;
  final NotificationProvider notificationProvider;
  final PushNotificationService? pushNotificationService;
  final SettingsProvider settingsProvider;
  final PublicConfigProvider publicConfigProvider;

  const TaybGoAdminApp({
    super.key,
    required this.apiService,
    required this.adminProvider,
    required this.countryFilterProvider,
    required this.pricingProvider,
    required this.authProvider,
    required this.notificationProvider,
    required this.pushNotificationService,
    required this.settingsProvider,
    required this.publicConfigProvider,
  });

  @override
  State<TaybGoAdminApp> createState() => _TaybGoAdminAppState();
}

class _TaybGoAdminAppState extends State<TaybGoAdminApp>
    with WidgetsBindingObserver {
  late final AppRouter _appRouter;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appRouter = AppRouter(authProvider: widget.authProvider);
    widget.notificationProvider.isAuthenticated = () =>
        widget.authProvider.isAuthenticated;
    widget.notificationProvider.onNavigationRequested =
        _handleNotificationNavigation;
    widget.notificationProvider.onForegroundNotification =
        _showForegroundNotification;
    widget.authProvider.addListener(_handleAuthStateChanged);

    final initialMessage = widget.pushNotificationService?.initialMessage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (initialMessage != null) {
        unawaited(widget.notificationProvider.handleOpenedPush(initialMessage));
      }
      _navigatePendingNotification();
    });
  }

  @override
  void dispose() {
    widget.authProvider.removeListener(_handleAuthStateChanged);
    widget.notificationProvider.onNavigationRequested = null;
    widget.notificationProvider.onForegroundNotification = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.authProvider.validateSession(forceRemote: true);
      if (widget.authProvider.isAuthenticated) {
        unawaited(widget.notificationProvider.refresh());
      }
    }
  }

  void _handleAuthStateChanged() {
    if (widget.authProvider.isAuthenticated) _navigatePendingNotification();
  }

  void _navigatePendingNotification() {
    if (!widget.authProvider.isAuthenticated) return;
    final destination = widget.notificationProvider.takePendingNavigation();
    if (destination == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.authProvider.isAuthenticated) {
        _appRouter.router.go(destination.path);
      }
    });
  }

  void _handleNotificationNavigation(AppNotificationDestination destination) {
    if (!widget.authProvider.isAuthenticated) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.authProvider.isAuthenticated) {
        _appRouter.router.go(destination.path);
      }
    });
  }

  void _showForegroundNotification(ForegroundNotificationEvent event) {
    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final localizationsContext = _scaffoldMessengerKey.currentContext;
    final l = localizationsContext == null
        ? null
        : AppLocalizations.of(localizationsContext);
    final title = event.notification.title.isEmpty
        ? (l?.notifications ?? 'Notifications')
        : event.notification.title;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            event.notification.body.isEmpty
                ? title
                : '$title\n${event.notification.body}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          action: SnackBarAction(
            label: l?.openNotification ?? 'Open',
            onPressed: () {
              unawaited(
                widget.notificationProvider.openForegroundNotification(event),
              );
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider.value(value: widget.adminProvider),
        ChangeNotifierProvider.value(value: widget.countryFilterProvider),
        ChangeNotifierProvider.value(value: widget.pricingProvider),
        ChangeNotifierProvider.value(value: widget.notificationProvider),
        ChangeNotifierProvider.value(value: widget.settingsProvider),
        ChangeNotifierProvider.value(value: widget.publicConfigProvider),
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
            scaffoldMessengerKey: _scaffoldMessengerKey,
            builder: (context, child) =>
                RequiredUpdateGate(child: child ?? const SizedBox.shrink()),
          );
        },
      ),
    );
  }
}
