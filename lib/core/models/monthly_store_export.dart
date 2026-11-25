class MonthlyStoreExport {
  final int id;
  final int restaurantId;
  final String restaurantName;
  final String restaurantStoreType;
  final int year;
  final int month;
  final String status;
  final String fileFormat;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int rowCount;
  final Map<String, dynamic> summaryJson;
  final DateTime? generatedAt;
  final String? errorMessage;
  final String? downloadUrl;
  final DateTime? downloadUrlExpiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MonthlyStoreExport({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantStoreType,
    required this.year,
    required this.month,
    required this.status,
    required this.fileFormat,
    this.periodStart,
    this.periodEnd,
    this.rowCount = 0,
    this.summaryJson = const {},
    this.generatedAt,
    this.errorMessage,
    this.downloadUrl,
    this.downloadUrlExpiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory MonthlyStoreExport.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['summary_json'];
    return MonthlyStoreExport(
      id: _asInt(json['id']),
      restaurantId: _asInt(json['restaurant']),
      restaurantName: _asString(json['restaurant_name']),
      restaurantStoreType:
          _asString(json['restaurant_store_type']).toUpperCase().isEmpty
          ? 'RESTAURANT'
          : _asString(json['restaurant_store_type']).toUpperCase(),
      year: _asInt(json['year']),
      month: _asInt(json['month']),
      status: _asString(json['status']).toUpperCase(),
      fileFormat: _asString(json['file_format']).isEmpty
          ? 'PDF'
          : _asString(json['file_format']).toUpperCase(),
      periodStart: _asDate(json['period_start']),
      periodEnd: _asDate(json['period_end']),
      rowCount: _asInt(json['row_count']),
      summaryJson: rawSummary is Map
          ? Map<String, dynamic>.from(rawSummary)
          : const {},
      generatedAt: _asDate(json['generated_at']),
      errorMessage: _nullableString(json['error_message']),
      downloadUrl: _nullableString(json['download_url']),
      downloadUrlExpiresAt: _asDate(json['download_url_expires_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get hasDownload =>
      downloadUrl != null && downloadUrl!.trim().isNotEmpty;
  String get periodLabel =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  String? get grossSalesDisplay {
    final raw =
        summaryJson['gross_sales'] ??
        summaryJson['gross_revenue'] ??
        summaryJson['total_revenue'] ??
        summaryJson['total_amount'];
    if (raw == null) return null;
    final parsed = double.tryParse(raw.toString());
    if (parsed == null) return raw.toString();
    return parsed.toStringAsFixed(2);
  }
}

class AdminMonthlyGenerateResult {
  final MonthlyStoreExport? singleExport;
  final Map<String, dynamic>? batchSummary;

  const AdminMonthlyGenerateResult({this.singleExport, this.batchSummary});

  factory AdminMonthlyGenerateResult.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('id') && json.containsKey('restaurant')) {
      return AdminMonthlyGenerateResult(
        singleExport: MonthlyStoreExport.fromJson(json),
      );
    }
    return AdminMonthlyGenerateResult(batchSummary: json);
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

DateTime? _asDate(dynamic value) {
  final text = _nullableString(value);
  return text == null ? null : DateTime.tryParse(text);
}
