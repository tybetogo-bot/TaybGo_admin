class SupportTicket {
  final int id;
  final String subject;
  final String category; // ORDER, PAYMENT, DELIVERY, ACCOUNT, OTHER
  final String priority; // LOW, MEDIUM, HIGH, URGENT
  final String status; // OPEN, IN_PROGRESS, RESOLVED, CLOSED
  final int requester;
  final String requesterName;
  final int? order;
  final int? restaurant;
  final String? restaurantName;
  final int? driver;
  final String? driverName;
  final int? assignedTo;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActivityAt;
  final DateTime? closedAt;
  final List<TicketMessage> messages;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.requester,
    required this.requesterName,
    this.order,
    this.restaurant,
    this.restaurantName,
    this.driver,
    this.driverName,
    this.assignedTo,
    this.assignedToName,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActivityAt,
    this.closedAt,
    this.messages = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] ?? 0,
      subject: json['subject'] ?? '',
      category: json['category'] ?? 'OTHER',
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'OPEN',
      requester: json['requester'] ?? 0,
      requesterName: json['requester_name'] ?? '',
      order: json['order'],
      restaurant: json['restaurant'],
      restaurantName: json['restaurant_name'],
      driver: json['driver'],
      driverName: json['driver_name'],
      assignedTo: json['assigned_to'],
      assignedToName: json['assigned_to_name'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.tryParse(json['last_activity_at']) ?? DateTime.now()
          : DateTime.now(),
      closedAt: json['closed_at'] != null
          ? DateTime.tryParse(json['closed_at'])
          : null,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) =>
                  TicketMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  bool get isOpen => status == 'OPEN';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isResolved => status == 'RESOLVED';
  bool get isClosed => status == 'CLOSED';
}

class TicketMessage {
  final int id;
  final int author;
  final String authorName;
  final String authorRole; // CUSTOMER, ADMIN, DRIVER, RESTAURANT, etc.
  final String body;
  final DateTime createdAt;
  final List<TicketAttachment> attachments;

  const TicketMessage({
    required this.id,
    required this.author,
    required this.authorName,
    required this.authorRole,
    required this.body,
    required this.createdAt,
    this.attachments = const [],
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] ?? 0,
      author: json['author'] ?? 0,
      authorName: json['author_name'] ?? '',
      authorRole: json['author_role'] ?? 'CUSTOMER',
      body: json['body'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((a) =>
                  TicketAttachment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  bool get isAdmin => authorRole == 'ADMIN';
}

class TicketAttachment {
  final int id;
  final String fileUrl;
  final String mimeType;
  final DateTime createdAt;

  const TicketAttachment({
    required this.id,
    required this.fileUrl,
    required this.mimeType,
    required this.createdAt,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) {
    return TicketAttachment(
      id: json['id'] ?? 0,
      fileUrl: json['file_url'] ?? '',
      mimeType: json['mime_type'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
