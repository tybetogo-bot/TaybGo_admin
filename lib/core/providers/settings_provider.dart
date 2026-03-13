import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyLocale = 'settings_locale';

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  /// Load saved settings from storage. Call once at app startup.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyThemeMode);
    final localeCode = prefs.getString(_keyLocale);

    if (themeIndex != null && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    if (localeCode != null && _supportedLocales.contains(localeCode)) {
      _locale = Locale(localeCode);
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _save();
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _save();
    notifyListeners();
  }

  static const _supportedLocales = ['en', 'ar', 'nl', 'fr', 'de'];

  void toggleLocale() {
    final idx = _supportedLocales.indexOf(_locale.languageCode);
    final next = (idx + 1) % _supportedLocales.length;
    _locale = Locale(_supportedLocales[next]);
    _save();
    notifyListeners();
  }

  /// Reset settings to defaults. Called on sign-out.
  void resetToDefaults() {
    _themeMode = ThemeMode.light;
    _locale = const Locale('en');
    _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, _themeMode.index);
    await prefs.setString(_keyLocale, _locale.languageCode);
  }
}
