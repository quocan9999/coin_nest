import 'package:flutter/material.dart';

/// Maps icon string keys (stored in DB) to Material Icons and colors.
///
/// Using string keys decouples the database from Flutter's [IconData] and
/// makes future migrations or platform ports safer.
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> icons = {
    // Expense categories
    'food': Icons.restaurant_rounded,
    'transport': Icons.directions_car_rounded,
    'housing': Icons.home_rounded,
    'utilities': Icons.bolt_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'health': Icons.medical_services_rounded,
    'education': Icons.school_rounded,
    'entertainment': Icons.movie_rounded,
    'clothing': Icons.checkroom_rounded,
    'personal': Icons.face_rounded,
    'gift': Icons.card_giftcard_rounded,
    'telecom': Icons.phone_android_rounded,
    'travel': Icons.flight_rounded,
    'repair': Icons.build_rounded,
    'other_expense': Icons.more_horiz_rounded,

    // Income categories
    'salary': Icons.account_balance_wallet_rounded,
    'investment': Icons.trending_up_rounded,
    'bonus': Icons.emoji_events_rounded,
    'side_income': Icons.attach_money_rounded,
    'interest': Icons.account_balance_rounded,
    'received_gift': Icons.redeem_rounded,
    'other_income': Icons.more_horiz_rounded,

    // Special
    'transfer': Icons.swap_horiz_rounded,
    'loan': Icons.handshake_rounded,
    'lend': Icons.volunteer_activism_rounded,
    'balance_adjust': Icons.tune_rounded,

    // Account types
    'cash': Icons.payments_rounded,
    'bank': Icons.account_balance_rounded,
    'e_wallet': Icons.wallet_rounded,
    'savings': Icons.savings_rounded,
    'credit_card': Icons.credit_card_rounded,
    'other': Icons.category_rounded,
  };

  static const Map<String, Color> colors = {
    'food': Color(0xFFE57373),
    'transport': Color(0xFF64B5F6),
    'housing': Color(0xFFFFB74D),
    'utilities': Color(0xFFFFD54F),
    'shopping': Color(0xFFBA68C8),
    'health': Color(0xFFEF5350),
    'education': Color(0xFF42A5F5),
    'entertainment': Color(0xFFFF7043),
    'clothing': Color(0xFF7E57C2),
    'personal': Color(0xFFEC407A),
    'gift': Color(0xFFAB47BC),
    'telecom': Color(0xFF26A69A),
    'travel': Color(0xFF29B6F6),
    'repair': Color(0xFF8D6E63),
    'other_expense': Color(0xFF78909C),

    'salary': Color(0xFF66BB6A),
    'investment': Color(0xFF26C6DA),
    'bonus': Color(0xFFFFA726),
    'side_income': Color(0xFF9CCC65),
    'interest': Color(0xFF5C6BC0),
    'received_gift': Color(0xFFEF5350),
    'other_income': Color(0xFF78909C),

    'transfer': Color(0xFF42A5F5),
    'loan': Color(0xFFFF7043),
    'lend': Color(0xFFAB47BC),
    'balance_adjust': Color(0xFF78909C),

    'cash': Color(0xFF66BB6A),
    'bank': Color(0xFF42A5F5),
    'e_wallet': Color(0xFFAB47BC),
    'savings': Color(0xFFFFA726),
    'credit_card': Color(0xFFEF5350),
    'other': Color(0xFF78909C),
  };

  /// Return the [IconData] for a given key, with a fallback.
  static IconData getIcon(String key) =>
      icons[key] ?? Icons.category_rounded;

  /// Return the [Color] for a given key, with a fallback.
  static Color getColor(String key) =>
      colors[key] ?? const Color(0xFF78909C);

  /// All icon keys available for category selection UI.
  static List<String> get expenseIconKeys => const [
        'food', 'transport', 'housing', 'utilities', 'shopping',
        'health', 'education', 'entertainment', 'clothing', 'personal',
        'gift', 'telecom', 'travel', 'repair', 'other_expense',
      ];

  static List<String> get incomeIconKeys => const [
        'salary', 'investment', 'bonus', 'side_income',
        'interest', 'received_gift', 'other_income',
      ];

  static List<String> get accountIconKeys => const [
        'cash', 'bank', 'e_wallet', 'savings', 'credit_card', 'other',
      ];
}
