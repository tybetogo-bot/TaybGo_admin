import 'dart:async';
import 'package:flutter/foundation.dart';
import '../partner_search.dart';
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
  int _driverProfileRequestVersion = 0;
  int _restaurantProfileRequestVersion = 0;
  int _driverRequestVersion = 0;

  HomeResponse? _homeData;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastHomeUpdatedAt;
  Object? _driverRequestProfileQueueRawResponse;

  // ─── Direct management data ────────────────────────────────────
  // The dashboard keeps using /api/admin/home/ because it includes live
  // driver-location ordering and aggregate order metrics. Management lists
  // use their dedicated paginated admin endpoints instead.
  PaginatedResponse<DriverWithLocation>? _managementDrivers;
  PaginatedResponse<HomeRestaurant>? _managementRestaurants;
  bool _managementDriversLoading = false;
  bool _managementRestaurantsLoading = false;
  String? _managementDriversError;
  String? _managementRestaurantsError;
  int _managementDriversRequestVersion = 0;
  int _managementRestaurantsRequestVersion = 0;
  String? _managementDriverSearch;
  String? _managementDriverStatus;
  bool? _managementDriverOnline;
  String? _managementRestaurantSearch;
  String? _managementRestaurantStatus;

  int _managementDriversSummaryTotal = 0;
  int _managementDriversSummaryOnline = 0;
  int _managementDriversSummaryOffline = 0;
  int _managementDriversSummarySuspended = 0;
  bool _hasManagementDriversSummary = false;
  int _managementRestaurantsSummaryTotal = 0;
  int _managementRestaurantsSummaryActive = 0;
  int _managementRestaurantsSummaryInactive = 0;
  int _managementRestaurantsSummaryOpen = 0;
  bool _hasManagementRestaurantsSummary = false;

  // ─── Direct approval data ──────────────────────────────────────
  PaginatedResponse<PendingDriver>? _approvalPendingDrivers;
  PaginatedResponse<PendingRestaurant>? _approvalPendingRestaurants;
  bool _approvalsLoading = false;
  String? _approvalsError;
  int _approvalsRequestVersion = 0;

  // ─── Ticket state ──────────────────────────────────────────────
  List<SupportTicket> _tickets = [];
  int _ticketsTotal = 0;
  String? _ticketsNext;
  String? _ticketsPrevious;
  int _ticketsPage = 1;
  bool _ticketsLoading = false;
  int? _ticketsLoadingRequestVersion;
  String? _ticketsError;
  SupportTicket? _selectedTicket;
  bool _ticketDetailLoading = false;
  int _ticketDetailRequestVersion = 0;

  // ─── Driver profile detail ────────────────────────────────────
  DriverProfile? get driverProfile => _driverProfile;
  bool get driverProfileLoading => _driverProfileLoading;
  DriverProfile? _driverProfile;
  bool _driverProfileLoading = false;

  HomeRestaurant? get restaurantProfile => _restaurantProfile;
  bool get restaurantProfileLoading => _restaurantProfileLoading;
  HomeRestaurant? _restaurantProfile;
  bool _restaurantProfileLoading = false;

  DriverProfile? _driverRequestProfile;
  bool _driverRequestProfileLoading = false;

  DriverProfile? get driverRequestProfile => _driverRequestProfile;
  bool get driverRequestProfileLoading => _driverRequestProfileLoading;
  Object? get driverRequestProfileQueueRawResponse =>
      _driverRequestProfileQueueRawResponse;

  // ─── Polling ───────────────────────────────────────────────────
  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 10);
  Timer? _supportPollTimer;
  int _supportPollGeneration = 0;
  bool _supportListPollInFlight = false;
  bool _supportPollRequestInFlight = false;
  static const _supportPollInterval = Duration(seconds: 3);

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

  List<DriverWithLocation> get managementDrivers =>
      _managementDrivers?.results ?? [];
  int get managementDriversTotal => _managementDrivers?.count ?? 0;
  bool get managementDriversLoading => _managementDriversLoading;
  String? get managementDriversError => _managementDriversError;
  int get managementDriversSummaryTotal => _hasManagementDriversSummary
      ? _managementDriversSummaryTotal
      : managementDriversTotal;
  int get managementDriversSummaryOnline => _hasManagementDriversSummary
      ? _managementDriversSummaryOnline
      : managementDrivers
            .where(
              (driver) =>
                  driver.isOnline && driver.status.toUpperCase() != 'SUSPENDED',
            )
            .length;
  int get managementDriversSummaryOffline => _hasManagementDriversSummary
      ? _managementDriversSummaryOffline
      : managementDrivers
            .where(
              (driver) =>
                  !driver.isOnline &&
                  driver.status.toUpperCase() != 'SUSPENDED',
            )
            .length;
  int get managementDriversSummarySuspended => _hasManagementDriversSummary
      ? _managementDriversSummarySuspended
      : managementDrivers
            .where((driver) => driver.status.toUpperCase() == 'SUSPENDED')
            .length;

  List<HomeRestaurant> get managementRestaurants =>
      _managementRestaurants?.results ?? [];
  int get managementRestaurantsTotal => _managementRestaurants?.count ?? 0;
  bool get managementRestaurantsLoading => _managementRestaurantsLoading;
  String? get managementRestaurantsError => _managementRestaurantsError;
  int get managementRestaurantsSummaryTotal => _hasManagementRestaurantsSummary
      ? _managementRestaurantsSummaryTotal
      : managementRestaurantsTotal;
  int get managementRestaurantsSummaryActive => _hasManagementRestaurantsSummary
      ? _managementRestaurantsSummaryActive
      : managementRestaurants
            .where((restaurant) => restaurant.effectiveStatus == 'ACTIVE')
            .length;
  int get managementRestaurantsSummaryInactive =>
      _hasManagementRestaurantsSummary
      ? _managementRestaurantsSummaryInactive
      : managementRestaurants
            .where((restaurant) => restaurant.effectiveStatus == 'INACTIVE')
            .length;
  int get managementRestaurantsSummaryOpen => _hasManagementRestaurantsSummary
      ? _managementRestaurantsSummaryOpen
      : managementRestaurants
            .where((restaurant) => restaurant.isOpenNow())
            .length;
  bool get managementLoading =>
      _managementDriversLoading || _managementRestaurantsLoading;
  String? get managementError =>
      _managementDriversError ?? _managementRestaurantsError;

  bool get approvalsLoading => _approvalsLoading;
  String? get approvalsError => _approvalsError;

  void _handleCountryChanged() {
    final countryFilter = _countryFilter;
    if (countryFilter == null) return;
    final nextCountryId = _countryFilter?.selectedCountryId;
    if (_countryId == nextCountryId) return;
    _countryId = nextCountryId;
    debugPrint('[AdminProvider] Country changed — refreshing home and tickets');
    final revision = countryFilter.revision;
    final refreshManagement =
        _managementDrivers != null || _managementRestaurants != null;
    unawaited(
      Future.wait<void>([
        fetchHome(),
        fetchTickets(page: 1),
        if (refreshManagement) fetchManagementData(),
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
      _approvalPendingDrivers?.results ??
      _homeData?.pendingDrivers.results ??
      [];

  int get pendingDriversTotal =>
      _approvalPendingDrivers?.count ?? _homeData?.pendingDrivers.count ?? 0;

  List<PendingRestaurant> get pendingRestaurants =>
      _approvalPendingRestaurants?.results ??
      _homeData?.pendingRestaurants.results ??
      [];

  int get pendingRestaurantsTotal =>
      _approvalPendingRestaurants?.count ??
      _homeData?.pendingRestaurants.count ??
      0;

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
  String? get ticketsNext => _ticketsNext;
  String? get ticketsPrevious => _ticketsPrevious;
  int get ticketsPage => _ticketsPage;
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
      debugPrint(
        '[AdminProvider] Poll tick — refreshing home, management + approvals',
      );
      _silentRefreshHome();
      // Support has its own 3-second poller while a support screen is open.
      // Avoid issuing a second ticket-list request from the general poller.
      if (_supportPollTimer == null) _silentRefreshTickets();
      _silentRefreshApprovals();
      _silentRefreshManagement();
    });
  }

  void stopPolling() {
    if (_pollTimer != null) {
      debugPrint('[AdminProvider] Stopping polling');
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  /// Poll support data only while the support list or a ticket detail is open.
  ///
  /// Ticket detail responses include the complete conversation, so the detail
  /// variant retrieves newly-created requester messages without disturbing the
  /// reply composer or showing a loading spinner on every poll tick.
  void startSupportPolling({int? ticketId}) {
    stopSupportPolling();
    final generation = _supportPollGeneration;
    final target = ticketId == null ? 'ticket list' : 'ticket #$ticketId';
    debugPrint(
      '[AdminProvider] Starting support polling for $target '
      '(every ${_supportPollInterval.inSeconds}s)',
    );
    _supportPollTimer = Timer.periodic(_supportPollInterval, (_) {
      if (generation != _supportPollGeneration) return;
      if (ticketId == null) {
        _pollSupportList(generation);
      } else {
        _silentRefreshTicketDetail(ticketId, generation);
      }
    });
  }

  void stopSupportPolling() {
    _supportPollGeneration++;
    if (_supportPollTimer != null) {
      debugPrint('[AdminProvider] Stopping support polling');
      _supportPollTimer?.cancel();
      _supportPollTimer = null;
    }
    _supportListPollInFlight = false;
    _supportPollRequestInFlight = false;
  }

  void _pollSupportList(int generation) {
    if (_supportListPollInFlight) return;
    _supportListPollInFlight = true;
    unawaited(
      _silentRefreshTickets().whenComplete(() {
        if (generation == _supportPollGeneration) {
          _supportListPollInFlight = false;
        }
      }),
    );
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

  /// Refresh approval lists from their dedicated paginated admin endpoints.
  /// Pending drivers come from the verification queue; pending restaurants are
  /// the direct restaurant list filtered by `status=PENDING`.
  Future<void> fetchApprovals({bool silent = false}) async {
    final requestVersion = ++_approvalsRequestVersion;
    if (!silent) {
      _approvalsLoading = true;
      _approvalsError = null;
      notifyListeners();
    }

    try {
      final driverFuture = _loadAllVerificationQueue(countryId: _countryId);
      final restaurantFuture = _loadAllAdminRestaurants(
        countryId: _countryId,
        status: 'PENDING',
      );
      final driverPage = await driverFuture;
      final restaurantPage = await restaurantFuture;
      if (requestVersion != _approvalsRequestVersion) return;

      final pendingDrivers = driverPage.results
          .where((driver) => !_recentlyRemovedDriverIds.contains(driver.id))
          .map(
            (driver) => PendingDriver(
              id: driver.id,
              name: driver.name,
              phone: driver.phone ?? '',
              status: driver.status,
              submittedAt: driver.submittedAt,
              address: driver.address,
            ),
          )
          .toList();
      final pendingRestaurants = restaurantPage.results
          .where(
            (restaurant) =>
                !_recentlyRemovedRestaurantIds.contains(restaurant.id),
          )
          .map(
            (restaurant) => PendingRestaurant(
              id: restaurant.id,
              name: restaurant.name,
              status: restaurant.status,
              submittedAt: restaurant.createdAt,
            ),
          )
          .toList();

      _approvalPendingDrivers = PaginatedResponse(
        count:
            driverPage.count -
            (driverPage.results.length - pendingDrivers.length),
        next: null,
        previous: null,
        results: pendingDrivers,
        rawResponse: driverPage.rawResponse,
      );
      _approvalPendingRestaurants = PaginatedResponse(
        count:
            restaurantPage.count -
            (restaurantPage.results.length - pendingRestaurants.length),
        next: null,
        previous: null,
        results: pendingRestaurants,
        rawResponse: restaurantPage.rawResponse,
      );

      final serverDriverIds = driverPage.results
          .map((driver) => driver.id)
          .toSet();
      _recentlyRemovedDriverIds.removeWhere(
        (id) => !serverDriverIds.contains(id),
      );
      final serverRestaurantIds = restaurantPage.results
          .map((restaurant) => restaurant.id)
          .toSet();
      _recentlyRemovedRestaurantIds.removeWhere(
        (id) => !serverRestaurantIds.contains(id),
      );
      _approvalsError = null;
    } on ApiException catch (e) {
      if (requestVersion == _approvalsRequestVersion) {
        _approvalsError = e.message;
      }
      debugPrint('[AdminProvider] fetchApprovals() FAILED: ${e.message}');
    } catch (e) {
      if (requestVersion == _approvalsRequestVersion) {
        _approvalsError = 'Connection error. Please try again.';
      }
      debugPrint('[AdminProvider] fetchApprovals() ERROR: $e');
    } finally {
      if (requestVersion == _approvalsRequestVersion) {
        _approvalsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _silentRefreshApprovals() async {
    await fetchApprovals(silent: true);
  }

  Future<PaginatedResponse<DriverProfile>> _loadAllVerificationQueue({
    required int? countryId,
  }) async {
    var page = 1;
    var current = await _apiService.getVerificationQueue(
      page: page,
      countryId: countryId,
    );
    final results = <DriverProfile>[];
    final seenIds = <int>{};

    void append(List<DriverProfile> items) {
      for (final item in items) {
        if (seenIds.add(item.id)) results.add(item);
      }
    }

    append(current.results);
    while (current.next != null &&
        results.length < current.count &&
        page < 1000) {
      page++;
      current = await _apiService.getVerificationQueue(
        page: page,
        countryId: countryId,
      );
      final before = results.length;
      append(current.results);
      if (before == results.length) break;
    }

    return PaginatedResponse(
      count: current.count,
      next: null,
      previous: null,
      results: results,
      rawResponse: current.rawResponse,
    );
  }

  /// Refresh tickets silently (no loading indicator).
  Future<void> _silentRefreshTickets() async {
    // Never let a background poll supersede a foreground refresh. The latter
    // owns the loading state and must be allowed to clear it in its finally
    // block even when a response is slow.
    if (_ticketsLoading) return;
    final requestVersion = ++_ticketsRequestVersion;
    final countryId = _countryId;
    try {
      final json = await _apiService.getTickets(
        page: _ticketsPage,
        countryId: countryId,
      );
      if (requestVersion != _ticketsRequestVersion) return;
      _ticketsTotal = json['count'] ?? 0;
      _ticketsNext = json['next']?.toString();
      _ticketsPrevious = json['previous']?.toString();
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

  /// Refresh the selected ticket conversation silently.
  Future<void> _silentRefreshTicketDetail(int ticketId, int generation) async {
    if (_supportPollRequestInFlight || _selectedTicket?.id != ticketId) return;

    _supportPollRequestInFlight = true;
    final requestVersion = ++_ticketDetailRequestVersion;
    try {
      final latest = await _apiService.getTicket(ticketId);
      if (generation != _supportPollGeneration ||
          requestVersion != _ticketDetailRequestVersion ||
          _selectedTicket?.id != ticketId) {
        return;
      }

      final current = _selectedTicket;
      if (current == null || _ticketChanged(current, latest)) {
        _selectedTicket = latest;
        debugPrint(
          '[AdminProvider] Silent support detail refresh OK — '
          'Ticket #$ticketId, messages: ${latest.messages.length}',
        );
        notifyListeners();
      }
    } on ApiException catch (e) {
      // A transient polling failure must not replace the visible conversation
      // or show an error state over content that is still usable.
      debugPrint(
        '[AdminProvider] Silent support detail refresh FAILED: ${e.message}',
      );
    } catch (e) {
      debugPrint('[AdminProvider] Silent support detail refresh ERROR: $e');
    } finally {
      if (generation == _supportPollGeneration) {
        _supportPollRequestInFlight = false;
      }
    }
  }

  bool _ticketChanged(SupportTicket current, SupportTicket latest) {
    if (current.id != latest.id ||
        current.subject != latest.subject ||
        current.category != latest.category ||
        current.priority != latest.priority ||
        current.status != latest.status ||
        current.requester != latest.requester ||
        current.requesterName != latest.requesterName ||
        current.order != latest.order ||
        current.restaurant != latest.restaurant ||
        current.restaurantName != latest.restaurantName ||
        current.driver != latest.driver ||
        current.driverName != latest.driverName ||
        current.assignedTo != latest.assignedTo ||
        current.assignedToName != latest.assignedToName ||
        current.createdAt != latest.createdAt ||
        current.updatedAt != latest.updatedAt ||
        current.lastActivityAt != latest.lastActivityAt ||
        current.closedAt != latest.closedAt ||
        current.messages.length != latest.messages.length) {
      return true;
    }

    for (var i = 0; i < current.messages.length; i++) {
      final oldMessage = current.messages[i];
      final newMessage = latest.messages[i];
      if (oldMessage.id != newMessage.id ||
          oldMessage.author != newMessage.author ||
          oldMessage.authorName != newMessage.authorName ||
          oldMessage.authorRole != newMessage.authorRole ||
          oldMessage.body != newMessage.body ||
          oldMessage.createdAt != newMessage.createdAt ||
          oldMessage.attachments.length != newMessage.attachments.length) {
        return true;
      }
    }
    return false;
  }

  // ─── API calls ──────────────────────────────────────────────────

  static const _driversPageSize = 100;
  static const _restaurantsPageSize = 100;

  /// Load the management driver collection from the dedicated admin route.
  ///
  /// The current management UI has no visible page controls, so this follows
  /// the endpoint's `next` links and keeps the complete filtered collection in
  /// memory. The requests still use the server-side contract filters.
  Future<void> fetchManagementDrivers({
    String? search,
    String? status,
    bool? isOnline,
    bool silent = false,
  }) async {
    final requestVersion = ++_managementDriversRequestVersion;
    final backendSearch = search == null
        ? ''
        : backendPartnerSearchQuery(search);
    final normalizedSearch = backendSearch.isEmpty ? null : backendSearch;
    final normalizedStatus = status?.trim().isEmpty == true
        ? null
        : status?.trim().toUpperCase();
    _managementDriverSearch = normalizedSearch;
    _managementDriverStatus = normalizedStatus;
    _managementDriverOnline = isOnline;

    if (!silent) {
      _managementDriversLoading = true;
      _managementDriversError = null;
      notifyListeners();
    }

    try {
      final data = await _loadAllAdminDrivers(
        countryId: _countryId,
        search: normalizedSearch,
        status: normalizedStatus,
        isOnline: isOnline,
      );
      if (requestVersion != _managementDriversRequestVersion) return;
      _managementDrivers = data;
      if (normalizedSearch == null &&
          normalizedStatus == null &&
          isOnline == null) {
        _managementDriversSummaryTotal = data.count;
        _managementDriversSummaryOnline = data.results
            .where(
              (driver) =>
                  driver.isOnline && driver.status.toUpperCase() != 'SUSPENDED',
            )
            .length;
        _managementDriversSummarySuspended = data.results
            .where((driver) => driver.status.toUpperCase() == 'SUSPENDED')
            .length;
        _managementDriversSummaryOffline = data.results
            .where(
              (driver) =>
                  !driver.isOnline &&
                  driver.status.toUpperCase() != 'SUSPENDED',
            )
            .length;
        _hasManagementDriversSummary = true;
      }
      _managementDriversError = null;
    } on ApiException catch (e) {
      if (requestVersion == _managementDriversRequestVersion) {
        _managementDriversError = e.message;
      }
      debugPrint(
        '[AdminProvider] fetchManagementDrivers() FAILED: ${e.message}',
      );
    } catch (e) {
      if (requestVersion == _managementDriversRequestVersion) {
        _managementDriversError = 'Connection error. Please try again.';
      }
      debugPrint('[AdminProvider] fetchManagementDrivers() ERROR: $e');
    } finally {
      if (requestVersion == _managementDriversRequestVersion) {
        _managementDriversLoading = false;
        notifyListeners();
      }
    }
  }

  /// Load the management restaurant collection from the dedicated admin route.
  Future<void> fetchManagementRestaurants({
    String? search,
    String? status,
    bool silent = false,
  }) async {
    final requestVersion = ++_managementRestaurantsRequestVersion;
    final backendSearch = search == null
        ? ''
        : backendPartnerSearchQuery(search);
    final normalizedSearch = backendSearch.isEmpty ? null : backendSearch;
    final normalizedStatus = status?.trim().isEmpty == true
        ? null
        : status?.trim().toUpperCase();
    _managementRestaurantSearch = normalizedSearch;
    _managementRestaurantStatus = normalizedStatus;

    if (!silent) {
      _managementRestaurantsLoading = true;
      _managementRestaurantsError = null;
      notifyListeners();
    }

    try {
      final data = await _loadAllAdminRestaurants(
        countryId: _countryId,
        search: normalizedSearch,
        status: normalizedStatus,
      );
      if (requestVersion != _managementRestaurantsRequestVersion) return;
      _managementRestaurants = data;
      if (normalizedSearch == null && normalizedStatus == null) {
        _managementRestaurantsSummaryTotal = data.count;
        _managementRestaurantsSummaryActive = data.results
            .where((restaurant) => restaurant.effectiveStatus == 'ACTIVE')
            .length;
        _managementRestaurantsSummaryInactive = data.results
            .where((restaurant) => restaurant.effectiveStatus == 'INACTIVE')
            .length;
        _managementRestaurantsSummaryOpen = data.results
            .where((restaurant) => restaurant.isOpenNow())
            .length;
        _hasManagementRestaurantsSummary = true;
      }
      _managementRestaurantsError = null;
    } on ApiException catch (e) {
      if (requestVersion == _managementRestaurantsRequestVersion) {
        _managementRestaurantsError = e.message;
      }
      debugPrint(
        '[AdminProvider] fetchManagementRestaurants() FAILED: ${e.message}',
      );
    } catch (e) {
      if (requestVersion == _managementRestaurantsRequestVersion) {
        _managementRestaurantsError = 'Connection error. Please try again.';
      }
      debugPrint('[AdminProvider] fetchManagementRestaurants() ERROR: $e');
    } finally {
      if (requestVersion == _managementRestaurantsRequestVersion) {
        _managementRestaurantsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchManagementData({bool silent = false}) async {
    await Future.wait<void>([
      fetchManagementDrivers(
        search: _managementDriverSearch,
        status: _managementDriverStatus,
        isOnline: _managementDriverOnline,
        silent: silent,
      ),
      fetchManagementRestaurants(
        search: _managementRestaurantSearch,
        status: _managementRestaurantStatus,
        silent: silent,
      ),
    ]);
  }

  Future<void> refreshManagementData() => fetchManagementData();

  Future<void> _silentRefreshManagement() async {
    if (_managementDrivers == null && _managementRestaurants == null) return;
    await fetchManagementData(silent: true);
  }

  Future<PaginatedResponse<DriverWithLocation>> _loadAllAdminDrivers({
    required int? countryId,
    String? search,
    String? status,
    bool? isOnline,
  }) async {
    var page = 1;
    var current = await _apiService.getAdminDrivers(
      page: page,
      countryId: countryId,
      search: search,
      status: status,
      isOnline: isOnline,
    );
    final results = <DriverWithLocation>[];
    final seenIds = <int>{};

    void append(List<DriverWithLocation> items) {
      for (final item in items) {
        if (seenIds.add(item.id)) results.add(item);
      }
    }

    append(current.results);
    while (current.next != null &&
        results.length < current.count &&
        page < 1000) {
      page++;
      current = await _apiService.getAdminDrivers(
        page: page,
        countryId: countryId,
        search: search,
        status: status,
        isOnline: isOnline,
      );
      final before = results.length;
      append(current.results);
      if (before == results.length) break;
    }

    return PaginatedResponse(
      count: current.count,
      next: null,
      previous: null,
      results: results,
      rawResponse: current.rawResponse,
    );
  }

  Future<PaginatedResponse<HomeRestaurant>> _loadAllAdminRestaurants({
    required int? countryId,
    String? search,
    String? status,
  }) async {
    var page = 1;
    var current = await _apiService.getAdminRestaurants(
      page: page,
      countryId: countryId,
      search: search,
      status: status,
    );
    final results = <HomeRestaurant>[];
    final seenIds = <int>{};

    void append(List<HomeRestaurant> items) {
      for (final item in items) {
        if (seenIds.add(item.id)) results.add(item);
      }
    }

    append(current.results);
    while (current.next != null &&
        results.length < current.count &&
        page < 1000) {
      page++;
      current = await _apiService.getAdminRestaurants(
        page: page,
        countryId: countryId,
        search: search,
        status: status,
      );
      final before = results.length;
      append(current.results);
      if (before == results.length) break;
    }

    return PaginatedResponse(
      count: current.count,
      next: null,
      previous: null,
      results: results,
      rawResponse: current.rawResponse,
    );
  }

  /// Load the full partner collections used by the management screen.
  ///
  /// The home endpoint paginates each section independently. The management UI
  /// does not expose pagination, so aggregate every page before deriving its
  /// counts, filters, and local search results.
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
      restaurantsPage: 1,
      restaurantsPageSize: _restaurantsPageSize,
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
        restaurantsPage: 1,
        restaurantsPageSize: _restaurantsPageSize,
      );

      final before = allDrivers.length;
      appendDrivers(current.driversWithLocations.results);
      if (allDrivers.length == before) break;
    }

    final expectedRestaurantCount = base.restaurants.count;
    final allRestaurants = <HomeRestaurant>[];
    final seenRestaurantIds = <int>{};

    void appendRestaurants(List<HomeRestaurant> page) {
      for (final restaurant in page) {
        if (seenRestaurantIds.add(restaurant.id)) {
          allRestaurants.add(restaurant);
        }
      }
    }

    appendRestaurants(base.restaurants.results);

    var currentRestaurantPage = 1;
    var currentRestaurantResponse = base;
    while (allRestaurants.length < expectedRestaurantCount &&
        currentRestaurantResponse.restaurants.next != null &&
        currentRestaurantPage < 1000) {
      currentRestaurantPage++;
      currentRestaurantResponse = await _apiService.getHome(
        countryId: countryId,
        driverSearch: driverSearch,
        restaurantSearch: restaurantSearch,
        orderType: orderType,
        driversPage: 1,
        driversPageSize: _driversPageSize,
        restaurantsPage: currentRestaurantPage,
        restaurantsPageSize: _restaurantsPageSize,
      );

      final before = allRestaurants.length;
      appendRestaurants(currentRestaurantResponse.restaurants.results);
      if (allRestaurants.length == before) break;
    }

    final drivers =
        allDrivers.length == base.driversWithLocations.results.length
        ? base.driversWithLocations
        : PaginatedResponse(
            count: expectedCount,
            next: null,
            previous: null,
            results: allDrivers,
            rawResponse: base.driversWithLocations.rawResponse,
          );
    final restaurants = allRestaurants.length == base.restaurants.results.length
        ? base.restaurants
        : PaginatedResponse(
            count: expectedRestaurantCount,
            next: null,
            previous: null,
            results: allRestaurants,
            rawResponse: base.restaurants.rawResponse,
          );

    if (identical(drivers, base.driversWithLocations) &&
        identical(restaurants, base.restaurants)) {
      return base;
    }

    return HomeResponse(
      driversWithLocations: drivers,
      restaurants: restaurants,
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
      // Keep dashboard metrics and live-location ordering from /home, while
      // sourcing approval rows from the dedicated paginated admin endpoints.
      await fetchApprovals(silent: true);
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
    if (_managementDrivers != null || _managementRestaurants != null) {
      await fetchManagementData();
    }
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
    final requestVersion = ++_driverProfileRequestVersion;
    _driverProfileLoading = true;
    final fallback = _buildLiveDriverProfile(
      driverId,
      driverName: driverName,
      driverPhone: driverPhone,
    );
    _driverProfile = fallback;
    notifyListeners();

    try {
      final fetched = await _apiService.getAdminDriver(driverId);
      if (requestVersion != _driverProfileRequestVersion) return;
      _driverProfile = fallback == null
          ? fetched
          : fetched.mergeFallback(fallback);
      debugPrint(
        '[AdminProvider] fetchDriverProfile() FOUND '
        '(admin detail id=${_driverProfile!.id})',
      );
    } on ApiException catch (e) {
      debugPrint('[AdminProvider] fetchDriverProfile() FAILED: ${e.message}');
    } catch (e) {
      debugPrint('[AdminProvider] fetchDriverProfile() ERROR: $e');
    }

    if (requestVersion == _driverProfileRequestVersion) {
      _driverProfileLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRestaurant(int restaurantId) async {
    debugPrint('[AdminProvider] fetchRestaurant() restaurantId=$restaurantId');
    final requestVersion = ++_restaurantProfileRequestVersion;
    _restaurantProfileLoading = true;
    _restaurantProfile = _managementRestaurants?.results
        .where((restaurant) => restaurant.id == restaurantId)
        .firstOrNull;
    notifyListeners();

    try {
      final fetched = await _apiService.getAdminRestaurant(restaurantId);
      if (requestVersion != _restaurantProfileRequestVersion) return;
      _restaurantProfile = fetched;
      debugPrint(
        '[AdminProvider] fetchRestaurant() FOUND '
        '(admin detail id=${fetched.id})',
      );
    } on ApiException catch (e) {
      debugPrint('[AdminProvider] fetchRestaurant() FAILED: ${e.message}');
    } catch (e) {
      debugPrint('[AdminProvider] fetchRestaurant() ERROR: $e');
    }

    if (requestVersion == _restaurantProfileRequestVersion) {
      _restaurantProfileLoading = false;
      notifyListeners();
    }
  }

  /// Refetch the restaurant detail after a status mutation.
  ///
  /// Unlike [fetchRestaurant], this method propagates the response error so a
  /// detail screen can distinguish a missing restaurant, a permission error,
  /// or a temporary server failure. The previous profile is never changed
  /// optimistically.
  Future<HomeRestaurant> refreshRestaurantProfile(int restaurantId) async {
    debugPrint(
      '[AdminProvider] refreshRestaurantProfile() restaurantId=$restaurantId',
    );
    final requestVersion = ++_restaurantProfileRequestVersion;
    _restaurantProfileLoading = true;
    notifyListeners();

    try {
      final fetched = await _apiService.getAdminRestaurant(restaurantId);
      if (requestVersion == _restaurantProfileRequestVersion) {
        _restaurantProfile = fetched;
      }
      return fetched;
    } on ApiException catch (e) {
      if (e.statusCode == 404 &&
          requestVersion == _restaurantProfileRequestVersion) {
        _restaurantProfile = null;
      }
      rethrow;
    } finally {
      if (requestVersion == _restaurantProfileRequestVersion) {
        _restaurantProfileLoading = false;
        notifyListeners();
      }
    }
  }

  /// Reconcile an ambiguous mutation without exposing a second error to UI.
  Future<HomeRestaurant?> tryRefreshRestaurantProfile(int restaurantId) async {
    try {
      return await refreshRestaurantProfile(restaurantId);
    } catch (e) {
      debugPrint('[AdminProvider] tryRefreshRestaurantProfile() FAILED: $e');
      return null;
    }
  }

  void clearRestaurantProfile() {
    _restaurantProfileRequestVersion++;
    _restaurantProfile = null;
    _restaurantProfileLoading = false;
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
    _driverProfileRequestVersion++;
    _driverProfile = null;
    _driverProfileLoading = false;
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
    if (_managementDrivers != null) {
      await fetchManagementDrivers(
        search: _managementDriverSearch,
        status: _managementDriverStatus,
        isOnline: _managementDriverOnline,
        silent: true,
      );
    }
    if (status == 'APPROVED' || status == 'REJECTED') {
      await fetchApprovals(silent: true);
    }
    debugPrint('[AdminProvider] updateDriverStatus() SUCCESS');
  }

  /// Refresh the currently loaded restaurant collection using the exact
  /// search, status, country, and page traversal state already in use.
  Future<void> refreshManagementRestaurants() async {
    if (_managementRestaurants == null) return;
    await fetchManagementRestaurants(
      search: _managementRestaurantSearch,
      status: _managementRestaurantStatus,
      silent: true,
    );
  }

  Future<HomeRestaurant> _runRestaurantStatusAction({
    required int restaurantId,
    required String action,
    required Future<void> Function() request,
  }) async {
    debugPrint(
      '[AdminProvider] restaurant status action=$action id=$restaurantId',
    );
    var refreshList = true;
    try {
      await request();
      // The POST response is intentionally empty. Read the backend state
      // before exposing the changed status to the UI.
      return await refreshRestaurantProfile(restaurantId);
    } on ApiException catch (e) {
      // A conflict may mean another admin changed the record. Reconcile it
      // before surfacing the backend message to the caller.
      if (e.statusCode == 409) {
        await tryRefreshRestaurantProfile(restaurantId);
      }
      // Avoid issuing a second unauthorized request after the auth callback
      // has already started the sign-in redirect.
      refreshList = e.statusCode != 401 && e.statusCode != 403;
      rethrow;
    } finally {
      if (refreshList) {
        await refreshManagementRestaurants();
      }
    }
  }

  /// Activate an existing restaurant from its detail screen.
  Future<HomeRestaurant> activateRestaurantFromDetail(int restaurantId) {
    return _runRestaurantStatusAction(
      restaurantId: restaurantId,
      action: 'activate',
      request: () => _apiService.activateRestaurant(restaurantId),
    );
  }

  /// Deactivate an active restaurant from its detail screen.
  Future<HomeRestaurant> deactivateRestaurantFromDetail(int restaurantId) {
    return _runRestaurantStatusAction(
      restaurantId: restaurantId,
      action: 'deactivate',
      request: () => _apiService.deactivateRestaurant(restaurantId),
    );
  }

  Future<void> activateRestaurant(int restaurantId) async {
    debugPrint('[AdminProvider] activateRestaurant() id=$restaurantId');
    await _apiService.activateRestaurant(restaurantId);
    _removePendingRestaurant(restaurantId);
    if (_managementRestaurants != null) {
      await fetchManagementRestaurants(
        search: _managementRestaurantSearch,
        status: _managementRestaurantStatus,
        silent: true,
      );
    }
    await fetchApprovals(silent: true);
    debugPrint(
      '[AdminProvider] activateRestaurant() SUCCESS — removed from pending list',
    );
  }

  void _removePendingDriver(int driverId) {
    _recentlyRemovedDriverIds.add(driverId);
    if (_approvalPendingDrivers != null) {
      final updated = _approvalPendingDrivers!.results
          .where((d) => d.id != driverId)
          .toList();
      if (updated.length != _approvalPendingDrivers!.results.length) {
        _approvalPendingDrivers = PaginatedResponse(
          count: (_approvalPendingDrivers!.count - 1).clamp(0, 1 << 30),
          next: _approvalPendingDrivers!.next,
          previous: _approvalPendingDrivers!.previous,
          results: updated,
          rawResponse: _approvalPendingDrivers!.rawResponse,
        );
      }
    }
    if (_homeData == null) {
      notifyListeners();
      return;
    }
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
    if (_approvalPendingRestaurants != null) {
      final updated = _approvalPendingRestaurants!.results
          .where((r) => r.id != restaurantId)
          .toList();
      if (updated.length != _approvalPendingRestaurants!.results.length) {
        _approvalPendingRestaurants = PaginatedResponse(
          count: (_approvalPendingRestaurants!.count - 1).clamp(0, 1 << 30),
          next: _approvalPendingRestaurants!.next,
          previous: _approvalPendingRestaurants!.previous,
          results: updated,
          rawResponse: _approvalPendingRestaurants!.rawResponse,
        );
      }
    }
    if (_homeData == null) {
      notifyListeners();
      return;
    }
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
    final requestedPage = page ?? 1;
    _ticketsLoading = true;
    _ticketsLoadingRequestVersion = requestVersion;
    _ticketsError = null;
    notifyListeners();

    try {
      final json = await _apiService.getTickets(
        page: requestedPage,
        countryId: countryId,
      );
      if (requestVersion != _ticketsRequestVersion) return;
      _ticketsTotal = json['count'] ?? 0;
      _ticketsNext = json['next']?.toString();
      _ticketsPrevious = json['previous']?.toString();
      _ticketsPage = requestedPage;
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
      if (_ticketsLoadingRequestVersion == requestVersion) {
        _ticketsLoading = false;
      }
      if (requestVersion == _ticketsRequestVersion) {
        notifyListeners();
      }
    }
  }

  Future<void> fetchTicketDetail(int ticketId) async {
    debugPrint('[AdminProvider] fetchTicketDetail() ticketId=$ticketId');
    final requestVersion = ++_ticketDetailRequestVersion;
    _ticketDetailLoading = true;
    notifyListeners();

    try {
      final ticket = await _apiService.getTicket(ticketId);
      if (requestVersion != _ticketDetailRequestVersion) return;
      _selectedTicket = ticket;
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
      if (requestVersion == _ticketDetailRequestVersion) {
        _ticketDetailLoading = false;
        notifyListeners();
      }
    }
  }

  void clearSelectedTicket() {
    debugPrint('[AdminProvider] clearSelectedTicket()');
    _ticketDetailRequestVersion++;
    _selectedTicket = null;
    notifyListeners();
  }

  /// Clear all cached data and stop polling. Called on sign-out.
  void clearAll() {
    debugPrint('[AdminProvider] clearAll() — wiping cached data');
    stopPolling();
    stopSupportPolling();
    _homeRequestVersion++;
    _ticketsRequestVersion++;
    _managementDriversRequestVersion++;
    _managementRestaurantsRequestVersion++;
    _approvalsRequestVersion++;
    _driverProfileRequestVersion++;
    _restaurantProfileRequestVersion++;
    _driverRequestVersion++;
    _ticketDetailRequestVersion++;
    _homeData = null;
    _isLoading = false;
    _error = null;
    _tickets = [];
    _ticketsTotal = 0;
    _ticketsNext = null;
    _ticketsPrevious = null;
    _ticketsPage = 1;
    _ticketsLoading = false;
    _ticketsLoadingRequestVersion = null;
    _ticketsError = null;
    _selectedTicket = null;
    _ticketDetailLoading = false;
    _driverProfile = null;
    _driverProfileLoading = false;
    _restaurantProfile = null;
    _restaurantProfileLoading = false;
    _driverRequestProfile = null;
    _driverRequestProfileLoading = false;
    _driverRequestProfileQueueRawResponse = null;
    _countryId = null;
    _managementDrivers = null;
    _managementRestaurants = null;
    _managementDriversLoading = false;
    _managementRestaurantsLoading = false;
    _managementDriversError = null;
    _managementRestaurantsError = null;
    _managementDriverSearch = null;
    _managementDriverStatus = null;
    _managementDriverOnline = null;
    _managementRestaurantSearch = null;
    _managementRestaurantStatus = null;
    _hasManagementDriversSummary = false;
    _hasManagementRestaurantsSummary = false;
    _approvalsLoading = false;
    _approvalsError = null;
    _approvalPendingDrivers = null;
    _approvalPendingRestaurants = null;
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
    stopSupportPolling();
    _countryFilter?.removeListener(_handleCountryChanged);
    _countryFilter?.unregisterConsumer('admin');
    _apiService.dispose();
    super.dispose();
  }
}
