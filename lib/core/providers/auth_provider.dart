import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyAccess = 'auth_access_token';
  static const _keyRefresh = 'auth_refresh_token';

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _phone;
  String? _testOtp;
  String? _accessToken;
  String? _refreshToken;

  // User profile data from /api/me/
  Map<String, dynamic>? _userProfile;
  bool _profileLoading = false;
  String? _profileError;

  final ApiService _apiService;

  AuthProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get phone => _phone;
  String? get testOtp => _testOtp;
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
      _accessToken = access;
      _refreshToken = refresh;
      _apiService.setAuthToken(access);
      _isAuthenticated = true;
      notifyListeners();
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.requestOtp(phone);
      _phone = phone;
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
    if (_phone == null) {
      _error = 'Phone number not set';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tokens = await _apiService.verifyOtp(_phone!, code);
      _accessToken = tokens['access'];
      _refreshToken = tokens['refresh'];
      _apiService.setAuthToken(_accessToken!);
      await _saveTokens();
      _isAuthenticated = true;
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

  void signOut() {
    _isAuthenticated = false;
    _accessToken = null;
    _refreshToken = null;
    _phone = null;
    _testOtp = null;
    _userProfile = null;
    _profileError = null;
    _apiService.clearAuthToken();
    _clearTokens();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
