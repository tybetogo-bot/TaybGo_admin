import 'package:firebase_messaging/firebase_messaging.dart';

const supportNotificationTypes = <String>{
  'support_ticket_created',
  'support_message_from_requester',
  'support_ticket_assigned',
};

class AppNotification {
  final int id;
  final String title;
  final String body;
  final Map<String, String> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.data = const {},
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: positiveInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: _stringMap(json['data']),
      isRead: _boolValue(json['is_read']),
      readAt: _dateValue(json['read_at']),
      createdAt: _dateValue(json['created_at']) ?? DateTime.now(),
    );
  }

  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    final data = _stringMap(message.data);
    return AppNotification(
      id: positiveInt(data['notification_id'] ?? data['id']) ?? 0,
      title: message.notification?.title ?? data['title'] ?? '',
      body: message.notification?.body ?? data['body'] ?? '',
      data: data,
      isRead: false,
      createdAt:
          _dateValue(data['created_at'] ?? data['timestamp']) ?? DateTime.now(),
    );
  }

  String get type => data['type']?.trim() ?? '';

  int? get ticketId => positiveInt(data['ticket_id']);

  AppNotificationDestination get destination =>
      AppNotificationDestination.fromData(data);

  AppNotification copyWith({
    String? title,
    String? body,
    Map<String, String>? data,
    bool? isRead,
    DateTime? readAt,
    bool clearReadAt = false,
  }) {
    return AppNotification(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      createdAt: createdAt,
    );
  }

  bool matchesRemoteMessage(RemoteMessage message) {
    final incoming = AppNotification.fromRemoteMessage(message);
    if (incoming.id > 0 && id > 0) return incoming.id == id;
    if (type.isNotEmpty && incoming.type.isNotEmpty && type != incoming.type) {
      return false;
    }
    if (ticketId != null && incoming.ticketId != null) {
      return ticketId == incoming.ticketId;
    }
    final messageId = data['message_id'];
    final incomingMessageId = incoming.data['message_id'];
    if (messageId != null && incomingMessageId != null) {
      return messageId == incomingMessageId;
    }
    return title == incoming.title && body == incoming.body;
  }

  static int? positiveInt(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is num && value == value.round() && value > 0) {
      return value.toInt();
    }
    final parsed = int.tryParse(value?.toString().trim() ?? '');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  static bool _boolValue(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime? _dateValue(dynamic value) {
    if (value is DateTime) return value;
    final text = value?.toString();
    return text == null || text.isEmpty ? null : DateTime.tryParse(text);
  }
}

class AppNotificationDestination {
  final String path;
  final int? notificationId;

  const AppNotificationDestination({required this.path, this.notificationId});

  factory AppNotificationDestination.fromData(Map<String, dynamic> data) {
    final type = data['type']?.toString().trim() ?? '';
    final ticketId = AppNotification.positiveInt(data['ticket_id']);
    final notificationId = AppNotification.positiveInt(
      data['notification_id'] ?? data['id'],
    );

    if (supportNotificationTypes.contains(type) && ticketId != null) {
      return AppNotificationDestination(
        path: '/support/$ticketId',
        notificationId: notificationId,
      );
    }

    return AppNotificationDestination(
      path: '/notifications',
      notificationId: notificationId,
    );
  }
}

class ForegroundNotificationEvent {
  final AppNotification notification;
  final AppNotificationDestination destination;

  const ForegroundNotificationEvent({
    required this.notification,
    required this.destination,
  });
}
