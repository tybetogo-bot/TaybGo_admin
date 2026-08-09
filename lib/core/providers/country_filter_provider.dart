import 'package:flutter/foundation.dart';

import '../models/pricing_policy.dart';
import '../services/api_service.dart';

/// Shared country scope for all admin list and export requests.
class CountryFilterProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<AdminCountry> _countries = [];
  int? _selectedCountryId;
  bool _isLoading = false;
  String? _error;
  int _revision = 0;
  bool _isRefreshing = false;
  final Set<String> _consumers = {};
  final Set<String> _pendingConsumers = {};

  CountryFilterProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  List<AdminCountry> get countries => List.unmodifiable(_countries);
  int? get selectedCountryId => _selectedCountryId;
  AdminCountry? get selectedCountry {
    final id = _selectedCountryId;
    if (id == null) return null;
    for (final country in _countries) {
      if (country.id == id) return country;
    }
    return null;
  }

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  int get revision => _revision;

  void registerConsumer(String key) {
    _consumers.add(key);
    if (_isRefreshing) _pendingConsumers.add(key);
  }

  void unregisterConsumer(String key) {
    _consumers.remove(key);
    _pendingConsumers.remove(key);
    if (_isRefreshing && _pendingConsumers.isEmpty) {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void completeRefresh(String key, int revision) {
    if (revision != _revision || !_isRefreshing) return;
    _pendingConsumers.remove(key);
    if (_pendingConsumers.isEmpty) {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadCountries() async {
    if (_isLoading || _countries.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final countries = <AdminCountry>[];
      int? page;
      while (true) {
        final response = await _apiService.getAdminCountries(
          page: page,
          isActive: true,
        );
        countries.addAll(response.results);
        if (response.next == null || response.results.isEmpty) break;
        page = (page ?? 1) + 1;
      }
      _countries = countries;
      _error = null;
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Failed to load countries.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCountry(int? countryId) {
    if (countryId != null &&
        _countries.isNotEmpty &&
        !_countries.any((country) => country.id == countryId)) {
      return;
    }
    if (_selectedCountryId == countryId) return;

    _selectedCountryId = countryId;
    _revision++;
    _pendingConsumers
      ..clear()
      ..addAll(_consumers);
    _isRefreshing = _pendingConsumers.isNotEmpty;
    notifyListeners();
  }

  void clearAll() {
    _countries = [];
    _selectedCountryId = null;
    _isLoading = false;
    _error = null;
    _revision++;
    _isRefreshing = false;
    _pendingConsumers.clear();
    notifyListeners();
  }
}
