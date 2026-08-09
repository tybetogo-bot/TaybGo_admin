class AdminCountry {
  final int id;
  final String name;
  final String? isoCode;
  final bool isActive;
  final DateTime? createdAt;

  const AdminCountry({
    required this.id,
    required this.name,
    this.isoCode,
    required this.isActive,
    this.createdAt,
  });

  factory AdminCountry.fromJson(Map<String, dynamic> json) {
    return AdminCountry(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      isoCode: _asNullableString(
        json['iso_code'] ?? json['iso'] ?? json['country_iso_code'],
      ),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _asDateTime(json['created_at']),
    );
  }
}

class AdminCity {
  final int id;
  final int countryId;
  final String countryName;
  final String? countryIsoCode;
  final String name;
  final bool isActive;
  final DateTime? createdAt;

  const AdminCity({
    required this.id,
    required this.countryId,
    required this.countryName,
    this.countryIsoCode,
    required this.name,
    required this.isActive,
    this.createdAt,
  });

  factory AdminCity.fromJson(Map<String, dynamic> json) {
    return AdminCity(
      id: _asInt(json['id']) ?? 0,
      countryId: _asInt(json['country']) ?? 0,
      countryName: json['country_name']?.toString() ?? '',
      countryIsoCode: _asNullableString(json['country_iso_code']),
      name: json['name']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _asDateTime(json['created_at']),
    );
  }

  String get displayName {
    if (countryName.trim().isEmpty) return name;
    return '$name, $countryName';
  }
}

