import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyAccess = 'auth_access_token';
  static const _keyRefresh = 'auth_refresh_token';
  static const _adminTargetRole = 'admin';
  static const _sessionCheckInterval = Duration(minutes: 1);
  static const _remoteValidationInterval = Duration(minutes: 5);
  static const _tokenExpirySkew = Duration(seconds: 30);

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _phone;
  String? _testOtp;
  String? _pendingOtpTargetRole;
  String? _accessToken;
  String? _refreshToken;

  // User profile data from /api/me/
  Map<String, dynamic>? _userProfile;
  bool _profileLoading = false;
  String? _profileError;
  Timer? _sessionCheckTimer;
  DateTime? _lastRemoteValidationAt;
  bool _sessionValidationInFlight = false;

  final ApiService _apiService;
  VoidCallback? onSignedOut;

  AuthProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get phone => _phone;
  String? get testOtp => _testOtp;
  String? get pendingOtpTargetRole => _pendingOtpTargetRole;
  String? get accessToken => _accessToken;

  Map<String, dynamic>? get userProfile => _userProfile;
  bool get profileLoading => _profileLoading;
  String? get profileError => _profileError;

  /// Load saved tokens from storage. Call once at app startup.
  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_keyAccess);
    final refresh = prefs.getString(_keyRefresh);

    if (access != null && refresh != null) {
      if (!_isAccessTokenValid(access)) {
        signOut();
        return;
      }

      _accessToken = access;
      _refreshToken = refresh;
      _apiService.setAuthToken(access);
      _isAuthenticated = true;
      _startSessionMonitoring();
      await validateSession(forceRemote: true);

      if (_isAuthenticated) {
        notifyListeners();
      }
    }
  }

  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) prefs.setString(_keyAccess, _accessToken!);
    if (_refreshToken != null) prefs.setString(_keyRefresh, _refreshToken!);
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Request OTP for the given phone number (no country code).
  Future<bool> requestOtp(String phone) async {
    return _requestOtpWithRole(phone: phone, targetRole: _adminTargetRole);
  }

  Future<bool> resendOtp() async {
    final phone = _phone;
    final targetRole = _pendingOtpTargetRole;

    if (phone == null || targetRole == null) {
      _error = 'Phone number not set';
      notifyListeners();
      return false;
    }

    return _requestOtpWithRole(phone: phone, targetRole: targetRole);
  }

  Future<bool> _requestOtpWithRole({
    required String phone,
    required String targetRole,
  }) async {
    _isLoading = true;
    _error = null;
    _phone = phone;
    _pendingOtpTargetRole = targetRole;
    notifyListeners();

    try {
      final response = await _apiService.requestOtp(
        phone,
        targetRole: targetRole,
      );
      _testOtp = response['otp'] as String?;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify the OTP code and obtain JWT tokens.
  Future<bool> verifyOtp(String code) async {
    final phone = _phone;
    final targetRole = _pendingOtpTargetRole;

    if (phone == null || targetRole == null) {
      _error = 'Phone number not set';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tokens = await _apiService.verifyOtp(
        phone,
        code,
        targetRole: targetRole,
      );
      _accessToken = tokens['access'];
      _refreshToken = tokens['refresh'];
      _apiService.setAuthToken(_accessToken!);
      await _saveTokens();
      _isAuthenticated = true;
      _lastRemoteValidationAt = DateTime.now();
      _startSessionMonitoring();
      _pendingOtpTargetRole = null;
      _testOtp = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchProfile() async {
    _profileLoading = true;
    _profileError = null;
    notifyListeners();

    try {
      _userProfile = await _apiService.getMe();
      _profileLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _profileError = e.message;
      _profileLoading = false;
      notifyListeners();
    } catch (_) {
      _profileError = 'Connection error';
      _profileLoading = false;
      notifyListeners();
    }
  }

  Future<bool> validateSession({bool forceRemote = false}) async {
    if (!_isAuthenticated || _accessToken == null) return false;

    if (!_isAccessTokenValid(_accessToken!)) {
      signOut();
      return false;
    }

    final shouldRunRemoteValidation =
        forceRemote || _shouldRunRemoteValidation();
    if (!shouldRunRemoteValidation) return true;

    if (_sessionValidationInFlight) return true;
    _sessionValidationInFlight = true;

    try {
      await _apiService.getMe();
      _lastRemoteValidationAt = DateTime.now();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401 && _isAuthenticated) {
        signOut();
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _sessionValidationInFlight = false;
    }
  }

  bool _shouldRunRemoteValidation() {
    if (_lastRemoteValidationAt == null) return true;
    return DateTime.now().difference(_lastRemoteValidationAt!) >=
        _remoteValidationInterval;
  }

  void _startSessionMonitoring() {
    _stopSessionMonitoring();
    _sessionCheckTimer = Timer.periodic(_sessionCheckInterval, (_) {
      validateSession();
    });
  }

  void _stopSessionMonitoring() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = null;
    _sessionValidationInFlight = false;
    _lastRemoteValidationAt = null;
  }

  bool _isAccessTokenValid(String token) {
    final payload = _parseJwtPayload(token);
    if (payload == null) return false;

    final exp = _parseEpochSeconds(payload['exp']);
    if (exp == null) return false;

    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    return expiry.isAfter(DateTime.now().toUtc().add(_tokenExpirySkew));
  }

  Map<String, dynamic>? _parseJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalizedPayload = base64Url.normalize(parts[1]);
      final decodedPayload = base64Url.decode(normalizedPayload);
      final payload = jsonDecode(utf8.decode(decodedPayload));

      if (payload is Map<String, dynamic>) return payload;
      if (payload is Map) return Map<String, dynamic>.from(payload);
      return null;
    } catch (_) {
      return null;
    }
  }

  int? _parseEpochSeconds(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  void signOut() {
    final hadSession =
        _isAuthenticated ||
        _accessToken != null ||
        _refreshToken != null ||
        _userProfile != null;

    _isAuthenticated = false;
    _accessToken = null;
    _refreshToken = null;
    _phone = null;
    _testOtp = null;
    _pendingOtpTargetRole = null;
    _userProfile = null;
    _profileError = null;
    _stopSessionMonitoring();
    _apiService.clearAuthToken();
    _clearTokens();
    if (hadSession) {
      onSignedOut?.call();
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopSessionMonitoring();
    super.dispose();
  }
}
