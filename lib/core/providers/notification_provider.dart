import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required ApiService apiService})
    : _apiService = apiService;

  final ApiService _apiService;

  List<AppNotification> _notifications = const [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  String? _actionError;
  Future<void>? _loadInFlight;
  AppNotificationDestination? _pendingNavigation;

  /// Set by the app shell so a push received before authentication can be
  /// held and replayed after sign-in.
  bool Function()? isAuthenticated;

  /// Navigation remains an app concern; this provider only emits a safe,
  /// already-validated destination.
  void Function(AppNotificationDestination destination)? onNavigationRequested;

  /// The root app uses this for a foreground banner/snackbar.
  void Function(ForegroundNotificationEvent event)? onForegroundNotification;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  String? get actionError => _actionError;
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  Future<void> loadNotifications() {
    final current = _loadInFlight;
    if (current != null) return current;

    final future = _loadNotifications();
    _loadInFlight = future;
    return future.whenComplete(() {
      if (identical(_loadInFlight, future)) _loadInFlight = null;
    });
  }

  Future<void> refresh() => loadNotifications();

  Future<void> _loadNotifications() async {
    final hadData = _notifications.isNotEmpty;
    _isLoading = !hadData;
    _isRefreshing = hadData;
    _error = null;
    notifyListeners();

    try {
      final items = await _apiService.getNotifications();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _notifications = List.unmodifiable(items);
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Connection error. Please try again.';
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<bool> markRead(int id) => _setRead(id, isRead: true);

  Future<bool> markUnread(int id) => _setRead(id, isRead: false);

  Future<bool> _setRead(int id, {required bool isRead}) async {
    if (id <= 0) return false;
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0) return false;

    final original = _notifications[index];
    if (original.isRead == isRead) return true;

    _actionError = null;
    _replaceAt(
      index,
      original.copyWith(
        isRead: isRead,
        readAt: isRead ? (original.readAt ?? DateTime.now()) : null,
        clearReadAt: !isRead,
      ),
    );
    notifyListeners();

    try {
      await _apiService.updateNotificationRead(id, isRead: isRead);
      return true;
    } on ApiException catch (error) {
      _actionError = error.message;
    } catch (_) {
      _actionError = 'Connection error. Please try again.';
    }

    final currentIndex = _notifications.indexWhere((item) => item.id == id);
    if (currentIndex >= 0) _replaceAt(currentIndex, original);
    notifyListeners();
    return false;
  }

  Future<bool> deleteNotification(int id) async {
    if (id <= 0) return false;
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0) return false;

    final deleted = _notifications[index];
    _actionError = null;
    final updated = List<AppNotification>.from(_notifications)..removeAt(index);
    _notifications = List.unmodifiable(updated);
    notifyListeners();

    try {
      await _apiService.deleteNotification(id);
      return true;
    } on ApiException catch (error) {
      _actionError = error.message;
    } catch (_) {
      _actionError = 'Connection error. Please try again.';
    }

    final restored = List<AppNotification>.from(_notifications)..add(deleted);
    restored.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _notifications = List.unmodifiable(restored);
    notifyListeners();
    return false;
  }

  /// Opens a notification from the list. The page never marks all items read
  /// just because it was opened; only this explicit action does so.
  Future<void> openNotification(AppNotification notification) async {
    if (!notification.isRead) await markRead(notification.id);
    _requestNavigation(notification.destination);
  }

  Future<void> openForegroundNotification(
    ForegroundNotificationEvent event,
  ) async {
    if (isAuthenticated?.call() ?? true) {
      await _markIncomingNotification(event.notification);
    }
    _requestNavigation(event.destination);
  }

  /// Refreshes the persisted list after a foreground push without navigating.
  void handleForegroundPush(RemoteMessage message) {
    final notification = AppNotification.fromRemoteMessage(message);
    unawaited(refresh());
    onForegroundNotification?.call(
      ForegroundNotificationEvent(
        notification: notification,
        destination: notification.destination,
      ),
    );
  }

  /// Handles both warm-app notification opens and the cold-start message.
  /// Navigation is deferred while logged out; the app shell replays it after
  /// authentication succeeds.
  Future<void> handleOpenedPush(RemoteMessage message) async {
    final notification = AppNotification.fromRemoteMessage(message);
    if (isAuthenticated?.call() ?? true) {
      await _markIncomingNotification(notification);
    }
    _requestNavigation(notification.destination);
  }

  AppNotificationDestination? takePendingNavigation() {
    final pending = _pendingNavigation;
    _pendingNavigation = null;
    return pending;
  }

  void clear() {
    _notifications = const [];
    _isLoading = false;
    _isRefreshing = false;
    _error = null;
    _actionError = null;
    _pendingNavigation = null;
    notifyListeners();
  }

  Future<void> _markIncomingNotification(AppNotification incoming) async {
    try {
      if (_notifications.isEmpty) await refresh();
      var match = _findMatching(incoming);
      if (match == null) {
        await refresh();
        match = _findMatching(incoming);
      }
      if (match != null && !match.isRead) await markRead(match.id);
    } catch (_) {
      // Opening a push must still reach its safe destination if the list or
      // read-state request is temporarily unavailable.
    }
  }

  AppNotification? _findMatching(AppNotification incoming) {
    for (final item in _notifications) {
      if (incoming.id > 0 && item.id == incoming.id) return item;
    }
    for (final item in _notifications) {
      if (incoming.type.isNotEmpty &&
          item.type.isNotEmpty &&
          incoming.type != item.type) {
        continue;
      }
      if (incoming.ticketId != null &&
          item.ticketId != null &&
          incoming.ticketId != item.ticketId) {
        continue;
      }
      final incomingMessageId = incoming.data['message_id'];
      final itemMessageId = item.data['message_id'];
      if (incomingMessageId != null &&
          itemMessageId != null &&
          incomingMessageId != itemMessageId) {
        continue;
      }
      if (incomingMessageId != null &&
          itemMessageId != null &&
          incomingMessageId == itemMessageId) {
        return item;
      }
      if (incoming.title == item.title && incoming.body == item.body) {
        return item;
      }
    }
    return null;
  }

  void _requestNavigation(AppNotificationDestination destination) {
    if (isAuthenticated != null && !isAuthenticated!()) {
      _pendingNavigation = destination;
      return;
    }
    final callback = onNavigationRequested;
    if (callback == null) {
      _pendingNavigation = destination;
      return;
    }
    callback(destination);
  }

  void _replaceAt(int index, AppNotification notification) {
    final updated = List<AppNotification>.from(_notifications)
      ..[index] = notification;
    _notifications = List.unmodifiable(updated);
  }
}
