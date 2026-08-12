import 'dart:convert';

class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;
  final Object? rawResponse;

  const PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
    this.rawResponse,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
          (json['results'] as List<dynamic>?)
              ?.map((e) => fromJsonT(e as Map<String, dynamic>))
              .toList() ??
          [],
      rawResponse: Map<String, dynamic>.from(json),
    );
  }
}

class DriverAddress {
  final int? id;
  final String label;
  final String? lat;
  final String? lng;
  final String fullAddress;
  final String streetName;
  final String houseNumber;
  final String city;
  final String postalCode;
  final String country;
  final bool? isDefault;

  const DriverAddress({
    this.id,
    required this.label,
    this.lat,
    this.lng,
    required this.fullAddress,
    required this.streetName,
    required this.houseNumber,
    required this.city,
    required this.postalCode,
    required this.country,
    this.isDefault,
  });

  factory DriverAddress.fromJson(Map<String, dynamic> json) {
    return DriverAddress(
      id: json['id'] == null ? null : _intValue(json['id']),
      label: _stringValue(json['label']),
      lat: _nullIfEmpty(json['lat']),
      lng: _nullIfEmpty(json['lng']),
      fullAddress: _stringValue(json['full_address']),
      streetName: _stringValue(json['street_name']),
      houseNumber: _stringValue(json['house_number']),
      city: _stringValue(json['city']),
      postalCode: _stringValue(json['postal_code']),
      country: _stringValue(json['country']),
      isDefault: _boolValue(json['is_default']),
    );
  }

  static DriverAddress? fromDynamic(dynamic value) {
    if (value is! Map) return null;
    final address = DriverAddress.fromJson(Map<String, dynamic>.from(value));
    return address.isEmpty ? null : address;
  }

  bool get isEmpty =>
      label.isEmpty &&
      lat == null &&
      lng == null &&
      fullAddress.isEmpty &&
      streetName.isEmpty &&
      houseNumber.isEmpty &&
      city.isEmpty &&
      postalCode.isEmpty &&
      country.isEmpty;

  bool get hasCoordinates =>
      lat != null &&
      lat!.trim().isNotEmpty &&
      lng != null &&
      lng!.trim().isNotEmpty;

  String get displayLine {
    if (fullAddress.isNotEmpty) return fullAddress;

    final street = [
      streetName,
      houseNumber,
    ].where((part) => part.isNotEmpty).join(' ');
    final locality = [
      city,
      postalCode,
    ].where((part) => part.isNotEmpty).join(', ');
    return [
      street,
      locality,
      country,
    ].where((part) => part.isNotEmpty).join(', ');
  }

  String get searchText => [
    label,
    fullAddress,
    streetName,
    houseNumber,
    city,
    postalCode,
    country,
  ].where((part) => part.isNotEmpty).join(' ');
}

class DriverWithLocation {
  final int id;
  final String? email;
  final String name;
  final String phone;
  final String status;
  final bool isOnline;
  final String vehicleType;
  final bool? acceptsFood;
  final bool? acceptsShipping;
  final bool? acceptsTaxi;
  final String? drivingLicense;
  final String? idDocument;
  final String? otherDocuments;
  final String? carSize;
  final String? vehiclePlateNumber;
  final String? vehicleColor;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleYear;
  final DateTime? createdAt;
  final String? latitude;
  final String? longitude;
  final DateTime? locationUpdatedAt;
  final DriverAddress? address;
  final List<DriverDocument> documentItems;

  const DriverWithLocation({
    required this.id,
    this.email,
    required this.name,
    required this.phone,
    this.status = '',
    required this.isOnline,
    this.vehicleType = '',
    this.acceptsFood,
    this.acceptsShipping,
    this.acceptsTaxi,
    this.drivingLicense,
    this.idDocument,
    this.otherDocuments,
    this.carSize,
    this.vehiclePlateNumber,
    this.vehicleColor,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
    this.address,
    this.documentItems = const [],
  });

