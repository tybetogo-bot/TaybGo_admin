import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'api_service.dart';

/// Firebase receives background messages outside the Flutter widget tree.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint('[FCM] Background message received: ${message.messageId}');
}

/// Initializes FCM, requests permission, and registers the current token with
/// the authenticated admin account.
class PushNotificationService {
  PushNotificationService({required ApiService apiService})
    : _apiService = apiService,
      _messaging = FirebaseMessaging.instance;

  final ApiService _apiService;
  final FirebaseMessaging _messaging;

  bool _initialized = false;
  Future<String?>? _registrationInFlight;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  RemoteMessage? _initialMessage;

  /// Optional hook for refreshing an in-app notification surface.
  void Function(RemoteMessage message)? onForegroundMessage;
  void Function(RemoteMessage message)? onNotificationOpened;

  RemoteMessage? get initialMessage => _initialMessage;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) {
      debugPrint(
        '[FCM] Foreground message received: '
        '${message.notification?.title ?? message.messageId}',
      );
      onForegroundMessage?.call(message);
    });

    _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      debugPrint('[FCM] Notification opened: ${message.messageId}');
      onNotificationOpened?.call(message);
    });

    try {
      _initialMessage = await _messaging.getInitialMessage();
      if (_initialMessage != null) {
        debugPrint(
          '[FCM] Initial notification received: ${_initialMessage!.messageId}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[FCM] Initial notification lookup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    // The web implementation currently exposes a no-op refresh stream, while
    // Android/iOS use it to keep the backend registration current.
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      _registerRefreshedToken,
    );
  }

  /// Requests permission, obtains the current FCM token, and registers it.
  /// Calling this repeatedly is safe and also re-associates the token after a
  /// different admin signs in on the same browser/device.
  Future<String?> registerCurrentToken() {
    final inFlight = _registrationInFlight;
    if (inFlight != null) return inFlight;

    final future = _registerCurrentToken();
    _registrationInFlight = future;
    return future.whenComplete(() {
      if (identical(_registrationInFlight, future)) {
        _registrationInFlight = null;
      }
    });
  }

  Future<String?> _registerCurrentToken() async {
    try {
      final permission = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final authorized =
          permission.authorizationStatus == AuthorizationStatus.authorized ||
          permission.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) {
        debugPrint('[FCM] Notification permission was not granted');
        return null;
      }

      final configuredVapidKey = const String.fromEnvironment(
        'FCM_WEB_VAPID_KEY',
      );
      final token = await _messaging.getToken(
        vapidKey: kIsWeb && configuredVapidKey.isNotEmpty
            ? configuredVapidKey
            : null,
      );
      if (token == null || token.isEmpty) {
        debugPrint('[FCM] No registration token was returned');
        return null;
      }

      await _registerToken(token);
      return token;
    } catch (error, stackTrace) {
      debugPrint('[FCM] Token registration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> _registerRefreshedToken(String token) async {
    try {
      await _registerToken(token);
    } catch (error, stackTrace) {
      debugPrint('[FCM] Refreshed token registration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _registerToken(String token) async {
    final deviceType = kIsWeb
        ? 'web'
        : defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    await _apiService.registerDeviceToken(token: token, deviceType: deviceType);
    debugPrint('[FCM] Device token registered ($deviceType)');
  }

  Future<void> dispose() async {
    await _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;
    await _openedMessageSubscription?.cancel();
    _openedMessageSubscription = null;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
