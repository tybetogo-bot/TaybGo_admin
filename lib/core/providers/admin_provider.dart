import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/home_response.dart';
import '../models/support_ticket.dart';
import 'country_filter_provider.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _apiService;
  ApiService get apiService => _apiService;
  final CountryFilterProvider? _countryFilter;
  int? _countryId;
  int _homeRequestVersion = 0;
  int _ticketsRequestVersion = 0;
  int _driverRequestVersion = 0;

  HomeResponse? _homeData;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastHomeUpdatedAt;
  Object? _driverRequestProfileQueueRawResponse;

  // ─── Ticket state ──────────────────────────────────────────────
  List<SupportTicket> _tickets = [];
  int _ticketsTotal = 0;
  bool _ticketsLoading = false;
  String? _ticketsError;
  SupportTicket? _selectedTicket;
  bool _ticketDetailLoading = false;

  // ─── Driver profile detail ────────────────────────────────────
  DriverProfile? get driverProfile => _driverProfile;
  bool get driverProfileLoading => _driverProfileLoading;
  DriverProfile? _driverProfile;
  bool _driverProfileLoading = false;

  DriverProfile? _driverRequestProfile;
  bool _driverRequestProfileLoading = false;

  DriverProfile? get driverRequestProfile => _driverRequestProfile;
  bool get driverRequestProfileLoading => _driverRequestProfileLoading;
  Object? get driverRequestProfileQueueRawResponse =>
      _driverRequestProfileQueueRawResponse;

  // ─── Polling ───────────────────────────────────────────────────
  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 10);

  // Track recently approved/removed IDs so polling doesn't re-add them
  final Set<int> _recentlyRemovedDriverIds = {};
  final Set<int> _recentlyRemovedRestaurantIds = {};

  AdminProvider({ApiService? apiService, CountryFilterProvider? countryFilter})
    : _apiService = apiService ?? ApiService(),
      _countryFilter = countryFilter {
    _countryId = countryFilter?.selectedCountryId;
    countryFilter?.registerConsumer('admin');
    countryFilter?.addListener(_handleCountryChanged);
  }

  // ─── State getters ──────────────────────────────────────────────

  HomeResponse? get homeData => _homeData;
  Object? get homeRawResponse => _homeData?.rawResponse;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastHomeUpdatedAt => _lastHomeUpdatedAt;
  int? get countryId => _countryId;

  void _handleCountryChanged() {
    final countryFilter = _countryFilter;
    if (countryFilter == null) return;
    final nextCountryId = _countryFilter?.selectedCountryId;
    if (_countryId == nextCountryId) return;
    _countryId = nextCountryId;
    debugPrint('[AdminProvider] Country changed — refreshing home and tickets');
    final revision = countryFilter.revision;
    unawaited(
      Future.wait<void>([
        fetchHome(),
        fetchTickets(page: 1),
      ]).whenComplete(() => countryFilter.completeRefresh('admin', revision)),
    );
  }

  // ─── Derived getters from home response ─────────────────────────

  List<DriverWithLocation> get drivers =>
      _homeData?.driversWithLocations.results ?? [];

  int get driversTotal => _homeData?.driversWithLocations.count ?? 0;

  List<HomeRestaurant> get restaurants => _homeData?.restaurants.results ?? [];

  int get restaurantsTotal => _homeData?.restaurants.count ?? 0;

  List<PendingDriver> get pendingDrivers =>
      _homeData?.pendingDrivers.results ?? [];

  int get pendingDriversTotal => _homeData?.pendingDrivers.count ?? 0;

  List<PendingRestaurant> get pendingRestaurants =>
      _homeData?.pendingRestaurants.results ?? [];

  int get pendingRestaurantsTotal => _homeData?.pendingRestaurants.count ?? 0;

  Map<String, int> get ordersCountByStatus =>
      _homeData?.ordersCountByStatus ?? {};

  int get totalOrders => _homeData?.totalOrders ?? 0;

  DriversCount get driversCount =>
      _homeData?.driversCount ?? const DriversCount(online: 0, offline: 0);

  List<DriverWithLocation> get onlineDrivers =>
      drivers.where((d) => d.isOnline).toList();

  List<DriverWithLocation> get offlineDrivers =>
      drivers.where((d) => !d.isOnline).toList();

  // ─── Support tickets ────────────────────────────────────────────

  List<SupportTicket> get tickets => _tickets;
  int get ticketsTotal => _ticketsTotal;
  bool get ticketsLoading => _ticketsLoading;
  String? get ticketsError => _ticketsError;
  SupportTicket? get selectedTicket => _selectedTicket;
  bool get ticketDetailLoading => _ticketDetailLoading;

  List<SupportTicket> get openTickets =>
      _tickets.where((t) => t.isOpen).toList();

  List<SupportTicket> get inProgressTickets =>
      _tickets.where((t) => t.isInProgress).toList();

  List<SupportTicket> get resolvedTickets =>
      _tickets.where((t) => t.isResolved).toList();

  List<SupportTicket> get closedTickets =>
      _tickets.where((t) => t.isClosed).toList();

  // ─── Polling control ──────────────────────────────────────────

  void startPolling() {
    stopPolling();
    debugPrint(
      '[AdminProvider] Starting polling (every ${_pollInterval.inSeconds}s)',
    );
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      debugPrint('[AdminProvider] Poll tick — refreshing home + tickets');
      _silentRefreshHome();
      _silentRefreshTickets();
    });
  }

  void stopPolling() {
    if (_pollTimer != null) {
      debugPrint('[AdminProvider] Stopping polling');
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  /// Refresh home data silently (no loading indicator).
  Future<void> _silentRefreshHome() async {
    final requestVersion = ++_homeRequestVersion;
    final countryId = _countryId;
    try {
      final data = await _getHomeData(countryId: countryId);
      if (requestVersion != _homeRequestVersion) return;

      // Filter out recently approved/removed items so they don't reappear
      // due to backend processing lag.
      final filteredDrivers = data.pendingDrivers.results
          .where((d) => !_recentlyRemovedDriverIds.contains(d.id))
          .toList();
      final filteredRestaurants = data.pendingRestaurants.results
          .where((r) => !_recentlyRemovedRestaurantIds.contains(r.id))
          .toList();

      // Clear IDs that the backend has already processed (no longer in response)
      final serverDriverIds = data.pendingDrivers.results
          .map((d) => d.id)
          .toSet();
      _recentlyRemovedDriverIds.removeWhere(
        (id) => !serverDriverIds.contains(id),
      );
      final serverRestaurantIds = data.pendingRestaurants.results
          .map((r) => r.id)
          .toSet();
      _recentlyRemovedRestaurantIds.removeWhere(
        (id) => !serverRestaurantIds.contains(id),
      );

      _homeData = HomeResponse(
        driversWithLocations: data.driversWithLocations,
        restaurants: data.restaurants,
        pendingDrivers: PaginatedResponse(
          count:
              data.pendingDrivers.count -
              (data.pendingDrivers.results.length - filteredDrivers.length),
          next: data.pendingDrivers.next,
          previous: data.pendingDrivers.previous,
          results: filteredDrivers,
          rawResponse: data.pendingDrivers.rawResponse,
        ),
        pendingRestaurants: PaginatedResponse(
          count:
              data.pendingRestaurants.count -
              (data.pendingRestaurants.results.length -
                  filteredRestaurants.length),
          next: data.pendingRestaurants.next,
          previous: data.pendingRestaurants.previous,
          results: filteredRestaurants,
          rawResponse: data.pendingRestaurants.rawResponse,
        ),
        ordersCountByStatus: data.ordersCountByStatus,
        driversCount: data.driversCount,
        rawResponse: data.rawResponse,
      );
      _lastHomeUpdatedAt = DateTime.now();
      _error = null;
      debugPrint(
        '[AdminProvider] Silent home refresh OK — '
        '${drivers.length} drivers, '
        '$restaurantsTotal restaurants, '
        '$totalOrders orders',
      );
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('[AdminProvider] Silent home refresh FAILED: ${e.message}');
    } catch (e) {
      debugPrint('[AdminProvider] Silent home refresh ERROR: $e');
    }
  }

  /// Refresh tickets silently (no loading indicator).
  Future<void> _silentRefreshTickets() async {
    final requestVersion = ++_ticketsRequestVersion;
    final countryId = _countryId;
    try {
      final json = await _apiService.getTickets(countryId: countryId);
      if (requestVersion != _ticketsRequestVersion) return;
      _ticketsTotal = json['count'] ?? 0;
      _tickets =
          (json['results'] as List<dynamic>?)
              ?.map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _ticketsError = null;
      debugPrint(
        '[AdminProvider] Silent tickets refresh OK — '
        '$_ticketsTotal total, '
        '${openTickets.length} open, '
        '${inProgressTickets.length} in-progress',
      );
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('[AdminProvider] Silent tickets refresh FAILED: ${e.message}');
    } catch (e) {
      debugPrint('[AdminProvider] Silent tickets refresh ERROR: $e');
    }
  }

  // ─── API calls ──────────────────────────────────────────────────

  static const _driversPageSize = 100;

  /// Load the full driver collection used by the management screen.
  ///
  /// The home endpoint paginates each section independently. The driver UI
  /// does not expose pagination, so loading only the default first page makes
  /// its status tiles disagree with the API-wide driver count.
  Future<HomeResponse> _getHomeData({
    int? countryId,
    String? driverSearch,
    String? restaurantSearch,
    String? orderType,
  }) async {
    final base = await _apiService.getHome(
      countryId: countryId,
      driverSearch: driverSearch,
      restaurantSearch: restaurantSearch,
      orderType: orderType,
      driversPage: 1,
      driversPageSize: _driversPageSize,
    );

    final expectedCount = base.driversWithLocations.count;
    final allDrivers = <DriverWithLocation>[];
    final seenDriverIds = <int>{};

    void appendDrivers(List<DriverWithLocation> page) {
      for (final driver in page) {
        if (seenDriverIds.add(driver.id)) {
          allDrivers.add(driver);
        }
      }
    }

    appendDrivers(base.driversWithLocations.results);

    var currentPage = 1;
    var current = base;
    while (allDrivers.length < expectedCount &&
        current.driversWithLocations.next != null &&
        currentPage < 1000) {
      currentPage++;
      current = await _apiService.getHome(
        countryId: countryId,
        driverSearch: driverSearch,
        restaurantSearch: restaurantSearch,
        orderType: orderType,
        driversPage: currentPage,
        driversPageSize: _driversPageSize,
      );

      final before = allDrivers.length;
      appendDrivers(current.driversWithLocations.results);
      if (allDrivers.length == before) break;
    }

    if (allDrivers.length == base.driversWithLocations.results.length) {
      return base;
    }

    return HomeResponse(
      driversWithLocations: PaginatedResponse(
        count: expectedCount,
        next: null,
        previous: null,
        results: allDrivers,
        rawResponse: base.driversWithLocations.rawResponse,
      ),
      restaurants: base.restaurants,
      pendingDrivers: base.pendingDrivers,
      pendingRestaurants: base.pendingRestaurants,
      ordersCountByStatus: base.ordersCountByStatus,
      driversCount: base.driversCount,
      rawResponse: base.rawResponse,
    );
  }

  Future<void> fetchHome({
    String? driverSearch,
    String? restaurantSearch,
    String? orderType,
  }) async {
    debugPrint('[AdminProvider] fetchHome() called');
    final requestVersion = ++_homeRequestVersion;
    final countryId = _countryId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _homeData = await _getHomeData(
        countryId: countryId,
        driverSearch: driverSearch,
        restaurantSearch: restaurantSearch,
        orderType: orderType,
      );
      _lastHomeUpdatedAt = DateTime.now();
      _error = null;
      debugPrint(
        '[AdminProvider] fetchHome() SUCCESS — '
        'drivers: ${drivers.length}, '
        'restaurants: $restaurantsTotal, '
        'orders: $totalOrders, '
        'pending drivers: $pendingDriversTotal, '
        'pending restaurants: $pendingRestaurantsTotal, '
        'online: ${driversCount.online}, '
        'offline: ${driversCount.offline}',
      );
      for (final d in drivers) {
        debugPrint(
          '[AdminProvider]   Driver: id=${d.id}, name="${d.name}", '
          'phone="${d.phone}", online=${d.isOnline}, '
          'lat=${d.latitude}, lng=${d.longitude}',
        );
      }
      for (final r in restaurants) {
        debugPrint(
          '[AdminProvider]   Restaurant: id=${r.id}, name="${r.name}", '
          'status="${r.status}", active=${r.isActive}',
        );
      }
    } on ApiException catch (e) {
      _error = e.message;
      debugPrint(
        '[AdminProvider] fetchHome() FAILED: ${e.message} (${e.statusCode})',
      );
    } catch (e) {
      _error = 'Connection error. Please try again.';
      debugPrint('[AdminProvider] fetchHome() ERROR: $e');
    } finally {
      if (requestVersion == _homeRequestVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshHome() async {
    debugPrint('[AdminProvider] refreshHome() called');
    await fetchHome();
  }

  // ─── Driver profile detail ──────────────────────────────────────

  Future<void> fetchDriverProfile(
    int driverId, {
    String? driverName,
    String? driverPhone,
  }) async {
    debugPrint(
      '[AdminProvider] fetchDriverProfile() '
      'driverId=$driverId, name=$driverName, phone=$driverPhone',
    );
    _driverProfileLoading = true;
    _driverProfile = _buildLiveDriverProfile(
      driverId,
      driverName: driverName,
      driverPhone: driverPhone,
    );
    notifyListeners();

    try {
      if (_driverProfile == null && _homeData == null) {
        debugPrint(
          '[AdminProvider] fetchDriverProfile() no cached home data — fetching',
        );
        _homeData = await _getHomeData(countryId: _countryId);
        _driverProfile = _buildLiveDriverProfile(
          driverId,
          driverName: driverName,
          driverPhone: driverPhone,
        );
      }
      if (_driverProfile != null) {
        debugPrint(
          '[AdminProvider] fetchDriverProfile() FOUND '
          '(home id=${_driverProfile!.id})',
        );
      } else {
        debugPrint(
          '[AdminProvider] fetchDriverProfile() NOT FOUND in home data',
        );
      }
    } on ApiException catch (e) {
      debugPrint('[AdminProvider] fetchDriverProfile() FAILED: ${e.message}');
    } catch (e) {
      debugPrint('[AdminProvider] fetchDriverProfile() ERROR: $e');
    }

    _driverProfileLoading = false;
    notifyListeners();
  }

  Future<void> fetchDriverRequestProfile(
    int driverId, {
    String? driverName,
    String? driverPhone,
  }) async {
    debugPrint(
      '[AdminProvider] fetchDriverRequestProfile() '
      'driverId=$driverId, name=$driverName, phone=$driverPhone',
    );
    _driverRequestProfileLoading = true;
    _driverRequestProfileQueueRawResponse = null;
    final fallback = _buildPendingDriverProfile(
      driverId,
      driverName: driverName,
      driverPhone: driverPhone,
    );
    _driverRequestProfile = fallback;
    notifyListeners();

    final requestVersion = ++_driverRequestVersion;
    final countryId = _countryId;
    try {
      var page = 1;
      while (true) {
        final queue = await _apiService.getVerificationQueue(
          page: page,
          countryId: countryId,
        );
        if (requestVersion != _driverRequestVersion) return;
        _driverRequestProfileQueueRawResponse = queue.rawResponse;
        for (final d in queue.results) {
          debugPrint(
            '[AdminProvider]   queue driver: '
            'id=${d.id}, name="${d.name}", phone="${d.phone}"',
          );
        }
        final match = queue.results
            .where(
              (d) => _matchesRequestedDriver(
                d,
                driverId,
                driverName: driverName,
                driverPhone: driverPhone,
              ),
            )
            .firstOrNull;
        if (match != null) {
          _driverRequestProfile = fallback != null
              ? match.mergeFallback(fallback)
              : match;
        }
        if (match != null || queue.next == null) break;
        page++;
      }
      debugPrint(
        '[AdminProvider] fetchDriverRequestProfile() '
        '${_driverRequestProfile != null ? 'FOUND (queue id=${_driverRequestProfile!.id})' : 'NOT FOUND'} '
        '(searched $page pages)',
      );
    } on ApiException catch (e) {
      debugPrint(
        '[AdminProvider] fetchDriverRequestProfile() queue FAILED: ${e.message}',
      );
    } catch (e) {
      debugPrint('[AdminProvider] fetchDriverRequestProfile() queue ERROR: $e');
    }

    if (requestVersion == _driverRequestVersion) {
      _driverRequestProfileLoading = false;
      notifyListeners();
    }
  }

  DriverProfile? _buildPendingDriverProfile(
    int driverId, {
    String? driverName,
    String? driverPhone,
  }) {
    final pending = pendingDrivers
        .where(
          (d) => _matchesDriverIdentity(
            candidateId: d.id,
            candidateName: d.name,
            candidatePhone: d.phone,
            requestedId: driverId,
            requestedName: driverName,
            requestedPhone: driverPhone,
          ),
        )
        .firstOrNull;
    if (pending != null) {
      return DriverProfile.fromPendingDriver(pending);
    }

    return null;
  }

  DriverProfile? _buildLiveDriverProfile(
    int driverId, {
    String? driverName,
    String? driverPhone,
  }) {
    final liveDriver = drivers
        .where(
          (d) => _matchesDriverIdentity(
            candidateId: d.id,
            candidateName: d.name,
            candidatePhone: d.phone,
            requestedId: driverId,
            requestedName: driverName,
            requestedPhone: driverPhone,
          ),
        )
        .firstOrNull;
    if (liveDriver != null) {
      return DriverProfile.fromDriverWithLocation(liveDriver);
    }

    return null;
  }

  bool _matchesRequestedDriver(
    DriverProfile profile,
    int driverId, {
    String? driverName,
    String? driverPhone,
  }) {
    return _matchesDriverIdentity(
      candidateId: profile.id,
      candidateName: profile.name,
      candidatePhone: profile.phone,
      requestedId: driverId,
      requestedName: driverName,
      requestedPhone: driverPhone,
    );
  }

  bool _matchesDriverIdentity({
    required int candidateId,
    String? candidateName,
    String? candidatePhone,
    required int requestedId,
    String? requestedName,
    String? requestedPhone,
  }) {
    if (candidateId != 0 && candidateId == requestedId) return true;

    final requestedPhoneNormalized = _normalizePhone(requestedPhone);
    final candidatePhoneNormalized = _normalizePhone(candidatePhone);
    if (requestedPhoneNormalized != null &&
        requestedPhoneNormalized == candidatePhoneNormalized) {
      return true;
    }

    final requestedNameNormalized = _normalizeName(requestedName);
    final candidateNameNormalized = _normalizeName(candidateName);
    if (requestedNameNormalized == null ||
        candidateNameNormalized != requestedNameNormalized) {
      return false;
    }

    if (requestedPhoneNormalized == null || candidatePhoneNormalized == null) {
      return true;
    }

    return requestedPhoneNormalized == candidatePhoneNormalized;
  }

  String? _normalizePhone(String? value) {
    if (value == null) return null;
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.isEmpty ? null : digitsOnly;
  }

  String? _normalizeName(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return normalized.isEmpty ? null : normalized;
  }

  void clearDriverProfile() {
    _driverProfile = null;
    notifyListeners();
  }

  void clearDriverRequestProfile() {
    _driverRequestProfile = null;
    _driverRequestProfileQueueRawResponse = null;
    notifyListeners();
  }

  // ─── Approval actions ────────────────────────────────────────────

  Future<Map<String, dynamic>> createDriver(
    Map<String, dynamic> payload,
  ) async {
    debugPrint('[AdminProvider] createDriver()');
    final created = await _apiService.createDriver(payload);
    await refreshHome();
    debugPrint('[AdminProvider] createDriver() SUCCESS');
    return created;
  }

  Future<Map<String, dynamic>> createRestaurant(
    Map<String, dynamic> payload,
  ) async {
    debugPrint('[AdminProvider] createRestaurant()');
    final created = await _apiService.createRestaurant(payload);
    await refreshHome();
    debugPrint('[AdminProvider] createRestaurant() SUCCESS');
    return created;
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> payload) async {
    debugPrint('[AdminProvider] createUser() role=${payload['role']}');
    final created = await _apiService.createUser(payload);
    debugPrint('[AdminProvider] createUser() SUCCESS');
    return created;
  }

  Future<Map<String, dynamic>> resetUserPassword({
    required int userId,
    required String password,
  }) async {
    debugPrint('[AdminProvider] resetUserPassword() userId=$userId');
    final updated = await _apiService.resetUserPassword(
      userId: userId,
      password: password,
    );
    debugPrint('[AdminProvider] resetUserPassword() SUCCESS');
    return updated;
  }

  Future<void> updateDriverStatus(
    int driverId, {
    required String status,
    String? notes,
  }) async {
    debugPrint(
      '[AdminProvider] updateDriverStatus() id=$driverId, status=$status',
    );
    await _apiService.updateDriverStatus(
      driverId,
      status: status,
      notes: notes,
    );
    if (status == 'APPROVED' || status == 'REJECTED') {
      _removePendingDriver(driverId);
    }
    _updateDriverStatusInState(driverId, status);
    debugPrint('[AdminProvider] updateDriverStatus() SUCCESS');
  }

  Future<void> activateRestaurant(int restaurantId) async {
    debugPrint('[AdminProvider] activateRestaurant() id=$restaurantId');
    await _apiService.activateRestaurant(restaurantId);
    _removePendingRestaurant(restaurantId);
    debugPrint(
      '[AdminProvider] activateRestaurant() SUCCESS — removed from pending list',
    );
  }

  void _removePendingDriver(int driverId) {
    _recentlyRemovedDriverIds.add(driverId);
    if (_homeData == null) return;
    final updated = _homeData!.pendingDrivers.results
        .where((d) => d.id != driverId)
        .toList();
    _homeData = HomeResponse(
      driversWithLocations: _homeData!.driversWithLocations,
      restaurants: _homeData!.restaurants,
      pendingDrivers: PaginatedResponse(
        count: _homeData!.pendingDrivers.count - 1,
        next: _homeData!.pendingDrivers.next,
        previous: _homeData!.pendingDrivers.previous,
        results: updated,
        rawResponse: _homeData!.pendingDrivers.rawResponse,
      ),
      pendingRestaurants: _homeData!.pendingRestaurants,
      ordersCountByStatus: _homeData!.ordersCountByStatus,
      driversCount: _homeData!.driversCount,
      rawResponse: _homeData!.rawResponse,
    );
    notifyListeners();
  }

  void _updateDriverStatusInState(int driverId, String status) {
    final normalizedStatus = status.toUpperCase();

    if (_driverProfile?.id == driverId) {
      final profile = _driverProfile!;
      _driverProfile = DriverProfile(
        id: profile.id,
        email: profile.email,
        name: profile.name,
        status: normalizedStatus,
        phone: profile.phone,
        vehicleType: profile.vehicleType,
        acceptsFood: profile.acceptsFood,
        acceptsShipping: profile.acceptsShipping,
        acceptsTaxi: profile.acceptsTaxi,
        drivingLicense: profile.drivingLicense,
        idDocument: profile.idDocument,
        otherDocuments: profile.otherDocuments,
        carSize: profile.carSize,
        vehiclePlateNumber: profile.vehiclePlateNumber,
        vehicleColor: profile.vehicleColor,
        vehicleMake: profile.vehicleMake,
        vehicleModel: profile.vehicleModel,
        vehicleYear: profile.vehicleYear,
        createdAt: profile.createdAt,
        submittedAt: profile.submittedAt,
        isOnline: normalizedStatus == 'SUSPENDED' ? false : profile.isOnline,
        latitude: profile.latitude,
        longitude: profile.longitude,
        locationUpdatedAt: profile.locationUpdatedAt,
        address: profile.address,
        documentItems: profile.documentItems,
        hasExtendedDetails: profile.hasExtendedDetails,
      );
    }

    if (_homeData != null) {
      final updatedDrivers = _homeData!.driversWithLocations.results
          .map(
            (driver) => driver.id != driverId
                ? driver
                : DriverWithLocation(
                    id: driver.id,
                    email: driver.email,
                    name: driver.name,
                    phone: driver.phone,
                    status: normalizedStatus,
                    isOnline: normalizedStatus == 'SUSPENDED'
                        ? false
                        : driver.isOnline,
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
                    latitude: driver.latitude,
                    longitude: driver.longitude,
                    locationUpdatedAt: driver.locationUpdatedAt,
                    address: driver.address,
                    documentItems: driver.documentItems,
                  ),
          )
          .toList();

      _homeData = HomeResponse(
        driversWithLocations: PaginatedResponse(
          count: _homeData!.driversWithLocations.count,
          next: _homeData!.driversWithLocations.next,
          previous: _homeData!.driversWithLocations.previous,
          results: updatedDrivers,
          rawResponse: _homeData!.driversWithLocations.rawResponse,
        ),
        restaurants: _homeData!.restaurants,
        pendingDrivers: _homeData!.pendingDrivers,
        pendingRestaurants: _homeData!.pendingRestaurants,
        ordersCountByStatus: _homeData!.ordersCountByStatus,
        driversCount: _homeData!.driversCount,
        rawResponse: _homeData!.rawResponse,
      );
    }

    notifyListeners();
  }

  void _removePendingRestaurant(int restaurantId) {
    _recentlyRemovedRestaurantIds.add(restaurantId);
    if (_homeData == null) return;
    final updated = _homeData!.pendingRestaurants.results
        .where((r) => r.id != restaurantId)
        .toList();
    _homeData = HomeResponse(
      driversWithLocations: _homeData!.driversWithLocations,
      restaurants: _homeData!.restaurants,
      pendingDrivers: _homeData!.pendingDrivers,
      pendingRestaurants: PaginatedResponse(
        count: _homeData!.pendingRestaurants.count - 1,
        next: _homeData!.pendingRestaurants.next,
        previous: _homeData!.pendingRestaurants.previous,
        results: updated,
        rawResponse: _homeData!.pendingRestaurants.rawResponse,
      ),
      ordersCountByStatus: _homeData!.ordersCountByStatus,
      driversCount: _homeData!.driversCount,
      rawResponse: _homeData!.rawResponse,
    );
    notifyListeners();
  }

  // ─── Support ticket API calls ───────────────────────────────────

  Future<void> fetchTickets({int? page}) async {
    debugPrint('[AdminProvider] fetchTickets() called, page=$page');
    final requestVersion = ++_ticketsRequestVersion;
    final countryId = _countryId;
    _ticketsLoading = true;
    _ticketsError = null;
    notifyListeners();

    try {
      final json = await _apiService.getTickets(
        page: page,
        countryId: countryId,
      );
      if (requestVersion != _ticketsRequestVersion) return;
      _ticketsTotal = json['count'] ?? 0;
      _tickets =
          (json['results'] as List<dynamic>?)
              ?.map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _ticketsError = null;
      debugPrint(
        '[AdminProvider] fetchTickets() SUCCESS — '
        'total: $_ticketsTotal, '
        'open: ${openTickets.length}, '
        'in-progress: ${inProgressTickets.length}, '
        'resolved: ${resolvedTickets.length}, '
        'closed: ${closedTickets.length}',
      );
      for (final t in _tickets) {
        debugPrint(
          '[AdminProvider]   Ticket #${t.id}: "${t.subject}" '
          '[${t.status}] [${t.priority}] category=${t.category}, '
          'requester="${t.requesterName}"',
        );
      }
    } on ApiException catch (e) {
      _ticketsError = e.message;
      debugPrint(
        '[AdminProvider] fetchTickets() FAILED: ${e.message} (${e.statusCode})',
      );
    } catch (e) {
      _ticketsError = 'Connection error. Please try again.';
      debugPrint('[AdminProvider] fetchTickets() ERROR: $e');
    } finally {
      if (requestVersion == _ticketsRequestVersion) {
        _ticketsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchTicketDetail(int ticketId) async {
    debugPrint('[AdminProvider] fetchTicketDetail() ticketId=$ticketId');
    _ticketDetailLoading = true;
    notifyListeners();

    try {
      _selectedTicket = await _apiService.getTicket(ticketId);
      debugPrint(
        '[AdminProvider] fetchTicketDetail() SUCCESS — '
        'Ticket #${_selectedTicket!.id}: "${_selectedTicket!.subject}" '
        '[${_selectedTicket!.status}] [${_selectedTicket!.priority}] '
        'messages: ${_selectedTicket!.messages.length}',
      );
      for (final m in _selectedTicket!.messages) {
        debugPrint(
          '[AdminProvider]   Message #${m.id} by "${m.authorName}" '
          '(${m.authorRole}): "${m.body.length > 80 ? '${m.body.substring(0, 80)}...' : m.body}"',
        );
      }
    } on ApiException catch (e) {
      _ticketsError = e.message;
      debugPrint(
        '[AdminProvider] fetchTicketDetail() FAILED: ${e.message} (${e.statusCode})',
      );
    } catch (e) {
      _ticketsError = 'Connection error. Please try again.';
      debugPrint('[AdminProvider] fetchTicketDetail() ERROR: $e');
    } finally {
      _ticketDetailLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedTicket() {
    debugPrint('[AdminProvider] clearSelectedTicket()');
    _selectedTicket = null;
    notifyListeners();
  }

  /// Clear all cached data and stop polling. Called on sign-out.
  void clearAll() {
    debugPrint('[AdminProvider] clearAll() — wiping cached data');
    stopPolling();
    _homeRequestVersion++;
    _ticketsRequestVersion++;
    _driverRequestVersion++;
    _homeData = null;
    _isLoading = false;
    _error = null;
    _tickets = [];
    _ticketsTotal = 0;
    _ticketsLoading = false;
    _ticketsError = null;
    _selectedTicket = null;
    _ticketDetailLoading = false;
    _driverProfile = null;
    _driverProfileLoading = false;
    _driverRequestProfile = null;
    _driverRequestProfileLoading = false;
    _driverRequestProfileQueueRawResponse = null;
    _countryId = null;
    _recentlyRemovedDriverIds.clear();
    _recentlyRemovedRestaurantIds.clear();
    notifyListeners();
  }

  Future<void> updateTicketStatus(int ticketId, String newStatus) async {
    debugPrint(
      '[AdminProvider] updateTicketStatus() ticketId=$ticketId, newStatus=$newStatus',
    );
    final updated = await _apiService.updateTicket(ticketId, status: newStatus);
    // Update in list
    _tickets = _tickets.map((t) => t.id == ticketId ? updated : t).toList();
    // Update detail if it's the selected ticket
    if (_selectedTicket?.id == ticketId) {
      _selectedTicket = updated;
    }
    debugPrint(
      '[AdminProvider] updateTicketStatus() SUCCESS — '
      'Ticket #${updated.id} now ${updated.status}',
    );
    notifyListeners();
  }

  Future<void> addTicketReply(int ticketId, String body) async {
    debugPrint(
      '[AdminProvider] addTicketReply() ticketId=$ticketId, '
      'body="${body.length > 60 ? '${body.substring(0, 60)}...' : body}"',
    );
    final message = await _apiService.addTicketMessage(ticketId, body: body);
    debugPrint(
      '[AdminProvider] addTicketReply() SUCCESS — '
      'Message #${message.id} by "${message.authorName}"',
    );
    // Append message to selected ticket detail
    if (_selectedTicket?.id == ticketId) {
      _selectedTicket = SupportTicket(
        id: _selectedTicket!.id,
        subject: _selectedTicket!.subject,
        category: _selectedTicket!.category,
        priority: _selectedTicket!.priority,
        status: _selectedTicket!.status,
        requester: _selectedTicket!.requester,
        requesterName: _selectedTicket!.requesterName,
        order: _selectedTicket!.order,
        restaurant: _selectedTicket!.restaurant,
        restaurantName: _selectedTicket!.restaurantName,
        driver: _selectedTicket!.driver,
        driverName: _selectedTicket!.driverName,
        assignedTo: _selectedTicket!.assignedTo,
        assignedToName: _selectedTicket!.assignedToName,
        createdAt: _selectedTicket!.createdAt,
        updatedAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        closedAt: _selectedTicket!.closedAt,
        messages: [..._selectedTicket!.messages, message],
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    debugPrint('[AdminProvider] dispose() — stopping polling & closing API');
    stopPolling();
    _countryFilter?.removeListener(_handleCountryChanged);
    _countryFilter?.unregisterConsumer('admin');
    _apiService.dispose();
    super.dispose();
  }
}