  factory DriverWithLocation.fromJson(Map<String, dynamic> json) {
    String? nullIfEmpty(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
      return null;
    }

    final rawDocuments = json['documents'];
    final documents = rawDocuments is Map
        ? Map<String, dynamic>.from(rawDocuments)
        : const <String, dynamic>{};
    final rawVehicle = json['vehicle'];
    final vehicle = rawVehicle is Map
        ? Map<String, dynamic>.from(rawVehicle)
        : const <String, dynamic>{};
    final rawServices = json['service_types'];
    final services = rawServices is Map
        ? Map<String, dynamic>.from(rawServices)
        : const <String, dynamic>{};

    return DriverWithLocation(
      id: json['id'] ?? 0,
      email: nullIfEmpty(json['email']),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      status: (nullIfEmpty(json['status'] ?? json['approval_status']) ?? '')
          .toUpperCase(),
      isOnline: json['is_online'] ?? false,
      vehicleType:
          nullIfEmpty(
            json['vehicle_type'] ??
                json['vehicleType'] ??
                vehicle['type'] ??
                vehicle['vehicle_type'] ??
                (rawVehicle is String ? rawVehicle : null),
          ) ??
          '',
      acceptsFood: parseBool(
        json['accepts_food'] ??
            services['accepts_food'] ??
            services['food'] ??
            json['food_enabled'],
      ),
      acceptsShipping: parseBool(
        json['accepts_shipping'] ??
            services['accepts_shipping'] ??
            services['shipping'] ??
            json['shipping_enabled'],
      ),
      acceptsTaxi: parseBool(
        json['accepts_taxi'] ??
            services['accepts_taxi'] ??
            services['taxi'] ??
            json['taxi_enabled'],
      ),
      drivingLicense: nullIfEmpty(
        json['driving_license'] ??
            documents['driving_license'] ??
            documents['license'],
      ),
      idDocument: nullIfEmpty(
        json['id_document'] ??
            documents['id_document'] ??
            documents['identity_document'],
      ),
      otherDocuments: nullIfEmpty(
        json['other_documents'] ??
            documents['other_documents'] ??
            documents['other'],
      ),
      carSize: nullIfEmpty(
        json['car_size'] ??
            json['carSize'] ??
            vehicle['car_size'] ??
            vehicle['carSize'],
      ),
      vehiclePlateNumber: nullIfEmpty(
        json['vehicle_plate_number'] ??
            json['plate_number'] ??
            json['vehiclePlateNumber'] ??
            vehicle['vehicle_plate_number'] ??
            vehicle['plate_number'] ??
            vehicle['plateNumber'],
      ),
      vehicleColor: nullIfEmpty(
        json['vehicle_color'] ??
            json['color'] ??
            json['vehicleColor'] ??
            vehicle['vehicle_color'] ??
            vehicle['color'],
      ),
      vehicleMake: nullIfEmpty(
        json['vehicle_make'] ??
            json['make'] ??
            json['vehicleMake'] ??
            vehicle['vehicle_make'] ??
            vehicle['make'],
      ),
      vehicleModel: nullIfEmpty(
        json['vehicle_model'] ??
            json['model'] ??
            json['vehicleModel'] ??
            vehicle['vehicle_model'] ??
            vehicle['model'],
      ),
      vehicleYear: nullIfEmpty(
        json['vehicle_year'] ??
            json['year'] ??
            json['vehicleYear'] ??
            vehicle['vehicle_year'] ??
            vehicle['year'],
      ),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      latitude: nullIfEmpty(json['latitude']),
      longitude: nullIfEmpty(json['longitude']),
      locationUpdatedAt: json['location_updated_at'] != null
          ? DateTime.tryParse(json['location_updated_at'])
          : null,
      address: DriverAddress.fromDynamic(json['address']),
      documentItems: _parseDriverDocuments(json, documents),
    );
  }
}

class HomeRestaurant {
  final int id;
  final int ownerUser;
  final String name;
  final String? logo;
  final RestaurantAddress? address;
  final String phone;
  final RestaurantWorkHours workHours;
  final String status;
  final DateTime? createdAt;
  final bool isActive;

  const HomeRestaurant({
    required this.id,
    required this.ownerUser,
    required this.name,
    this.logo,
    this.address,
    required this.phone,
    required this.workHours,
    required this.status,
    this.createdAt,
    required this.isActive,
  });

  factory HomeRestaurant.fromJson(Map<String, dynamic> json) {
    final rawAddress = json['address'];
    return HomeRestaurant(
      id: _intValue(json['id']),
      ownerUser: _intValue(json['owner_user']),
      name: _stringValue(json['name']),
      logo: _nullIfEmpty(json['logo']),
      address: rawAddress is Map
          ? RestaurantAddress.fromJson(Map<String, dynamic>.from(rawAddress))
          : null,
      phone: _stringValue(json['phone']),
      workHours: RestaurantWorkHours.fromJson(json['work_hours']),
      status: _stringValue(json['status']).toUpperCase(),
      createdAt: _dateValue(json['created_at']),
      isActive: _boolValue(json['is_active']) ?? false,
    );
  }

