import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Manages app-level settings (theme, currency, notifications).
class SettingsProvider extends ChangeNotifier {
  bool _showBalance = true;
  bool _dailyReminder = false;
  String _currency = 'VND';
  ThemeMode _themeMode = ThemeMode.light;

  bool get showBalance => _showBalance;
  bool get dailyReminder => _dailyReminder;
  String get currency => _currency;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showBalance = prefs.getBool(AppConstants.prefShowBalance) ?? true;
    _dailyReminder = prefs.getBool(AppConstants.prefDailyReminder) ?? false;
    _currency = prefs.getString(AppConstants.prefCurrency) ?? 'VND';
    final savedTheme = prefs.getString(AppConstants.prefThemeMode) ?? 'light';
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeMode, value ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setShowBalance(bool value) async {
    _showBalance = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefShowBalance, value);
    notifyListeners();
  }

  Future<void> setDailyReminder(bool value) async {
    _dailyReminder = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefDailyReminder, value);
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefCurrency, value);
    notifyListeners();
  }
}
