class AppSetting {
  const AppSetting({
    required this.key,
    required this.value,
    required this.defaultValue,
    required this.description,
    required this.isPublic,
    required this.isOverridden,
    this.updatedAt,
    this.updatedBy,
  });

  final String key;
  final dynamic value;
  final dynamic defaultValue;
  final String description;
  final bool isPublic;
  final bool isOverridden;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory AppSetting.fromJson(Map<String, dynamic> json) {
    final updatedBy = json['updated_by'];
    return AppSetting(
      key: json['key'] as String,
      value: json['value'],
      defaultValue: json['default_value'],
      description: json['description'] as String? ?? '',
      isPublic: json['is_public'] == true,
      isOverridden: json['is_overridden'] == true,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      updatedBy: updatedBy is Map ? updatedBy['name'] as String? : null,
    );
  }

  AppSetting copyWith({dynamic value}) => AppSetting(
    key: key,
    value: value,
    defaultValue: defaultValue,
    description: description,
    isPublic: isPublic,
    isOverridden: true,
    updatedAt: DateTime.now(),
    updatedBy: updatedBy,
  );
}
