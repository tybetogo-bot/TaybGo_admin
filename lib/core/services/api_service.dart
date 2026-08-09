import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../auth/auth_error_keys.dart';
import '../config/env_config.dart';
import '../models/admin_order.dart';
import '../models/home_response.dart';
import '../models/pricing_policy.dart';
import '../models/support_ticket.dart';

class ApiService {
  String get baseUrl => EnvConfig.baseUrl;

  final http.Client _client;
  String? _authToken;
  VoidCallback? onUnauthorized;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Never _throwUnauthorized() {
    onUnauthorized?.call();
    throw const ApiException('Unauthorized', 401);
  }

  Map<String, dynamic> _otpPayload({
    required String phone,
    required String targetRole,
    String? code,
  }) {
    final payload = <String, dynamic>{
      'phone': phone,
      'target_role': targetRole,
    };
    if (code != null) payload['code'] = code;
    return payload;
  }

  Future<Map<String, dynamic>> requestOtp(
    String phone, {
    required String targetRole,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/otp/request/');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(_otpPayload(phone: phone, targetRole: targetRole)),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw _otpException(response, fallbackMessage: 'Failed to request OTP');
    }
  }

  Future<Map<String, String>> verifyOtp(
    String phone,
    String code, {
    required String targetRole,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/otp/verify/');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(
        _otpPayload(phone: phone, targetRole: targetRole, code: code),
      ),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'refresh': json['refresh'] as String,
        'access': json['access'] as String,
      };
    } else {
      throw _otpException(response, fallbackMessage: 'Invalid OTP');
    }
  }

  ApiException _otpException(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final detail = _extractApiErrorDetail(response);
    if (_isOtpConflict(response.statusCode, detail)) {
      return ApiException(
        AuthErrorKeys.phoneAlreadyRegistered,
        response.statusCode,
      );
    }

    return ApiException(detail ?? fallbackMessage, response.statusCode);
  }

  String? _extractApiErrorDetail(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).join(', ');
      }

      if (decoded is! Map) return null;

      final body = Map<String, dynamic>.from(decoded);
      final detail = body['detail'] ?? body['message'] ?? body['error'];
      if (detail != null) return _stringifyApiError(detail);

      final fieldErrors = body.entries
          .where((entry) => entry.value != null)
          .map((entry) => '${entry.key}: ${_stringifyApiError(entry.value)}')
          .where((entry) => entry.trim().isNotEmpty)
          .join(', ');
      return fieldErrors.isEmpty ? null : fieldErrors;
    } catch (_) {
      return null;
    }
  }

  String _stringifyApiError(dynamic value) {
    if (value is List) {
      return value.map(_stringifyApiError).join(', ');
    }
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${_stringifyApiError(entry.value)}')
          .join(', ');
    }
    return value.toString();
  }

  ApiException _apiException(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final detail = _extractApiErrorDetail(response);
    final message = detail == null || detail.trim().isEmpty
        ? '$fallbackMessage (HTTP ${response.statusCode})'
        : detail;
    return ApiException(
      message,
      response.statusCode,
      fieldErrors: _extractApiFieldErrors(response),
    );
  }

  Map<String, String> _extractApiFieldErrors(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return const {};
      final body = Map<String, dynamic>.from(decoded);
      if (body.containsKey('detail') ||
          body.containsKey('message') ||
          body.containsKey('error')) {
        return const {};
      }

      return Map.fromEntries(
        body.entries
            .where((entry) => entry.value != null)
            .map(
              (entry) => MapEntry(entry.key, _stringifyApiError(entry.value)),
            ),
      );
    } catch (_) {
      return const {};
    }
  }

  bool _isOtpConflict(int statusCode, String? detail) {
    if (statusCode == 409) {
      return true;
    }

    final normalized = detail?.toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return false;
    }

    return normalized.contains('already registered') ||
        normalized.contains('already exists') ||
        normalized.contains('phone already') ||
        normalized.contains('phone number already') ||
        normalized.contains('account already') ||
        (normalized.contains('role') &&
            (normalized.contains('conflict') ||
                normalized.contains('mismatch') ||
                normalized.contains('registered')));
  }

  /// Update a driver's admin status.
  /// [status] should be "APPROVED", "REJECTED", or "SUSPENDED".
  Future<void> updateDriverStatus(
    int driverId, {
    required String status,
    String? notes,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/admin/drivers/$driverId/update-status/',
    );
    final payload = <String, dynamic>{'status': status};
    if (notes != null) payload['notes'] = notes;

    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) return;
    if (response.statusCode == 401) _throwUnauthorized();
    String detail = 'Failed to update driver status';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['detail'] != null) detail = body['detail'].toString();
    } catch (_) {}
    throw ApiException(detail, response.statusCode);
  }

  /// Activate a restaurant so it appears to customers and accepts orders.
  Future<void> activateRestaurant(int restaurantId) async {
    final uri = Uri.parse(
      '$baseUrl/api/admin/restaurants/$restaurantId/activate/',
    );
    final response = await _client.post(uri, headers: _headers);

    if (response.statusCode == 200) return;
    if (response.statusCode == 401) _throwUnauthorized();
    throw ApiException('Failed to activate restaurant', response.statusCode);
  }

  /// Fetch the driver verification queue with full profile details.
  Future<PaginatedResponse<DriverProfile>> getVerificationQueue({
    int? page,
    int? countryId,
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = '$page';
    if (countryId != null) params['country_id'] = '$countryId';

    final uri = Uri.parse(
      '$baseUrl/api/admin/drivers/verification-queue/',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return _parseVerificationQueueResponse(decoded);
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw ApiException(
        'Failed to load verification queue',
        response.statusCode,
      );
    }
  }

  PaginatedResponse<DriverProfile> _parseVerificationQueueResponse(
    dynamic decoded,
  ) {
    final page = _extractVerificationQueuePage(decoded);
    return PaginatedResponse(
      count: _asInt(page.count) ?? page.results.length,
      next: _asNullableString(page.next),
      previous: _asNullableString(page.previous),
      results: page.results,
      rawResponse: page.rawResponse,
    );
  }

  _VerificationQueuePage _extractVerificationQueuePage(
    dynamic decoded, {
    Object? rawResponse,
  }) {
    final response = rawResponse ?? decoded;

    if (decoded is List) {
      final results = _asDriverProfiles(decoded);
      return _VerificationQueuePage(
        count: results.length,
        next: null,
        previous: null,
        results: results,
        rawResponse: response,
      );
    }

    if (decoded is! Map) {
      throw const FormatException(
        'Unexpected verification queue response type',
      );
    }

    final json = Map<String, dynamic>.from(decoded);
    final nestedData = json['data'];

    if (nestedData is Map) {
      final nestedMap = Map<String, dynamic>.from(nestedData);
      if (nestedMap['results'] is List) {
        return _extractVerificationQueuePage(nestedMap, rawResponse: response);
      }
    }

    final listCandidate =
        json['results'] ??
        json['items'] ??
        json['drivers'] ??
        json['queue'] ??
        (nestedData is List ? nestedData : null);

    if (listCandidate is List) {
      final results = _asDriverProfiles(listCandidate);
      return _VerificationQueuePage(
        count: json['count'],
        next: json['next'],
        previous: json['previous'],
        results: results,
        rawResponse: response,
      );
    }

    if (_looksLikeDriverProfile(json)) {
      return _VerificationQueuePage(
        count: 1,
        next: null,
        previous: null,
        results: [DriverProfile.fromJson(json)],
        rawResponse: response,
      );
    }

    throw const FormatException('Unexpected verification queue response shape');
  }

  List<DriverProfile> _asDriverProfiles(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map((item) => DriverProfile.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  bool _looksLikeDriverProfile(Map<String, dynamic> json) {
    return json.containsKey('id') ||
        json.containsKey('driver_id') ||
        json.containsKey('name') ||
        json.containsKey('driver_name') ||
        json.containsKey('driver');
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

  Future<HomeResponse> getHome({
    int? countryId,
    bool? driverOnline,
    String? driverSearch,
    String? driverStatus,
    int? driversPage,
    int? driversPageSize,
    String? orderType,
    String? ordersFrom,
    String? ordersTo,
    int? pendingDriversPage,
    int? pendingDriversPageSize,
    int? pendingRestaurantsPage,
    int? pendingRestaurantsPageSize,
    String? restaurantSearch,
    String? restaurantStatus,
    int? restaurantsPage,
    int? restaurantsPageSize,
  }) async {
    final params = <String, String>{};

    if (countryId != null) params['country_id'] = '$countryId';
    if (driverOnline != null) params['driver_online'] = '$driverOnline';
    if (driverSearch != null) params['driver_search'] = driverSearch;
    if (driverStatus != null) params['driver_status'] = driverStatus;
    if (driversPage != null) params['drivers_page'] = '$driversPage';
    if (driversPageSize != null) {
      params['drivers_page_size'] = '$driversPageSize';
    }
    if (orderType != null) params['order_type'] = orderType;
    if (ordersFrom != null) params['orders_from'] = ordersFrom;
    if (ordersTo != null) params['orders_to'] = ordersTo;
    if (pendingDriversPage != null) {
      params['pending_drivers_page'] = '$pendingDriversPage';
    }
    if (pendingDriversPageSize != null) {
      params['pending_drivers_page_size'] = '$pendingDriversPageSize';
    }
    if (pendingRestaurantsPage != null) {
      params['pending_restaurants_page'] = '$pendingRestaurantsPage';
    }
    if (pendingRestaurantsPageSize != null) {
      params['pending_restaurants_page_size'] = '$pendingRestaurantsPageSize';
    }
    if (restaurantSearch != null) {
      params['restaurant_search'] = restaurantSearch;
    }
    if (restaurantStatus != null) {
      params['restaurant_status'] = restaurantStatus;
    }
    if (restaurantsPage != null) {
      params['restaurants_page'] = '$restaurantsPage';
    }
    if (restaurantsPageSize != null) {
      params['restaurants_page_size'] = '$restaurantsPageSize';
    }

    final uri = Uri.parse(
      '$baseUrl/api/admin/home/',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return HomeResponse.fromJson(json);
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw ApiException('Failed to load dashboard data', response.statusCode);
    }
  }

  // ─── Support Tickets ──────────────────────────────────────────

  Future<PaginatedResponse<AdminOrder>> getAdminOrders({
    int? page,
    int? countryId,
    String? search,
    String? status,
    String? orderType,
    String? from,
    String? to,
    int? customerId,
    int? driverId,
    int? restaurantId,
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = '$page';
    if (countryId != null) params['country_id'] = '$countryId';
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      params['status'] = status.trim();
    }
    if (orderType != null && orderType.trim().isNotEmpty) {
      params['order_type'] = orderType.trim();
    }
    if (from != null && from.trim().isNotEmpty) params['from_'] = from.trim();
    if (to != null && to.trim().isNotEmpty) params['to'] = to.trim();
    if (customerId != null) params['customer_id'] = '$customerId';
    if (driverId != null) params['driver_id'] = '$driverId';
    if (restaurantId != null) params['restaurant_id'] = '$restaurantId';

    final uri = Uri.parse(
      '$baseUrl/api/admin/orders/',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PaginatedResponse.fromJson(json, AdminOrder.fromJson);
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw _apiException(response, fallbackMessage: 'Failed to load orders');
    }
  }

  Future<AdminOrder> getAdminOrder(int orderId) async {
    final uri = Uri.parse('$baseUrl/api/admin/orders/$orderId/');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AdminOrder.fromJson(json);
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw _apiException(response, fallbackMessage: 'Failed to load order');
    }
  }

  Future<PaginatedResponse<OrderStatusHistory>> getOrderStatusHistory(
    int orderId, {
    int? page,
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = '$page';

    final uri = Uri.parse(
      '$baseUrl/api/admin/orders/$orderId/status-history/',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PaginatedResponse.fromJson(json, OrderStatusHistory.fromJson);
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw _apiException(
        response,
        fallbackMessage: 'Failed to load order status history',
      );
    }
  }

  // ─── Pricing policies ──────────────────────────────────────────

  Future<PaginatedResponse<PricingPolicy>> getPricingPolicies({
    int? page,
    String? search,
    String? scope,
    int? countryId,
    int? cityId,
    String? orderType,
    String? vehicleType,
    bool? isActive,
    String? currency,
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = '$page';
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (scope != null && scope.trim().isNotEmpty) {
      params['scope'] = scope.trim().toUpperCase();
    }
    if (countryId != null) params['country_id'] = '$countryId';
    if (cityId != null) params['city_id'] = '$cityId';
    if (orderType != null && orderType.trim().isNotEmpty) {
      params['order_type'] = orderType.trim().toUpperCase();
    }
    if (vehicleType != null && vehicleType.trim().isNotEmpty) {
      params['vehicle_type'] = vehicleType.trim().toUpperCase();
    }
    if (isActive != null) params['is_active'] = '$isActive';
    if (currency != null && currency.trim().isNotEmpty) {
      params['currency'] = currency.trim().toUpperCase();
    }

    final uri = Uri.parse(
      '$baseUrl/api/admin/pricing-policies/',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PaginatedResponse.fromJson(json, PricingPolicy.fromJson);
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw _apiException(
        response,
        fallbackMessage: 'Failed to load pricing policies',
      );
    }
  }

  Future<PricingPolicy> getPricingPolicy(int policyId) async {
    final uri = Uri.parse('$baseUrl/api/admin/pricing-policies/$policyId/');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return PricingPolicy.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw _apiException(
        response,
        fallbackMessage: 'Failed to load pricing policy',
      );
    }
  }

  Future<PricingPolicy> createPricingPolicy(
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$baseUrl/api/admin/pricing-policies/');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PricingPolicy.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw _apiException(
        response,
        fallbackMessage: 'Failed to create pricing policy',
      );
    }
  }

  Future<PricingPolicy> patchPricingPolicy(
    int policyId,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$baseUrl/api/admin/pricing-policies/$policyId/');
    final response = await _client.patch(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return PricingPolicy.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw _apiException(
        response,
        fallbackMessage: 'Failed to update pricing policy',
      );
    }
  }

  Future<PricingPolicy> putPricingPolicy(
    int policyId,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$baseUrl/api/admin/pricing-policies/$policyId/');
    final response = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return PricingPolicy.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw _apiException(
        response,
        fallbackMessage: 'Failed to replace pricing policy',
      );
    }
  }

  Future<void> deletePricingPolicy(int policyId) async {
    final uri = Uri.parse('$baseUrl/api/admin/pricing-policies/$policyId/');
    final response = await _client.delete(uri, headers: _headers);

    if (response.statusCode == 204 || response.statusCode == 200) return;
    if (response.statusCode == 401) _throwUnauthorized();
    throw _apiException(
      response,
      fallbackMessage: 'Failed to delete pricing policy',
    );
  }

  Future<PaginatedResponse<AdminCountry>> getAdminCountries({
    int? page,
    String? search,
    bool? isActive,
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = '$page';
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (isActive != null) params['is_active'] = '$isActive';

    final uri = Uri.parse(
      '$baseUrl/api/admin/countries/',
    ).replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PaginatedResponse.fromJson(json, AdminCountry.fromJson);
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw _apiException(
        response,
        fallbackMessage: 'Failed to load countries',
      );
    }
  }

  Future<PaginatedResponse<AdminCity>> getAdminCities({
    int? page,
    int? countryId,
    String? countryIsoCode,
    String? search,
    bool? isActive,
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = '$page';
    if (countryId != null) params['country_id'] = '$countryId';
    if (countryIsoCode != null && countryIsoCode.trim().isNotEmpty) {
      params['country_iso_code'] = countryIsoCode.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (isActive != null) params['is_active'] = '$isActive';

    final uri = Uri.parse(
      '$baseUrl/api/admin/cities/',
    ).replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PaginatedResponse.fromJson(json, AdminCity.fromJson);
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw _apiException(response, fallbackMessage: 'Failed to load cities');
    }
  }

  Future<Map<String, dynamic>> getTickets({int? page, int? countryId}) async {
    final params = <String, String>{};
    if (page != null) params['page'] = '$page';
    if (countryId != null) params['country_id'] = '$countryId';

    final uri = Uri.parse(
      '$baseUrl/api/admin/support/tickets/',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw ApiException('Failed to load tickets', response.statusCode);
    }
  }

  Future<SupportTicket> getTicket(int ticketId) async {
    final uri = Uri.parse('$baseUrl/api/admin/support/tickets/$ticketId/');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SupportTicket.fromJson(json);
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw ApiException('Failed to load ticket', response.statusCode);
    }
  }

  Future<SupportTicket> updateTicket(
    int ticketId, {
    String? status,
    String? priority,
    int? assignedToId,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (priority != null) body['priority'] = priority;
    if (assignedToId != null) body['assigned_to_id'] = assignedToId;

    final uri = Uri.parse('$baseUrl/api/admin/support/tickets/$ticketId/');
    final response = await _client.patch(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SupportTicket.fromJson(json);
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw ApiException('Failed to update ticket', response.statusCode);
    }
  }

  Future<TicketMessage> addTicketMessage(
    int ticketId, {
    required String body,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/admin/support/tickets/$ticketId/messages/',
    );
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'body': body}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return TicketMessage.fromJson(json);
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw ApiException('Failed to send message', response.statusCode);
    }
  }

  // ─── User Profile ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getMe() async {
    final uri = Uri.parse('$baseUrl/api/me/');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      _throwUnauthorized();
    } else {
      throw ApiException('Failed to load profile', response.statusCode);
    }
  }

  // ─── Restaurant ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getRestaurant(int id) async {
    final uri = Uri.parse('$baseUrl/api/customer/restaurants/$id/');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException('Failed to load restaurant', response.statusCode);
    }
  }

  void dispose() {
    _client.close();
  }
}

class _VerificationQueuePage {
  final dynamic count;
  final dynamic next;
  final dynamic previous;
  final List<DriverProfile> results;
  final Object? rawResponse;

  const _VerificationQueuePage({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
    this.rawResponse,
  });
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, String> fieldErrors;

  const ApiException(
    this.message,
    this.statusCode, {
    this.fieldErrors = const {},
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
