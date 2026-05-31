import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// Manages app-level settings (theme, currency, notifications).
class SettingsProvider extends ChangeNotifier {
  bool _showBalance = true;
  bool _dailyReminder = false;
  bool _debtReminder = false;
  String _reminderTime = AppConstants.defaultReminderTime;
  String _currency = 'VND';

  // ================= DARK MODE =================
  bool _isDarkMode = false;

  bool get showBalance => _showBalance;
  bool get dailyReminder => _dailyReminder;
  bool get debtReminder => _debtReminder;
  String get reminderTime => _reminderTime;
  String get currency => _currency;

  // ================= DARK MODE =================
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _showBalance = prefs.getBool(AppConstants.prefShowBalance) ?? true;

    _dailyReminder = prefs.getBool(AppConstants.prefDailyReminder) ?? false;

    _debtReminder = prefs.getBool(AppConstants.prefDebtReminder) ?? false;

    _reminderTime =
        prefs.getString(AppConstants.prefReminderTime) ??
        AppConstants.defaultReminderTime;

    _currency =
        prefs.getString(AppConstants.prefCurrency) ??
        AppConstants.defaultCurrency;

    // ================= DARK MODE =================
    _isDarkMode = prefs.getBool('dark_mode') ?? false;

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

  Future<void> setDebtReminder(bool value) async {
    _debtReminder = value;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(AppConstants.prefDebtReminder, value);

    notifyListeners();
  }

  Future<void> setReminderTime(String value) async {
    _reminderTime = value;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(AppConstants.prefReminderTime, value);

    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(AppConstants.prefCurrency, value);

    notifyListeners();
  }

  // ================= DARK MODE =================
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('dark_mode', value);

    notifyListeners();
  }
}
