class AdminGiftCardActor {
  final int id;
  final String name;

  const AdminGiftCardActor({required this.id, required this.name});

  static AdminGiftCardActor? fromDynamic(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    return AdminGiftCardActor(
      id: _asInt(map['id']),
      name: _asString(map['name']),
    );
  }
}

class AdminGiftCardHistoryEntry {
  final int id;
  final String type;
  final String label;
  final String amount;
  final DateTime? createdAt;
  final AdminGiftCardActor? performedBy;
  final int? orderId;
  final int? transactionId;
  final Map<String, dynamic> metadata;

  const AdminGiftCardHistoryEntry({
    required this.id,
    required this.type,
    required this.label,
    required this.amount,
    this.createdAt,
    this.performedBy,
    this.orderId,
    this.transactionId,
    this.metadata = const {},
  });

  factory AdminGiftCardHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['metadata'];
    return AdminGiftCardHistoryEntry(
      id: _asInt(json['id']),
      type: _asString(json['type']),
      label: _asString(json['label']).isNotEmpty
          ? _asString(json['label'])
          : _asString(json['type']),
      amount: _moneyStr(json['amount']) ?? '0.00',
      createdAt: _asDate(json['created_at']),
      performedBy: AdminGiftCardActor.fromDynamic(json['performed_by']),
      orderId: json['order_id'] == null ? null : _asInt(json['order_id']),
      transactionId: json['transaction_id'] == null
          ? null
          : _asInt(json['transaction_id']),
      metadata: rawMeta is Map ? Map<String, dynamic>.from(rawMeta) : const {},
    );
  }
}

class AdminGiftCard {
  final int id;
  final String? code;
  final String maskedCode;
  final String initialAmount;
  final String balance;
  final String currency;
  final String status;
  final AdminGiftCardActor? purchasedBy;
  final AdminGiftCardActor? ownedBy;
  final bool isClaimed;
  final DateTime? claimedAt;
  final DateTime? expiresAt;
  final DateTime? paymentExpiresAt;
  final DateTime? createdAt;
  final List<AdminGiftCardHistoryEntry> history;

  const AdminGiftCard({
    required this.id,
    this.code,
    required this.maskedCode,
    required this.initialAmount,
    required this.balance,
    required this.currency,
    required this.status,
    this.purchasedBy,
    this.ownedBy,
    required this.isClaimed,
    this.claimedAt,
    this.expiresAt,
    this.paymentExpiresAt,
    this.createdAt,
    this.history = const [],
  });

  factory AdminGiftCard.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'];
    return AdminGiftCard(
      id: _asInt(json['id']),
      code: _nullableString(json['code']),
      maskedCode: _asString(json['masked_code']),
      initialAmount: _moneyStr(json['initial_amount']) ?? '0.00',
      balance: _moneyStr(json['balance']) ?? '0.00',
      currency: _asString(json['currency']).toUpperCase().isEmpty
          ? 'EUR'
          : _asString(json['currency']).toUpperCase(),
      status: _asString(json['status']).toUpperCase(),
      purchasedBy: AdminGiftCardActor.fromDynamic(json['purchased_by']),
      ownedBy: AdminGiftCardActor.fromDynamic(json['owned_by']),
      isClaimed: json['is_claimed'] == true,
      claimedAt: _asDate(json['claimed_at']),
      expiresAt: _asDate(json['expires_at']),
      paymentExpiresAt: _asDate(json['payment_expires_at']),
      createdAt: _asDate(json['created_at']),
      history: rawHistory is List
          ? rawHistory
                .whereType<Map>()
                .map(
                  (e) => AdminGiftCardHistoryEntry.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  bool get canVoid => status != 'VOID' && status != 'EXPIRED';
  bool get canAdjust => status == 'ACTIVE' || status == 'DEPLETED';
}

class AdminGiftCardIssueResult {
  final int id;
  final String code;
  final String balance;
  final String currency;
  final String status;
  final int? ownedById;
  final DateTime? expiresAt;

  const AdminGiftCardIssueResult({
    required this.id,
    required this.code,
    required this.balance,
    required this.currency,
    required this.status,
    this.ownedById,
    this.expiresAt,
  });

  factory AdminGiftCardIssueResult.fromJson(Map<String, dynamic> json) {
    return AdminGiftCardIssueResult(
      id: _asInt(json['id']),
      code: _asString(json['code']),
      balance: _moneyStr(json['balance']) ?? '0.00',
      currency: _asString(json['currency']).toUpperCase().isEmpty
          ? 'EUR'
          : _asString(json['currency']).toUpperCase(),
      status: _asString(json['status']).toUpperCase(),
      ownedById: json['owned_by'] == null ? null : _asInt(json['owned_by']),
      expiresAt: _asDate(json['expires_at']),
    );
  }
}

class AdminGiftCardOperationResult {
  final int id;
  final String status;
  final String balance;
  final String currency;
  final String maskedCode;

  const AdminGiftCardOperationResult({
    required this.id,
    required this.status,
    required this.balance,
    required this.currency,
    required this.maskedCode,
  });

  factory AdminGiftCardOperationResult.fromJson(Map<String, dynamic> json) {
    return AdminGiftCardOperationResult(
      id: _asInt(json['id']),
      status: _asString(json['status']).toUpperCase(),
      balance: _moneyStr(json['balance']) ?? '0.00',
      currency: _asString(json['currency']).toUpperCase().isEmpty
          ? 'EUR'
          : _asString(json['currency']).toUpperCase(),
      maskedCode: _asString(json['masked_code']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value) => value?.toString().trim() ?? '';

String? _nullableString(dynamic value) {
  final text = _asString(value);
  return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
}

String? _moneyStr(dynamic value) {
  final text = _nullableString(value);
  if (text == null) return null;
  final parsed = double.tryParse(text);
  return parsed?.toStringAsFixed(2) ?? text;
}

DateTime? _asDate(dynamic value) {
  final text = _nullableString(value);
  return text == null ? null : DateTime.tryParse(text);
}
