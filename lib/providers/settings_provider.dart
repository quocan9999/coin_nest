import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app-level settings (theme, currency, notifications).
class SettingsProvider extends ChangeNotifier {
  bool _showBalance = true;
  bool _dailyReminder = false;
  String _currency = 'VND';

  // ================= DARK MODE =================
  bool _isDarkMode = false;

  bool get showBalance => _showBalance;
  bool get dailyReminder => _dailyReminder;
  String get currency => _currency;

  // ================= DARK MODE =================
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode =>
      _isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _showBalance =
        prefs.getBool('show_balance') ?? true;

    _dailyReminder =
        prefs.getBool('daily_reminder') ?? false;

    _currency =
        prefs.getString('currency') ?? 'VND';

    // ================= DARK MODE =================
    _isDarkMode =
        prefs.getBool('dark_mode') ?? false;

    notifyListeners();
  }

  Future<void> setShowBalance(bool value) async {
    _showBalance = value;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'show_balance',
      value,
    );

    notifyListeners();
  }

  Future<void> setDailyReminder(bool value) async {
    _dailyReminder = value;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'daily_reminder',
      value,
    );

    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'currency',
      value,
    );

    notifyListeners();
  }

  // ================= DARK MODE =================
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'dark_mode',
      value,
    );

    notifyListeners();
  }
}