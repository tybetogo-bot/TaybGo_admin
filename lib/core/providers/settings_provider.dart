import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  static const _supportedLocales = ['en', 'ar', 'nl', 'fr', 'de'];

  void toggleLocale() {
    final idx = _supportedLocales.indexOf(_locale.languageCode);
    final next = (idx + 1) % _supportedLocales.length;
    _locale = Locale(_supportedLocales[next]);
    notifyListeners();
  }
}
