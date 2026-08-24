import 'package:flutter/foundation.dart';

import '../models/public_app_config.dart';
import '../services/api_service.dart';
import '../version/app_release_history.dart';

class PublicConfigProvider extends ChangeNotifier {
  PublicConfigProvider({required ApiService apiService})
    : _apiService = apiService;

  static const adminRole = 'admin';
  final ApiService _apiService;
  PublicAppConfig? _config;
  String? _error;
  bool _isLoading = false;

  PublicAppConfig? get config => _config;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get adminUsesOtp => _config?.usesOtpFor(adminRole) ?? false;

  Future<void> load({bool notify = true}) async {
    _isLoading = true;
    _error = null;
    if (notify) notifyListeners();
    try {
      final currentVersion = AppReleaseHistory.current.label.split('+').first;
      _config = await _apiService.getPublicConfig(
        currentVersion: currentVersion,
      );
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Unable to load application configuration.';
    } finally {
      _isLoading = false;
      if (notify) notifyListeners();
    }
  }
}
