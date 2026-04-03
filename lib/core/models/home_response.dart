class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
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
    );
  }
}

class DriverWithLocation {
  final int id;
  final String name;
  final String phone;
  final bool isOnline;
  final String? latitude;
  final String? longitude;
  final DateTime? locationUpdatedAt;

  const DriverWithLocation({
    required this.id,
    required this.name,
    required this.phone,
    required this.isOnline,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
  });

  factory DriverWithLocation.fromJson(Map<String, dynamic> json) {
    return DriverWithLocation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      isOnline: json['is_online'] ?? false,
      latitude: json['latitude'],
      longitude: json['longitude'],
      locationUpdatedAt: json['location_updated_at'] != null
          ? DateTime.tryParse(json['location_updated_at'])
          : null,
    );
  }
}

class HomeRestaurant {
  final int id;
  final String name;
  final String status;
  final bool isActive;

  const HomeRestaurant({
    required this.id,
    required this.name,
    required this.status,
    required this.isActive,
  });

  factory HomeRestaurant.fromJson(Map<String, dynamic> json) {
    return HomeRestaurant(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}

class PendingDriver {
  final int id;
  final String name;
  final String phone;
  final String status;
  final DateTime? submittedAt;

  const PendingDriver({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    this.submittedAt,
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
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final bool? isOnline;
  final String? latitude;
  final String? longitude;
  final DateTime? locationUpdatedAt;
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
    this.createdAt,
    this.submittedAt,
    this.isOnline,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
    this.hasExtendedDetails = false,
  });

  bool get hasLocation =>
      latitude != null &&
      latitude!.isNotEmpty &&
      longitude != null &&
      longitude!.isNotEmpty;

  bool get hasServiceDetails =>
      acceptsFood != null || acceptsShipping != null || acceptsTaxi != null;

  bool get hasDocuments =>
      drivingLicense != null || idDocument != null || otherDocuments != null;

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
      createdAt: createdAt ?? fallback.createdAt,
      submittedAt: submittedAt ?? fallback.submittedAt,
      isOnline: isOnline ?? fallback.isOnline,
      latitude: latitude ?? fallback.latitude,
      longitude: longitude ?? fallback.longitude,
      locationUpdatedAt: locationUpdatedAt ?? fallback.locationUpdatedAt,
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
      submittedAt: driver.submittedAt,
    );
  }

  factory DriverProfile.fromDriverWithLocation(DriverWithLocation driver) {
    return DriverProfile(
      id: driver.id,
      name: driver.name,
      status: driver.isOnline ? 'ONLINE' : 'OFFLINE',
      phone: driver.phone,
      vehicleType: '',
      acceptsFood: null,
      acceptsShipping: null,
      acceptsTaxi: null,
      isOnline: driver.isOnline,
      latitude: driver.latitude,
      longitude: driver.longitude,
      locationUpdatedAt: driver.locationUpdatedAt,
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
    final rawServices = json['service_types'];
    final services = rawServices is Map
        ? Map<String, dynamic>.from(rawServices)
        : const <String, dynamic>{};

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
      hasExtendedDetails: true,
    );
  }
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

  const HomeResponse({
    required this.driversWithLocations,
    required this.restaurants,
    required this.pendingDrivers,
    required this.pendingRestaurants,
    required this.ordersCountByStatus,
    required this.driversCount,
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
    );
  }
}