  RestaurantOpeningSnapshot openingStatus([DateTime? now]) {
    return workHours.openingStatus(now ?? DateTime.now());
  }

  bool isOpenNow([DateTime? now]) {
    return isActive && openingStatus(now).isOpenNow;
  }

  String get city => address?.city ?? '';
  String get displayAddress => address?.displayLine ?? '';
}

class RestaurantAddress {
  final int id;
  final String label;
  final bool isDefault;
  final String? lat;
  final String? lng;
  final String fullAddress;
  final String streetName;
  final String houseNumber;
  final String city;
  final String postalCode;
  final String country;
  final DateTime? createdAt;

  const RestaurantAddress({
    required this.id,
    required this.label,
    required this.isDefault,
    this.lat,
    this.lng,
    required this.fullAddress,
    required this.streetName,
    required this.houseNumber,
    required this.city,
    required this.postalCode,
    required this.country,
    this.createdAt,
  });

  factory RestaurantAddress.fromJson(Map<String, dynamic> json) {
    return RestaurantAddress(
      id: _intValue(json['id']),
      label: _stringValue(json['label']),
      isDefault: _boolValue(json['is_default']) ?? false,
      lat: _nullIfEmpty(json['lat']),
      lng: _nullIfEmpty(json['lng']),
      fullAddress: _stringValue(json['full_address']),
      streetName: _stringValue(json['street_name']),
      houseNumber: _stringValue(json['house_number']),
      city: _stringValue(json['city']),
      postalCode: _stringValue(json['postal_code']),
      country: _stringValue(json['country']),
      createdAt: _dateValue(json['created_at']),
    );
  }

