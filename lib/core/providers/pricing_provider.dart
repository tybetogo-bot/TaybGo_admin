import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/pricing_policy.dart';
import '../services/api_service.dart';
import 'country_filter_provider.dart';

class PricingProvider extends ChangeNotifier {
  final ApiService _apiService;
  final CountryFilterProvider? _countryFilter;
  int _requestVersion = 0;

  PricingProvider({
    ApiService? apiService,
    CountryFilterProvider? countryFilter,
  }) : _apiService = apiService ?? ApiService(),
       _countryFilter = countryFilter {
    _countryId = countryFilter?.selectedCountryId;
    countryFilter?.registerConsumer('pricing');
    countryFilter?.addListener(_handleCountryChanged);
  }

  List<PricingPolicy> _policies = [];
  int _total = 0;
  String? _next;
  String? _previous;
  int _page = 1;
  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  List<AdminCountry> _countries = [];
  List<AdminCity> _cities = [];
  bool _locationsLoading = false;
  String? _locationsError;

  String _search = '';
  String? _scope;
  int? _countryId;
  int? _cityId;
  String? _orderType;
  String? _vehicleType;
  bool? _isActive;
  String _currency = '';

  List<PricingPolicy> get policies => _policies;
  int get total => _total;
  String? get next => _next;
  String? get previous => _previous;
  int get page => _page;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);

  List<AdminCountry> get countries => _countries;
  List<AdminCity> get cities => _cities;
  bool get locationsLoading => _locationsLoading;
  String? get locationsError => _locationsError;

  String get search => _search;
  String? get scope => _scope;
  int? get countryId => _countryId;
  int? get cityId => _cityId;
  String? get orderType => _orderType;
  String? get vehicleType => _vehicleType;
  bool? get isActive => _isActive;
  String get currency => _currency;

  void _handleCountryChanged() {
    final countryFilter = _countryFilter;
    if (countryFilter == null) return;
    final nextCountryId = _countryFilter?.selectedCountryId;
    if (_countryId == nextCountryId) return;
    _countryId = nextCountryId;
    _cityId = null;
    debugPrint(
      '[PricingProvider] Country changed — refreshing policies '
      '(countryId=$nextCountryId)',
    );
    final revision = countryFilter.revision;
    unawaited(
      Future.wait<void>([
        _fetch(page: 1),
        loadCities(countryId: nextCountryId),
      ]).whenComplete(() => countryFilter.completeRefresh('pricing', revision)),
    );
  }

  Future<void> initialize() async {
    _countryId = _countryFilter?.selectedCountryId ?? _countryId;
    await Future.wait([
      loadCountries(),
      loadCities(countryId: _countryId),
      fetchPolicies(),
    ]);
  }

  Future<void> fetchPolicies() async {
    await _fetch(page: 1);
  }

  Future<void> fetchPage(int page) async {
    if (page < 1) return;
    await _fetch(page: page);
  }

  Future<void> applyFilters({
    required String search,
    required String? scope,
    required int? countryId,
    required int? cityId,
    required String? orderType,
    required String? vehicleType,
    required bool? isActive,
    required String currency,
  }) async {
    _search = search.trim();
    _scope = scope;
    _countryId = _countryFilter?.selectedCountryId ?? countryId;
    _cityId = cityId;
    _orderType = orderType;
    _vehicleType = vehicleType;
    _isActive = isActive;
    _currency = currency.trim().toUpperCase();
    await _fetch(page: 1);
  }

  Future<void> clearFilters() async {
    _search = '';
    _scope = null;
    _countryId = _countryFilter?.selectedCountryId;
    _cityId = null;
    _orderType = null;
    _vehicleType = null;
    _isActive = null;
    _currency = '';
    await _fetch(page: 1);
  }

  Future<void> _fetch({required int page}) async {
    final requestVersion = ++_requestVersion;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getPricingPolicies(
        page: page,
        search: _search,
        scope: _scope,
        countryId: _countryId,
        cityId: _cityId,
        orderType: _orderType,
        vehicleType: _vehicleType,
        isActive: _isActive,
        currency: _currency,
      );
      if (requestVersion != _requestVersion) return;
      _policies = response.results;
      _total = response.count;
      _next = response.next;
      _previous = response.previous;
      _page = page;
    } on ApiException catch (e) {
      _error = e.message;
      _fieldErrors = e.fieldErrors;
    } catch (_) {
      _error = 'pricing_connection_error';
    } finally {
      if (requestVersion == _requestVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadCountries() async {
    _locationsLoading = true;
    _locationsError = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminCountries(isActive: true);
      _countries = response.results;
    } on ApiException catch (e) {
      _locationsError = e.message;
    } catch (_) {
      _locationsError = 'pricing_failed_to_load_countries';
    } finally {
      _locationsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCities({int? countryId}) async {
    _locationsLoading = true;
    _locationsError = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminCities(
        countryId: countryId,
        isActive: true,
      );
      _cities = response.results;
    } on ApiException catch (e) {
      _locationsError = e.message;
    } catch (_) {
      _locationsError = 'pricing_failed_to_load_cities';
    } finally {
      _locationsLoading = false;
      notifyListeners();
    }
  }

  Future<PricingPolicy> createPolicy(Map<String, dynamic> payload) async {
    return _runMutation(() async {
      final created = await _apiService.createPricingPolicy(payload);
      await _fetch(page: _page);
      return created;
    });
  }

  Future<PricingPolicy> fetchPolicy(int policyId) {
    return _apiService.getPricingPolicy(policyId);
  }

  Future<List<PricingPolicy>> findPoliciesForTarget({
    required String scope,
    int? countryId,
    int? cityId,
    required String orderType,
    required String vehicleType,
  }) async {
    final matches = <PricingPolicy>[];
    var page = 1;

    while (true) {
      final response = await _apiService.getPricingPolicies(
        page: page,
        scope: scope,
        countryId: countryId,
        cityId: cityId,
        orderType: orderType,
        vehicleType: vehicleType,
      );
      matches.addAll(response.results);
      if (response.next == null || response.results.isEmpty) break;
      page++;
    }

    return matches;
  }

  Future<PricingPolicy> updatePolicy(
    int policyId,
    Map<String, dynamic> payload,
  ) async {
    return _runMutation(() async {
      final updated = await _apiService.patchPricingPolicy(policyId, payload);
      await _fetch(page: _page);
      return updated;
    });
  }

  Future<PricingPolicy> replacePolicy(
    int policyId,
    Map<String, dynamic> payload,
  ) async {
    return _runMutation(() async {
      final replaced = await _apiService.putPricingPolicy(policyId, payload);
      await _fetch(page: _page);
      return replaced;
    });
  }

  Future<void> deletePolicy(int policyId) async {
    _isMutating = true;
    _error = null;
    _fieldErrors = {};
    notifyListeners();

    try {
      await _apiService.deletePricingPolicy(policyId);
      if (_policies.length == 1 && _page > 1) {
        await _fetch(page: _page - 1);
      } else {
        await _fetch(page: _page);
      }
    } on ApiException catch (e) {
      _error = e.message;
      _fieldErrors = e.fieldErrors;
      rethrow;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<T> _runMutation<T>(Future<T> Function() action) async {
    _isMutating = true;
    _error = null;
    _fieldErrors = {};
    notifyListeners();

    try {
      return await action();
    } on ApiException catch (e) {
      _error = e.message;
      _fieldErrors = e.fieldErrors;
      rethrow;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  void clearAll() {
    _requestVersion++;
    _policies = [];
    _total = 0;
    _next = null;
    _previous = null;
    _page = 1;
    _isLoading = false;
    _isMutating = false;
    _error = null;
    _fieldErrors = {};
    _countries = [];
    _cities = [];
    _locationsLoading = false;
    _locationsError = null;
    _search = '';
    _scope = null;
    _countryId = null;
    _cityId = null;
    _orderType = null;
    _vehicleType = null;
    _isActive = null;
    _currency = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _countryFilter?.removeListener(_handleCountryChanged);
    _countryFilter?.unregisterConsumer('pricing');
    super.dispose();
  }
}
