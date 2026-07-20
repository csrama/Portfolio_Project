import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds app-level settings (persisted locally for now).
/// Settings requested by the task:
///  - اللغة
///  - الإشعارات
///  - الوضع الليلي
///  - الخصوصية
///  - عن التطبيق
class AppSettingsProvider extends ChangeNotifier {
  static const _kLang = 'app_settings_lang';
  static const _kNotificationsEnabled = 'app_settings_notifications_enabled';
  static const _kDarkModeEnabled = 'app_settings_dark_mode';

  String _languageCode = 'ar';
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  // Privacy placeholders (to be wired to real backend/privacy policy later)
  bool _allowTracking = false;

  String get languageCode => _languageCode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get allowTracking => _allowTracking;

  ThemeMode get themeMode =>
      _darkModeEnabled ? ThemeMode.dark : ThemeMode.light;

  /// Flutter Locale/Lang support isn't wired yet.
  /// For now we keep the selection for UI display.
  /// If you want full language switching, we must also apply:
  /// - MaterialApp.locale + supportedLocales
  /// - and provide localized strings (e.g. flutter_localizations / arb)
  Locale? get locale => _languageCode == 'en' ? const Locale('en') : const Locale('ar');


  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_kLang) ?? 'ar';
    _notificationsEnabled = prefs.getBool(_kNotificationsEnabled) ?? true;
    _darkModeEnabled = prefs.getBool(_kDarkModeEnabled) ?? false;
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, code);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, enabled);
    notifyListeners();
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    _darkModeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeEnabled, enabled);
    notifyListeners();
  }

  Future<void> setAllowTracking(bool value) async {
    _allowTracking = value;
    // Persisting privacy options can be added later.
    if (kDebugMode) {
      debugPrint('Privacy allowTracking toggled to: $value');
    }
    notifyListeners();
  }
}