  String get displayLine {
    if (fullAddress.trim().isNotEmpty) return fullAddress.trim();

    final street = [
      streetName,
      houseNumber,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    final parts = [
      street,
      city,
      postalCode,
      country,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  bool get hasCoordinates =>
      lat != null &&
      lat!.trim().isNotEmpty &&
      lng != null &&
      lng!.trim().isNotEmpty;
}

class RestaurantWorkHours {
  static const dayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final Map<String, List<RestaurantTimeRange>> days;

  const RestaurantWorkHours({required this.days});

  factory RestaurantWorkHours.empty() {
    return RestaurantWorkHours(
      days: {for (final day in dayKeys) day: const <RestaurantTimeRange>[]},
    );
  }

  factory RestaurantWorkHours.fromJson(dynamic value) {
    dynamic raw = value;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return RestaurantWorkHours.empty();
      try {
        raw = jsonDecode(trimmed);
      } catch (_) {
        return RestaurantWorkHours.empty();
      }
    }

    if (raw is! Map) return RestaurantWorkHours.empty();

    final source = Map<String, dynamic>.from(raw);
    final parsed = {for (final day in dayKeys) day: <RestaurantTimeRange>[]};
    final localOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;

    for (final day in dayKeys) {
      final rawRanges = source[day] ?? source[_capitalize(day)];
      if (rawRanges is List) {
        for (final rawRange in rawRanges.whereType<Map>()) {
          final range = RestaurantTimeRange.fromJson(
            Map<String, dynamic>.from(rawRange),
          );
          if (!range.isValid) continue;

          for (final localRange in _convertUtcRangeToLocal(
            utcDayIndex: dayKeys.indexOf(day),
            utcRange: range,
            localOffsetMinutes: localOffsetMinutes,
          )) {
            parsed[localRange.dayKey]!.add(localRange.range);
          }
        }
      }
    }

    for (final ranges in parsed.values) {
      ranges.sort((a, b) => a.openMinutes!.compareTo(b.openMinutes!));
    }

    return RestaurantWorkHours(days: parsed);
  }

  static List<_LocalRestaurantRange> _convertUtcRangeToLocal({
    required int utcDayIndex,
    required RestaurantTimeRange utcRange,
    required int localOffsetMinutes,
  }) {
    const dayMinutes = 24 * 60;
    const weekMinutes = dayMinutes * 7;

    var start =
        utcDayIndex * dayMinutes + utcRange.openMinutes! + localOffsetMinutes;
    var end =
        utcDayIndex * dayMinutes + utcRange.closeMinutes! + localOffsetMinutes;
    if (utcRange.closeMinutes! <= utcRange.openMinutes!) {
      end += dayMinutes;
    }

    while (start < 0) {
      start += weekMinutes;
      end += weekMinutes;
    }
    while (start >= weekMinutes) {
      start -= weekMinutes;
      end -= weekMinutes;
    }

    final converted = <_LocalRestaurantRange>[];

    void addInterval(int intervalStart, int intervalEnd) {
      var cursor = intervalStart;
      while (cursor < intervalEnd) {
        final dayIndex = (cursor ~/ dayMinutes) % 7;
        final dayEnd = (dayIndex + 1) * dayMinutes;
        final segmentEnd = intervalEnd < dayEnd ? intervalEnd : dayEnd;
        converted.add(
          _LocalRestaurantRange(
            dayKey: dayKeys[dayIndex],
            range: RestaurantTimeRange(
              open: _formatClockMinutes(cursor % dayMinutes),
              close: _formatClockMinutes(segmentEnd % dayMinutes),
            ),
          ),
        );
        cursor = segmentEnd;
      }
    }

    if (end > weekMinutes) {
      addInterval(start, weekMinutes);
      addInterval(0, end - weekMinutes);
    } else {
      addInterval(start, end);
    }

    return converted;
  }

  List<RestaurantTimeRange> rangesFor(String dayKey) {
    return days[dayKey] ?? const <RestaurantTimeRange>[];
  }

  bool get hasAnyHours => days.values.any((ranges) => ranges.isNotEmpty);

  RestaurantOpeningSnapshot openingStatus(DateTime now) {
    final todayKey = dayKeyFor(now);
    final yesterdayKey = dayKeyFor(now.subtract(const Duration(days: 1)));
    final nowMinutes = now.hour * 60 + now.minute;

    for (final range in rangesFor(yesterdayKey)) {
      if (range.crossesMidnight && nowMinutes < range.closeMinutes!) {
        return RestaurantOpeningSnapshot(
          isOpenNow: true,
          currentDayKey: yesterdayKey,
          currentRange: range,
        );
      }
    }

    for (final range in rangesFor(todayKey)) {
      if (range.isOpenOnStartDay(nowMinutes)) {
        return RestaurantOpeningSnapshot(
          isOpenNow: true,
          currentDayKey: todayKey,
          currentRange: range,
        );
      }
    }

    for (var offset = 0; offset <= 7; offset++) {
      final day = now.add(Duration(days: offset));
      final key = dayKeyFor(day);
      final ranges = [...rangesFor(key)]
        ..sort((a, b) => a.openMinutes!.compareTo(b.openMinutes!));

      for (final range in ranges) {
        if (offset > 0 || range.openMinutes! > nowMinutes) {
          return RestaurantOpeningSnapshot(
            isOpenNow: false,
            nextDayKey: key,
            nextRange: range,
            nextDaysAhead: offset,
          );
        }
      }
    }

    return const RestaurantOpeningSnapshot(isOpenNow: false);
  }

  static String dayKeyFor(DateTime date) => dayKeys[date.weekday - 1];
}

class RestaurantTimeRange {
  final String open;
  final String close;

  const RestaurantTimeRange({required this.open, required this.close});

  factory RestaurantTimeRange.fromJson(Map<String, dynamic> json) {
    return RestaurantTimeRange(
      open: _stringValue(json['open']),
      close: _stringValue(json['close']),
    );
  }

  int? get openMinutes => _parseClockMinutes(open);
  int? get closeMinutes => _parseClockMinutes(close);
  bool get isValid => openMinutes != null && closeMinutes != null;
  bool get crossesMidnight => isValid && closeMinutes! <= openMinutes!;

  bool isOpenOnStartDay(int minute) {
    if (!isValid) return false;
    if (crossesMidnight) return minute >= openMinutes!;
    return minute >= openMinutes! && minute < closeMinutes!;
  }

  String get display => '$open - $close';
}

class RestaurantOpeningSnapshot {
  final bool isOpenNow;
  final String? currentDayKey;
  final RestaurantTimeRange? currentRange;
  final String? nextDayKey;
  final RestaurantTimeRange? nextRange;
  final int? nextDaysAhead;

  const RestaurantOpeningSnapshot({
    required this.isOpenNow,
    this.currentDayKey,
    this.currentRange,
    this.nextDayKey,
    this.nextRange,
    this.nextDaysAhead,
  });
}

class _LocalRestaurantRange {
  final String dayKey;
  final RestaurantTimeRange range;

  const _LocalRestaurantRange({required this.dayKey, required this.range});
}

class PendingDriver {
  final int id;
  final String name;
  final String phone;
  final String status;
  final DateTime? submittedAt;
  final DriverAddress? address;

  const PendingDriver({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    this.submittedAt,
    this.address,
  });

  factory PendingDriver.fromJson(Map<String, dynamic> json) {
    return PendingDriver(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'PENDING',
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'])
          : null,
      address: DriverAddress.fromDynamic(json['address']),
    );
  }
}

class PendingRestaurant {
  final int id;
  final String name;
  final String status;
  final DateTime? submittedAt;

  const PendingRestaurant({
    required this.id,
    required this.name,
    required this.status,
    this.submittedAt,
  });

  factory PendingRestaurant.fromJson(Map<String, dynamic> json) {
    return PendingRestaurant(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? 'PENDING',
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'])
          : null,
    );
  }
}

class DriverDocument {
  final String key;
  final String label;
  final String? url;

  const DriverDocument({
    required this.key,
    required this.label,
    required this.url,
  });
}

class DriverProfile {
  final int id;
  final String? email;
  final String name;
  final String status;
  final String? phone;
  final String vehicleType;
  final bool? acceptsFood;
  final bool? acceptsShipping;
  final bool? acceptsTaxi;
  final String? drivingLicense;
  final String? idDocument;
  final String? otherDocuments;
  final String? carSize;
  final String? vehiclePlateNumber;
  final String? vehicleColor;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleYear;
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final bool? isOnline;
  final String? latitude;
  final String? longitude;
  final DateTime? locationUpdatedAt;
  final DriverAddress? address;
  final List<DriverDocument> documentItems;
  final bool hasExtendedDetails;

  const DriverProfile({
    required this.id,
    this.email,
    required this.name,
    required this.status,
    this.phone,
    required this.vehicleType,
    required this.acceptsFood,
    required this.acceptsShipping,
    required this.acceptsTaxi,
    this.drivingLicense,
    this.idDocument,
    this.otherDocuments,
    this.carSize,
    this.vehiclePlateNumber,
    this.vehicleColor,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.createdAt,
    this.submittedAt,
    this.isOnline,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
    this.address,
    this.documentItems = const [],
    this.hasExtendedDetails = false,
  });

  bool get hasLocation =>
      latitude != null &&
      latitude!.isNotEmpty &&
      longitude != null &&
      longitude!.isNotEmpty;

  bool get hasAddress => address != null && !address!.isEmpty;

  bool get hasServiceDetails =>
      acceptsFood != null || acceptsShipping != null || acceptsTaxi != null;

  bool get hasVehicleDetails =>
      vehicleType.isNotEmpty ||
      carSize != null ||
      vehiclePlateNumber != null ||
      vehicleColor != null ||
      vehicleMake != null ||
      vehicleModel != null ||
      vehicleYear != null;

  bool get hasDocuments =>
      documentItems.any((doc) => doc.url != null) ||
      drivingLicense != null ||
      idDocument != null ||
      otherDocuments != null;

  DriverProfile mergeFallback(DriverProfile fallback) {
    return DriverProfile(
      id: id != 0 ? id : fallback.id,
      email: email ?? fallback.email,
      name: name.isNotEmpty ? name : fallback.name,
      status: status.isNotEmpty ? status : fallback.status,
      phone: phone ?? fallback.phone,
      vehicleType: vehicleType.isNotEmpty ? vehicleType : fallback.vehicleType,
      acceptsFood: acceptsFood ?? fallback.acceptsFood,
      acceptsShipping: acceptsShipping ?? fallback.acceptsShipping,
      acceptsTaxi: acceptsTaxi ?? fallback.acceptsTaxi,
      drivingLicense: drivingLicense ?? fallback.drivingLicense,
      idDocument: idDocument ?? fallback.idDocument,
      otherDocuments: otherDocuments ?? fallback.otherDocuments,
      carSize: carSize ?? fallback.carSize,
      vehiclePlateNumber: vehiclePlateNumber ?? fallback.vehiclePlateNumber,
      vehicleColor: vehicleColor ?? fallback.vehicleColor,
      vehicleMake: vehicleMake ?? fallback.vehicleMake,
      vehicleModel: vehicleModel ?? fallback.vehicleModel,
      vehicleYear: vehicleYear ?? fallback.vehicleYear,
      createdAt: createdAt ?? fallback.createdAt,
      submittedAt: submittedAt ?? fallback.submittedAt,
      isOnline: isOnline ?? fallback.isOnline,
      latitude: latitude ?? fallback.latitude,
      longitude: longitude ?? fallback.longitude,
      locationUpdatedAt: locationUpdatedAt ?? fallback.locationUpdatedAt,
      address: address ?? fallback.address,
      documentItems: _mergeDriverDocuments(
        documentItems,
        fallback.documentItems,
      ),
      hasExtendedDetails: hasExtendedDetails || fallback.hasExtendedDetails,
    );
  }

  factory DriverProfile.fromPendingDriver(PendingDriver driver) {
    return DriverProfile(
      id: driver.id,
      name: driver.name,
      status: driver.status,
      phone: driver.phone,
      vehicleType: '',
      acceptsFood: null,
      acceptsShipping: null,
      acceptsTaxi: null,
      carSize: null,
      vehiclePlateNumber: null,
      vehicleColor: null,
      vehicleMake: null,
      vehicleModel: null,
      vehicleYear: null,
      submittedAt: driver.submittedAt,
      address: driver.address,
      documentItems: const [],
    );
  }

  factory DriverProfile.fromDriverWithLocation(DriverWithLocation driver) {
    final hasExtendedDetails =
        driver.vehicleType.isNotEmpty ||
        driver.acceptsFood != null ||
        driver.acceptsShipping != null ||
        driver.acceptsTaxi != null ||
        driver.drivingLicense != null ||
        driver.idDocument != null ||
        driver.otherDocuments != null ||
        driver.carSize != null ||
        driver.vehiclePlateNumber != null ||
        driver.vehicleColor != null ||
        driver.vehicleMake != null ||
        driver.vehicleModel != null ||
        driver.vehicleYear != null ||
        driver.address != null ||
        driver.documentItems.isNotEmpty;

    return DriverProfile(
      id: driver.id,
      email: driver.email,
      name: driver.name,
      status: driver.status.isNotEmpty
          ? driver.status
          : (driver.isOnline ? 'ONLINE' : 'OFFLINE'),
      phone: driver.phone,
      vehicleType: driver.vehicleType,
      acceptsFood: driver.acceptsFood,
      acceptsShipping: driver.acceptsShipping,
      acceptsTaxi: driver.acceptsTaxi,
      drivingLicense: driver.drivingLicense,
      idDocument: driver.idDocument,
      otherDocuments: driver.otherDocuments,
      carSize: driver.carSize,
      vehiclePlateNumber: driver.vehiclePlateNumber,
      vehicleColor: driver.vehicleColor,
      vehicleMake: driver.vehicleMake,
      vehicleModel: driver.vehicleModel,
      vehicleYear: driver.vehicleYear,
      createdAt: driver.createdAt,
      isOnline: driver.isOnline,
      latitude: driver.latitude,
      longitude: driver.longitude,
      locationUpdatedAt: driver.locationUpdatedAt,
      address: driver.address,
      documentItems: driver.documentItems,
      hasExtendedDetails: hasExtendedDetails,
    );
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    String? nullIfEmpty(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
      return null;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    int parseId(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    final rawDriver = json['driver'];
    final driver = rawDriver is Map
        ? Map<String, dynamic>.from(rawDriver)
        : const <String, dynamic>{};
    final rawVehicle = json['vehicle'];
    final vehicle = rawVehicle is Map
        ? Map<String, dynamic>.from(rawVehicle)
        : const <String, dynamic>{};
    final rawDocuments = json['documents'];
    final documents = rawDocuments is Map
        ? Map<String, dynamic>.from(rawDocuments)
        : const <String, dynamic>{};
    final rawDriverDocuments = driver['documents'];
    final driverDocuments = rawDriverDocuments is Map
        ? Map<String, dynamic>.from(rawDriverDocuments)
        : const <String, dynamic>{};
    final rawServices = json['service_types'];
    final services = rawServices is Map
        ? Map<String, dynamic>.from(rawServices)
        : const <String, dynamic>{};
    final documentItems = _parseDriverDocuments(
      json,
      documents,
      driverDocuments: driverDocuments,
    );
    final address = DriverAddress.fromDynamic(
      json['address'] ?? driver['address'],
    );

    final firstName =
        nullIfEmpty(json['first_name']) ?? nullIfEmpty(driver['first_name']);
    final lastName =
        nullIfEmpty(json['last_name']) ?? nullIfEmpty(driver['last_name']);
    final fullName =
        nullIfEmpty(json['name']) ??
        nullIfEmpty(json['full_name']) ??
        nullIfEmpty(json['driver_name']) ??
        nullIfEmpty(driver['name']) ??
        nullIfEmpty(driver['full_name']) ??
        [firstName, lastName].whereType<String>().join(' ').trim();

    return DriverProfile(
      id: parseId(json['id'] ?? json['driver_id'] ?? driver['id']),
      email: nullIfEmpty(json['email'] ?? driver['email']),
      name: fullName,
      status:
          (nullIfEmpty(
                    json['status'] ??
                        json['approval_status'] ??
                        driver['status'],
                  ) ??
                  'PENDING')
              .toUpperCase(),
      phone: nullIfEmpty(
        json['phone'] ??
            json['phone_number'] ??
            json['driver_phone'] ??
            driver['phone'] ??
            driver['phone_number'],
      ),
      vehicleType:
          nullIfEmpty(
            json['vehicle_type'] ??
                json['vehicleType'] ??
                vehicle['type'] ??
                vehicle['vehicle_type'] ??
                (rawVehicle is String ? rawVehicle : null),
          ) ??
          '',
      carSize: nullIfEmpty(
        json['car_size'] ??
            json['carSize'] ??
            vehicle['car_size'] ??
            vehicle['carSize'],
      ),
      vehiclePlateNumber: nullIfEmpty(
        json['vehicle_plate_number'] ??
            json['plate_number'] ??
            json['vehiclePlateNumber'] ??
            vehicle['vehicle_plate_number'] ??
            vehicle['plate_number'] ??
            vehicle['plateNumber'],
      ),
      vehicleColor: nullIfEmpty(
        json['vehicle_color'] ??
            json['color'] ??
            json['vehicleColor'] ??
            vehicle['vehicle_color'] ??
            vehicle['color'],
      ),
      vehicleMake: nullIfEmpty(
        json['vehicle_make'] ??
            json['make'] ??
            json['vehicleMake'] ??
            vehicle['vehicle_make'] ??
            vehicle['make'],
      ),
      vehicleModel: nullIfEmpty(
        json['vehicle_model'] ??
            json['model'] ??
            json['vehicleModel'] ??
            vehicle['vehicle_model'] ??
            vehicle['model'],
      ),
      vehicleYear: nullIfEmpty(
        json['vehicle_year'] ??
            json['year'] ??
            json['vehicleYear'] ??
            vehicle['vehicle_year'] ??
            vehicle['year'],
      ),
      acceptsFood: parseBool(
        json['accepts_food'] ??
            services['accepts_food'] ??
            services['food'] ??
            json['food_enabled'],
      ),
      acceptsShipping: parseBool(
        json['accepts_shipping'] ??
            services['accepts_shipping'] ??
            services['shipping'] ??
            json['shipping_enabled'],
      ),
      acceptsTaxi: parseBool(
        json['accepts_taxi'] ??
            services['accepts_taxi'] ??
            services['taxi'] ??
            json['taxi_enabled'],
      ),
      drivingLicense: nullIfEmpty(
        json['driving_license'] ??
            documents['driving_license'] ??
            documents['license'],
      ),
      idDocument: nullIfEmpty(
        json['id_document'] ??
            documents['id_document'] ??
            documents['identity_document'],
      ),
      otherDocuments: nullIfEmpty(
        json['other_documents'] ??
            documents['other_documents'] ??
            documents['other'],
      ),
      createdAt: parseDate(
        json['created_at'] ?? json['registered_at'] ?? driver['created_at'],
      ),
      submittedAt: parseDate(json['submitted_at']),
      isOnline: parseBool(json['is_online'] ?? driver['is_online']),
      latitude: nullIfEmpty(json['latitude'] ?? driver['latitude']),
      longitude: nullIfEmpty(json['longitude'] ?? driver['longitude']),
      locationUpdatedAt: parseDate(
        json['location_updated_at'] ?? driver['location_updated_at'],
      ),
      address: address,
      documentItems: documentItems,
      hasExtendedDetails: true,
    );
  }
}

List<DriverDocument> _parseDriverDocuments(
  Map<String, dynamic> json,
  Map<String, dynamic> documents, {
  Map<String, dynamic> driverDocuments = const {},
}) {
  final items = <DriverDocument>[];
  final seenKeys = <String>{};
  const canonicalKeys = <String>[
    'driving_license',
    'id_document',
    'health_insurance_document',
    'address_document',
    'bank_document',
    'other_documents',
  ];

  void addDocument(String key, dynamic value, {bool allowMissing = false}) {
    if (seenKeys.contains(key)) return;
    final url = _extractDocumentUrl(value);
    if (url == null && !allowMissing) return;
    seenKeys.add(key);
    items.add(
      DriverDocument(key: key, label: _humanizeDocumentKey(key), url: url),
    );
  }

  final hasDocumentSignals =
      documents.isNotEmpty ||
      driverDocuments.isNotEmpty ||
      canonicalKeys.any(json.containsKey);
  if (!hasDocumentSignals) return items;

  for (final key in canonicalKeys) {
    addDocument(
      key,
      json[key] ?? documents[key] ?? driverDocuments[key],
      allowMissing: true,
    );
  }

  for (final entry in documents.entries) {
    addDocument(entry.key, entry.value);
  }

  for (final entry in driverDocuments.entries) {
    addDocument(entry.key, entry.value);
  }

  return items;
}

List<DriverDocument> _mergeDriverDocuments(
  List<DriverDocument> current,
  List<DriverDocument> fallback,
) {
  if (current.isEmpty) return fallback;
  if (fallback.isEmpty) return current;

  final merged = <DriverDocument>[];
  final seen = <String>{};

  void addAll(List<DriverDocument> docs) {
    for (final doc in docs) {
      if (seen.add(doc.key)) {
        merged.add(doc);
      }
    }
  }

  addAll(current);
  addAll(fallback);
  return merged;
}

String _humanizeDocumentKey(String key) {
  final normalized = key.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (normalized.isEmpty) return key;

  return normalized
      .split(RegExp(r'\s+'))
      .map((part) {
        final lower = part.toLowerCase();
        if (lower == 'id') return 'ID';
        if (lower == 'url') return 'URL';
        if (part.length == 1) return part.toUpperCase();
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      })
      .join(' ');
}

String? _extractDocumentUrl(dynamic value) {
  if (value == null) return null;

  if (value is String) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    for (final key in const [
      'url',
      'file_url',
      'image_url',
      'document_url',
      'path',
      'link',
    ]) {
      final candidate = map[key];
      final url = _extractDocumentUrl(candidate);
      if (url != null) return url;
    }

    for (final candidate in map.values) {
      final url = _extractDocumentUrl(candidate);
      if (url != null) return url;
    }
    return null;
  }

  if (value is Iterable) {
    for (final candidate in value) {
      final url = _extractDocumentUrl(candidate);
      if (url != null) return url;
    }
    return null;
  }

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

class DriversCount {
  final int online;
  final int offline;

  const DriversCount({required this.online, required this.offline});

  int get total => online + offline;

  factory DriversCount.fromJson(Map<String, dynamic> json) {
    return DriversCount(
      online: json['online'] ?? 0,
      offline: json['offline'] ?? 0,
    );
  }
}

class HomeResponse {
  final PaginatedResponse<DriverWithLocation> driversWithLocations;
  final PaginatedResponse<HomeRestaurant> restaurants;
  final PaginatedResponse<PendingDriver> pendingDrivers;
  final PaginatedResponse<PendingRestaurant> pendingRestaurants;
  final Map<String, int> ordersCountByStatus;
  final DriversCount driversCount;
  final Object? rawResponse;

  const HomeResponse({
    required this.driversWithLocations,
    required this.restaurants,
    required this.pendingDrivers,
    required this.pendingRestaurants,
    required this.ordersCountByStatus,
    required this.driversCount,
    this.rawResponse,
  });

  int get totalOrders =>
      ordersCountByStatus.values.fold(0, (sum, v) => sum + v);

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      driversWithLocations: PaginatedResponse.fromJson(
        json['drivers_with_locations'] ?? {'count': 0, 'results': []},
        DriverWithLocation.fromJson,
      ),
      restaurants: PaginatedResponse.fromJson(
        json['restaurants'] ?? {'count': 0, 'results': []},
        HomeRestaurant.fromJson,
      ),
      pendingDrivers: PaginatedResponse.fromJson(
        json['pending_drivers'] ?? {'count': 0, 'results': []},
        PendingDriver.fromJson,
      ),
      pendingRestaurants: PaginatedResponse.fromJson(
        json['pending_restaurants'] ?? {'count': 0, 'results': []},
        PendingRestaurant.fromJson,
      ),
      ordersCountByStatus:
          (json['orders_count_by_status'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      driversCount: DriversCount.fromJson(
        json['drivers_count'] ?? {'online': 0, 'offline': 0},
      ),
      rawResponse: Map<String, dynamic>.from(json),
    );
  }
}

String _stringValue(dynamic value) => value?.toString().trim() ?? '';

String? _nullIfEmpty(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _intValue(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool? _boolValue(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return null;
}

DateTime? _dateValue(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int? _parseClockMinutes(String value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;

  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return hour * 60 + minute;
}

String _formatClockMinutes(int minutes) {
  final normalized = minutes % (24 * 60);
  final hour = normalized ~/ 60;
  final minute = normalized % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
