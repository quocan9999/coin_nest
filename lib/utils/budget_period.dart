class BudgetCycleRange {
  const BudgetCycleRange({required this.start, this.end});

  final DateTime start;
  final DateTime? end;
}

class BudgetPeriod {
  BudgetPeriod._();

  static const none = 'none';
  static const daily = 'daily';
  static const weekly = 'weekly';
  static const monthly = 'monthly';
  static const quarterly = 'quarterly';
  static const yearly = 'yearly';
  static const custom = 'custom';

  static const allowedValues = [
    none,
    daily,
    weekly,
    monthly,
    quarterly,
    yearly,
    custom,
  ];

  static BudgetCycleRange currentRange({
    required String period,
    required DateTime startDate,
    DateTime? endDate,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final start = _dateOnly(startDate);
    final end = endDate == null ? null : _dateOnly(endDate);

    switch (period) {
      case daily:
        return BudgetCycleRange(start: today, end: today);
      case weekly:
        final weekStart = today.subtract(
          Duration(days: today.weekday - DateTime.monday),
        );
        return BudgetCycleRange(
          start: weekStart,
          end: weekStart.add(const Duration(days: 6)),
        );
      case monthly:
        return BudgetCycleRange(
          start: DateTime(today.year, today.month),
          end: DateTime(today.year, today.month + 1, 0),
        );
      case quarterly:
        final quarterStartMonth = ((today.month - 1) ~/ 3) * 3 + 1;
        return BudgetCycleRange(
          start: DateTime(today.year, quarterStartMonth),
          end: DateTime(today.year, quarterStartMonth + 3, 0),
        );
      case yearly:
        return BudgetCycleRange(
          start: DateTime(today.year),
          end: DateTime(today.year, 12, 31),
        );
      case none:
      case custom:
      default:
        return BudgetCycleRange(start: start, end: end);
    }
  }

  static String toDbDate(DateTime date) {
    return _dateOnly(date).toIso8601String().split('T').first;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
