import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/home_response.dart';
import '../models/support_ticket.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _apiService;
  ApiService get apiService => _apiService;

  HomeResponse? _homeData;
  bool _isLoading = false;
  String? _error;

  // ─── Ticket state ──────────────────────────────────────────────
  List<SupportTicket> _tickets = [];
  int _ticketsTotal = 0;
  bool _ticketsLoading = false;
  String? _ticketsError;
  SupportTicket? _selectedTicket;
  bool _ticketDetailLoading = false;

  // ─── Driver profile detail ────────────────────────────────────
  DriverProfile? _driverProfile;
  bool _driverProfileLoading = false;

  DriverProfile? get driverProfile => _driverProfile;
  bool get driverProfileLoading => _driverProfileLoading;

  // ─── Polling ───────────────────────────────────────────────────
  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 10);

  // Track recently approved/removed IDs so polling doesn't re-add them
  final Set<int> _recentlyRemovedDriverIds = {};
  final Set<int> _recentlyRemovedRestaurantIds = {};

  AdminProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  // ─── State getters ──────────────────────────────────────────────

  HomeResponse? get homeData => _homeData;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    try {
      final data = await _apiService.getHome();

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
        ),
        pendingRestaurants: PaginatedResponse(
          count:
              data.pendingRestaurants.count -
              (data.pendingRestaurants.results.length -
                  filteredRestaurants.length),
          next: data.pendingRestaurants.next,
          previous: data.pendingRestaurants.previous,
          results: filteredRestaurants,
        ),
        ordersCountByStatus: data.ordersCountByStatus,
        driversCount: data.driversCount,
      );
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
    try {
      final json = await _apiService.getTickets();
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

  Future<void> fetchHome({
    String? driverSearch,
    String? restaurantSearch,
    String? orderType,
  }) async {
    debugPrint('[AdminProvider] fetchHome() called');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _homeData = await _apiService.getHome(
        driverSearch: driverSearch,
        restaurantSearch: restaurantSearch,
        orderType: orderType,
      );
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
      _isLoading = false;
      notifyListeners();
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
    final fallback = _buildCachedDriverProfile(
      driverId,
      driverName: driverName,
      driverPhone: driverPhone,
    );
    _driverProfile = fallback;
    notifyListeners();

    try {
      var page = 1;
      while (true) {
        final queue = await _apiService.getVerificationQueue(page: page);
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
          _driverProfile = fallback != null
              ? match.mergeFallback(fallback)
              : match;
        }
        if (match != null || queue.next == null) break;
        page++;
      }
      debugPrint(
        '[AdminProvider] fetchDriverProfile() '
        '${_driverProfile != null ? 'FOUND (queue id=${_driverProfile!.id})' : 'NOT FOUND'} '
        '(searched $page pages)',
      );
    } on ApiException catch (e) {
      debugPrint(
        '[AdminProvider] fetchDriverProfile() queue FAILED: ${e.message}',
      );
    } catch (e) {
      debugPrint('[AdminProvider] fetchDriverProfile() queue ERROR: $e');
    }

    _driverProfileLoading = false;
    notifyListeners();
  }

  DriverProfile? _buildCachedDriverProfile(
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

  // ─── Approval actions ────────────────────────────────────────────

  Future<void> verifyDriver(
    int driverId, {
    required String status,
    String? notes,
  }) async {
    debugPrint('[AdminProvider] verifyDriver() id=$driverId, status=$status');
    await _apiService.verifyDriver(driverId, status: status, notes: notes);
    _removePendingDriver(driverId);
    debugPrint(
      '[AdminProvider] verifyDriver() SUCCESS — removed from pending list',
    );
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
      ),
      pendingRestaurants: _homeData!.pendingRestaurants,
      ordersCountByStatus: _homeData!.ordersCountByStatus,
      driversCount: _homeData!.driversCount,
    );
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
      ),
      ordersCountByStatus: _homeData!.ordersCountByStatus,
      driversCount: _homeData!.driversCount,
    );
    notifyListeners();
  }

  // ─── Support ticket API calls ───────────────────────────────────

  Future<void> fetchTickets({int? page}) async {
    debugPrint('[AdminProvider] fetchTickets() called, page=$page');
    _ticketsLoading = true;
    _ticketsError = null;
    notifyListeners();

    try {
      final json = await _apiService.getTickets(page: page);
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
      _ticketsLoading = false;
      notifyListeners();
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
    _homeData = null;
    _isLoading = false;
    _error = null;
    _tickets = [];
    _ticketsTotal = 0;
    _ticketsLoading = false;
    _ticketsError = null;
    _selectedTicket = null;
    _ticketDetailLoading = false;
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
    _apiService.dispose();
    super.dispose();
  }
}
