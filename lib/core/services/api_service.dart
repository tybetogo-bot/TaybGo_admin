import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../models/home_response.dart';
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

  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final uri = Uri.parse('$baseUrl/api/auth/otp/request/');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        body['detail'] ?? 'Failed to request OTP',
        response.statusCode,
      );
    }
  }

  Future<Map<String, String>> verifyOtp(String phone, String code) async {
    final uri = Uri.parse('$baseUrl/api/auth/otp/verify/');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'phone': phone, 'code': code}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'refresh': json['refresh'] as String,
        'access': json['access'] as String,
      };
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(body['detail'] ?? 'Invalid OTP', response.statusCode);
    }
  }

  /// Approve or reject a driver.
  /// [status] should be "APPROVED" or "REJECTED".
  Future<void> verifyDriver(
    int driverId, {
    required String status,
    String? notes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/drivers/$driverId/verify/');
    final payload = <String, dynamic>{'status': status};
    if (notes != null) payload['notes'] = notes;

    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) return;
    if (response.statusCode == 401) _throwUnauthorized();
    String detail = 'Failed to verify driver';
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
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = '$page';

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
    );
  }

  _VerificationQueuePage _extractVerificationQueuePage(dynamic decoded) {
    if (decoded is List) {
      final results = _asDriverProfiles(decoded);
      return _VerificationQueuePage(
        count: results.length,
        next: null,
        previous: null,
        results: results,
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
        return _extractVerificationQueuePage(nestedMap);
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
      );
    }

    if (_looksLikeDriverProfile(json)) {
      return _VerificationQueuePage(
        count: 1,
        next: null,
        previous: null,
        results: [DriverProfile.fromJson(json)],
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

  Future<Map<String, dynamic>> getTickets({int? page}) async {
    final params = <String, String>{};
    if (page != null) params['page'] = '$page';

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

  const _VerificationQueuePage({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
