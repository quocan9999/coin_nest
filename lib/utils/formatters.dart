import 'package:intl/intl.dart';
import 'constants.dart';

/// Centralised formatting helpers for currency, dates and numbers.
class Formatters {
  Formatters._();

  // ─── Currency ──────────────────────────────────────────────────

  static final _currencyFormat = NumberFormat.currency(
    locale: AppConstants.currencyLocale,
    symbol: '',
    decimalDigits: 0,
  );

  /// Format [amount] as Vietnamese currency string, e.g. `42.850.000đ`.
  static String currency(double amount) {
    return '${_currencyFormat.format(amount)}${AppConstants.currencySymbol}';
  }

  /// Format [amount] with sign prefix: `+ 12.500.000đ` / `- 8.200.000đ`.
  static String signedCurrency(double amount) {
    final sign = amount >= 0 ? '+ ' : '- ';
    return '$sign${_currencyFormat.format(amount.abs())}${AppConstants.currencySymbol}';
  }

  /// Compact form for chips: `+12.5M` / `-8.2M`.
  static String compactCurrency(double amount) {
    if (amount.abs() >= 1e9) {
      return '${(amount / 1e9).toStringAsFixed(1)}B';
    } else if (amount.abs() >= 1e6) {
      return '${(amount / 1e6).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1e3) {
      return '${(amount / 1e3).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  // ─── Dates ─────────────────────────────────────────────────────

  static final _dateFormat = DateFormat(AppConstants.dateFormat);
  static final _timeFormat = DateFormat(AppConstants.timeFormat);
  static final _dateTimeFormat = DateFormat(AppConstants.dateTimeFormat);
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'vi');
  static final _dbDateFormat = DateFormat(AppConstants.dbDateFormat);
  static final _dbDateTimeFormat = DateFormat(AppConstants.dbDateTimeFormat);

  /// User-facing date string: `30/03/2024`.
  static String date(DateTime dt) => _dateFormat.format(dt);

  /// User-facing time string: `14:30`.
  static String time(DateTime dt) => _timeFormat.format(dt);

  /// User-facing date-time string: `30/03/2024 14:30`.
  static String dateTime(DateTime dt) => _dateTimeFormat.format(dt);

  /// `Tháng 3, 2024`.
  static String monthYear(DateTime dt) => _monthYearFormat.format(dt);

  /// Database-safe ISO date: `2024-03-30`.
  static String dbDate(DateTime dt) => _dbDateFormat.format(dt);

  /// Database-safe ISO datetime: `2024-03-30 14:30:00`.
  static String dbDateTime(DateTime dt) => _dbDateTimeFormat.format(dt);

  /// Parse a database date string back to [DateTime].
  static DateTime parseDbDate(String s) => _dbDateFormat.parseStrict(s);

  /// Parse a database datetime string back to [DateTime].
  static DateTime parseDbDateTime(String s) => _dbDateTimeFormat.parseStrict(s);

  /// Relative label: "HÔM NAY", "HÔM QUA", "30/03/2024".
  static String relativeDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);

    final diff = today.difference(target).inDays;
    if (diff == 0) return 'HÔM NAY';
    if (diff == 1) return 'HÔM QUA';
    if (diff <= 7) return '$diff NGÀY TRƯỚC';

    return date(dt);
  }

  // ─── Numbers ───────────────────────────────────────────────────

  /// Format a percentage: `48%`.
  static String percent(double value) => '${value.toStringAsFixed(0)}%';

  /// Format a percentage with 1 decimal: `48.5%`.
  static String percentDecimal(double value) =>
      '${value.toStringAsFixed(1)}%';
}
