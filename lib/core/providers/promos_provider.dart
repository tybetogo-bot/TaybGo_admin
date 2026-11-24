import 'package:flutter/foundation.dart';
import '../models/promo_banner.dart';
import '../services/api_service.dart';
import 'country_filter_provider.dart';

enum PromoQueue { pending, live, inactive, rejected, all }

class PromosProvider extends ChangeNotifier {
  final ApiService api;
  final CountryFilterProvider country;
  PromosProvider({required this.api, required this.country}) {
    _countryId = country.selectedCountryId;
    country.registerConsumer('promos');
    country.addListener(_countryChanged);
  }
  List<PromoBanner> items = [];
  String? status = 'PENDING';
  String city = '';
  int? restaurantId;
  String? restaurantName;
  bool? isActive;
  int page = 1, total = 0;
  bool loading = false, mutating = false, hasNext = false;
  String? error;
  Map<PromoQueue, int> counts = {};
  bool countsLoading = false;
  bool countsFailed = false;
  int? _countryId;
  int _version = 0, _countsVersion = 0;
  bool _disposed = false;
  bool _applyingCountry = false;
  String? _loadedScope;

  PromoQueue get queue {
    if (status == 'PENDING') return PromoQueue.pending;
    if (status == 'REJECTED') return PromoQueue.rejected;
    if (status == 'APPROVED' && isActive == true) return PromoQueue.live;
    if (status == 'APPROVED' && isActive == false) return PromoQueue.inactive;
    return PromoQueue.all;
  }

  Future<void> selectQueue(PromoQueue value) {
    status = switch (value) {
      PromoQueue.pending => 'PENDING',
      PromoQueue.rejected => 'REJECTED',
      PromoQueue.live || PromoQueue.inactive => 'APPROVED',
      PromoQueue.all => null,
    };
    isActive = switch (value) {
      PromoQueue.live => true,
      PromoQueue.inactive => false,
      _ => null,
    };
    return load();
  }

  Future<void> applyScope({
    required String city,
    int? restaurantId,
    String? restaurantName,
    int? countryId,
    bool changeCountry = false,
  }) async {
    if (changeCountry) {
      _applyingCountry = true;
      try {
        country.selectCountry(countryId);
      } finally {
        _applyingCountry = false;
      }
    }
    this.city = city.trim();
    this.restaurantId = restaurantId;
    this.restaurantName = restaurantName;
    final revision = country.revision;
    await refresh().whenComplete(
      () => country.completeRefresh('promos', revision),
    );
  }

  Future<void> refresh() => Future.wait([load(), loadCounts()]);

  void _countryChanged() {
    if (_countryId == country.selectedCountryId) return;
    _countryId = country.selectedCountryId;
    if (_applyingCountry) return;
    city = '';
    restaurantId = null;
    restaurantName = null;
    final revision = country.revision;
    refresh().whenComplete(() => country.completeRefresh('promos', revision));
  }

  Future<void> loadCounts() async {
    final version = ++_countsVersion;
    counts = {};
    countsLoading = true;
    countsFailed = false;
    notifyListeners();
    try {
      final results = await Future.wait(
        PromoQueue.values.where((v) => v != PromoQueue.all).map((q) async {
          final response = await api.getPromos(
            countryId: _countryId,
            city: city,
            restaurantId: restaurantId,
            status: switch (q) {
              PromoQueue.pending => 'PENDING',
              PromoQueue.rejected => 'REJECTED',
              _ => 'APPROVED',
            },
            isActive: switch (q) {
              PromoQueue.live => true,
              PromoQueue.inactive => false,
              _ => null,
            },
          );
          return MapEntry(q, response.count);
        }),
      );
      if (_disposed || version != _countsVersion) return;
      counts = Map.fromEntries(results);
      counts[PromoQueue.all] = counts.values.fold(0, (a, b) => a + b);
    } catch (_) {
      if (!_disposed && version == _countsVersion) countsFailed = true;
    } finally {
      if (!_disposed && version == _countsVersion) {
        countsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> load({int pageNumber = 1}) async {
    final version = ++_version;
    final scope =
        '$_countryId|$status|$isActive|$city|$restaurantId|$pageNumber';
    if (_loadedScope != scope) items = [];
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await api.getPromos(
        page: pageNumber,
        status: status,
        city: city,
        restaurantId: restaurantId,
        isActive: isActive,
        countryId: _countryId,
      );
      if (_disposed || version != _version) return;
      items = result.results;
      total = result.count;
      page = pageNumber;
      hasNext = result.next != null;
      _loadedScope = scope;
    } catch (e) {
      if (_disposed || version != _version) return;
      error = e is ApiException ? e.message : 'promosLoadError';
    } finally {
      if (!_disposed && version == _version) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<PromoBanner> moderate(
    int id, {
    required String action,
    int? priority,
    String? reason,
  }) async {
    if (mutating) throw StateError('A promo update is already in progress.');
    mutating = true;
    notifyListeners();
    try {
      final result = await api.moderatePromo(
        id,
        action: action,
        priority: priority,
        reason: reason,
      );
      if (_disposed) return result;
      await Future.wait([load(pageNumber: page), loadCounts()]);
      if (!_disposed && error == null && items.isEmpty && page > 1) {
        await load(pageNumber: page - 1);
      }
      return result;
    } finally {
      if (!_disposed) {
        mutating = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    _countsVersion++;
    country.removeListener(_countryChanged);
    country.unregisterConsumer('promos');
    super.dispose();
  }
}
