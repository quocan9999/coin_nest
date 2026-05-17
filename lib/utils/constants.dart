/// Application-wide constants.
///
/// Centralising magic values here prevents duplication and makes audits
/// straightforward.
class AppConstants {
  AppConstants._();

  // ─── App Metadata ──────────────────────────────────────────────
  static const String appName = 'CoinNest';
  static const String appTagline = 'THE FINANCIAL ARCHITECT';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String copyright = '© 2024 CoinNest Financial Ltd.';

  // ─── Database ──────────────────────────────────────────────────
  static const String dbName = 'coinnest.db';
  static const int dbVersion = 1;

  // ─── Security ──────────────────────────────────────────────────
  /// Minimum password length enforced at input validation.
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int saltLength = 32; // bytes
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  // ─── Validation Ranges ─────────────────────────────────────────
  /// Maximum transaction / balance amount (prevents integer overflow in
  /// aggregate queries on 64-bit signed integers).
  static const double maxAmount = 999999999999; // 999 tỷ
  static const int maxNameLength = 100;
  static const int maxNoteLength = 500;
  static const int maxFeedbackLength = 2000;

  // ─── Currency ──────────────────────────────────────────────────
  static const String defaultCurrency = 'VND';
  static const String currencySymbol = 'đ';
  static const String currencyLocale = 'vi_VN';

  // ─── Date Formats ──────────────────────────────────────────────
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String monthYearFormat = 'MM/yyyy';
  static const String dbDateFormat = 'yyyy-MM-dd';
  static const String dbDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // ─── Shared Preferences Keys ───────────────────────────────────
  static const String prefIsFirstLaunch = 'is_first_launch';
  static const String prefLoggedInUserId = 'logged_in_user_id';
  static const String prefThemeMode = 'theme_mode';
  static const String prefCurrency = 'currency';
  static const String prefLanguage = 'language';
  static const String prefShowBalance = 'show_balance';
  static const String prefDailyReminder = 'daily_reminder';
  static const String prefReminderTime = 'reminder_time';

  // ─── Secure Storage Keys ───────────────────────────────────────
  static const String secureSessionToken = 'session_token';

  // ─── Account Types ──────────────────────────────────────────────
  static const List<String> accountTypes = [
    'cash',
    'bank',
    'e_wallet',
    'savings',
    'credit_card',
    'other',
  ];

  static const Map<String, String> accountTypeLabels = {
    'cash': 'Tiền mặt',
    'bank': 'Ngân hàng',
    'e_wallet': 'Ví điện tử',
    'savings': 'Tiết kiệm',
    'credit_card': 'Thẻ tín dụng',
    'other': 'Khác',
  };

  // ─── Transaction Types ─────────────────────────────────────────
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';
  static const String typeTransfer = 'transfer';
  static const String typeLoan = 'loan';
  static const String typeLend = 'lend';
  static const String typeBalanceAdjust = 'balance_adjust';

  static const Map<String, String> transactionTypeLabels = {
    typeIncome: 'Thu nhập',
    typeExpense: 'Chi tiêu',
    typeTransfer: 'Chuyển khoản',
    typeLoan: 'Vay',
    typeLend: 'Cho vay',
    typeBalanceAdjust: 'Điều chỉnh số dư',
  };

  // ─── Loan Status ───────────────────────────────────────────────
  static const String loanStatusActive = 'active';
  static const String loanStatusPaid = 'paid';
  static const String loanStatusOverdue = 'overdue';

  // ─── Budget Periods ────────────────────────────────────────────
  static const Map<String, String> budgetPeriodLabels = {
    'daily': 'Hàng ngày',
    'weekly': 'Hàng tuần',
    'monthly': 'Hàng tháng',
    'yearly': 'Hàng năm',
    'custom': 'Tùy chọn',
  };

  // ─── Feedback Types ────────────────────────────────────────────
  static const Map<String, String> feedbackTypeLabels = {
    'bug': 'Lỗi phần mềm',
    'feature': 'Tính năng mới',
    'improvement': 'Cải thiện',
    'other': 'Khác',
  };
}