class PricingPolicy {
  final int id;
  final String name;
  final String scope;
  final int? countryId;
  final String? countryName;
  final String? countryIsoCode;
  final int? cityId;
  final String? cityName;
  final String orderType;
  final String vehicleType;
  final String baseAmount;
  final String baseDistance;
  final String perKmRate;
  final String? driverBaseAmount;
  final String? driverBaseDistance;
  final String? driverPricePerKm;
  final String weightMultiplier;
  final int? averageSpeedKmh;
  final String currency;
  final int version;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PricingPolicy({
    required this.id,
    required this.name,
    required this.scope,
    this.countryId,
    this.countryName,
    this.countryIsoCode,
    this.cityId,
    this.cityName,
    required this.orderType,
    required this.vehicleType,
    required this.baseAmount,
    required this.baseDistance,
    required this.perKmRate,
    this.driverBaseAmount,
    this.driverBaseDistance,
    this.driverPricePerKm,
    required this.weightMultiplier,
    this.averageSpeedKmh,
    required this.currency,
    required this.version,
    this.effectiveFrom,
    this.effectiveTo,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory PricingPolicy.fromJson(Map<String, dynamic> json) {
    return PricingPolicy(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      scope: json['scope']?.toString() ?? 'GLOBAL',
      countryId: _asInt(json['country']),
      countryName: _asNullableString(json['country_name']),
      countryIsoCode: _asNullableString(json['country_iso_code']),
      cityId: _asInt(json['city']),
      cityName: _asNullableString(json['city_name']),
      orderType: json['order_type']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString() ?? '',
      baseAmount: json['base_amount']?.toString() ?? '0',
      baseDistance: json['base_distance']?.toString() ?? '0',
      perKmRate: json['per_km_rate']?.toString() ?? '0',
      driverBaseAmount: _asNullableString(json['driver_base_amount']),
      driverBaseDistance: _asNullableString(json['driver_base_distance']),
      driverPricePerKm: _asNullableString(json['driver_price_per_km']),
      weightMultiplier: json['weight_multiplier']?.toString() ?? '0',
      averageSpeedKmh: _asInt(json['average_speed_kmh']),
      currency: json['currency']?.toString() ?? '',
      version: _asInt(json['version']) ?? 0,
      effectiveFrom: _asDateTime(json['effective_from']),
      effectiveTo: _asDateTime(json['effective_to']),
      isActive: json['is_active'] as bool? ?? false,
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toWriteJson() {
    return {
      'name': name,
      'scope': scope,
      'country': scope == 'COUNTRY' ? countryId : null,
      'city': scope == 'CITY' ? cityId : null,
      'order_type': orderType,
      'vehicle_type': vehicleType,
      'base_amount': baseAmount,
      'base_distance': baseDistance,
      'per_km_rate': perKmRate,
      'driver_base_amount': driverBaseAmount,
      'driver_base_distance': driverBaseDistance,
      'driver_price_per_km': driverPricePerKm,
      'weight_multiplier': weightMultiplier,
      'average_speed_kmh': averageSpeedKmh,
      'currency': currency.toUpperCase(),
      'version': version,
      'effective_from': effectiveFrom?.toUtc().toIso8601String(),
      'effective_to': effectiveTo?.toUtc().toIso8601String(),
      'is_active': isActive,
    };
  }
}

class PricingPolicyValidation {
  PricingPolicyValidation._();

  static Map<String, String> validate({
    required String name,
    required String? scope,
    int? countryId,
    int? cityId,
    required String? orderType,
    required String? vehicleType,
    required String baseAmount,
    required String baseDistance,
    required String perKmRate,
    String? driverBaseAmount,
    String? driverBaseDistance,
    String? driverPricePerKm,
    required String weightMultiplier,
    String? averageSpeedKmh,
    required String currency,
    required String version,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    Map<String, String>? messages,
  }) {
    final errors = <String, String>{};

    String message(String key, String fallback) => messages?[key] ?? fallback;

    if (name.trim().isEmpty) {
      errors['name'] = message('name_required', 'Name is required.');
    }
    if (!const {'GLOBAL', 'COUNTRY', 'CITY'}.contains(scope)) {
      errors['scope'] = message('invalid_scope', 'Select a valid scope.');
    }
    if (scope == 'COUNTRY' && countryId == null) {
      errors['country'] = message(
        'country_required',
        'Country is required for country policies.',
      );
    }
    if (scope == 'CITY' && cityId == null) {
      errors['city'] = message(
        'city_required',
        'City is required for city policies.',
      );
    }
    if (scope != 'COUNTRY' && countryId != null) {
      errors['country'] = message(
        'country_must_be_empty',
        'Country must be empty for this scope.',
      );
    }
    if (scope != 'CITY' && cityId != null) {
      errors['city'] = message(
        'city_must_be_empty',
        'City must be empty for this scope.',
      );
    }
    if (!const {'TAXI', 'SHIPPING', 'FOOD'}.contains(orderType)) {
      errors['order_type'] = message(
        'invalid_order_type',
        'Select a valid order type.',
      );
    }
    if (!const {'BIKE', 'MOTOR', 'CAR', 'VAN'}.contains(vehicleType)) {
      errors['vehicle_type'] = message(
        'invalid_vehicle_type',
        'Select a valid vehicle type.',
      );
    }

    for (final entry in {
      'base_amount': baseAmount,
      'base_distance': baseDistance,
      'per_km_rate': perKmRate,
      'weight_multiplier': weightMultiplier,
      if (driverBaseAmount != null && driverBaseAmount.trim().isNotEmpty)
        'driver_base_amount': driverBaseAmount,
      if (driverBaseDistance != null && driverBaseDistance.trim().isNotEmpty)
        'driver_base_distance': driverBaseDistance,
      if (driverPricePerKm != null && driverPricePerKm.trim().isNotEmpty)
        'driver_price_per_km': driverPricePerKm,
    }.entries) {
      if (!_isNonNegativeDecimal(entry.value)) {
        errors[entry.key] = message(
          'non_negative_number',
          'Enter a number that is zero or greater.',
        );
      }
    }

    if (averageSpeedKmh != null && averageSpeedKmh.trim().isNotEmpty) {
      final speed = int.tryParse(averageSpeedKmh.trim());
      if (speed == null || speed <= 0) {
        errors['average_speed_kmh'] = message(
          'positive_speed',
          'Speed must be a positive integer.',
        );
      }
    }

    if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(currency.trim())) {
      errors['currency'] = message(
        'currency_three_letters',
        'Currency must be exactly three letters.',
      );
    }

    final parsedVersion = int.tryParse(version.trim());
    if (parsedVersion == null || parsedVersion < 0) {
      errors['version'] = message(
        'version_nonnegative',
        'Version must be a nonnegative integer.',
      );
    }

    if (effectiveFrom == null) {
      errors['effective_from'] = message(
        'effective_from_required',
        'Effective from is required.',
      );
    }
    if (effectiveFrom != null &&
        effectiveTo != null &&
        !effectiveTo.isAfter(effectiveFrom)) {
      errors['effective_to'] = message(
        'effective_to_later',
        'Effective to must be later than effective from.',
      );
    }

    return errors;
  }

  static bool _isNonNegativeDecimal(String value) {
    final trimmed = value.trim();
    if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(trimmed)) return false;
    return double.tryParse(trimmed) != null;
  }
}

int? _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String? _asNullableString(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}

DateTime? _asDateTime(dynamic value) {
  final text = _asNullableString(value);
  return text == null ? null : DateTime.tryParse(text);
}
