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
      results: (json['results'] as List<dynamic>?)
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
          (json['orders_count_by_status'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
              {},
      driversCount: DriversCount.fromJson(
        json['drivers_count'] ?? {'online': 0, 'offline': 0},
      ),
    );
  }
}
