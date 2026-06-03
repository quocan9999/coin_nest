import 'dart:convert';

class AiSpendingInsight {
  const AiSpendingInsight({
    required this.title,
    required this.summary,
    required this.severity,
    required this.alerts,
    required this.savingTips,
    required this.model,
    required this.generatedAt,
  });

  final String title;
  final String summary;
  final String severity;
  final List<String> alerts;
  final List<String> savingTips;
  final String model;
  final DateTime generatedAt;

  factory AiSpendingInsight.fromJson(Map<String, dynamic> json) {
    return AiSpendingInsight(
      title: json['title'] as String,
      summary: json['summary'] as String,
      severity: json['severity'] as String,
      alerts: List<String>.from(json['alerts'] as List),
      savingTips: List<String>.from(json['savingTips'] as List),
      model: json['model'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'severity': severity,
      'alerts': alerts,
      'savingTips': savingTips,
      'model': model,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  String encode() => jsonEncode(toJson());

  static AiSpendingInsight decode(String value) {
    return AiSpendingInsight.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  }
}

class AiSpendingInsightRequest {
  const AiSpendingInsightRequest({
    required this.userId,
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.topExpenseCategories,
    this.debtSummary,
    this.budgetSummary,
  });

  final String userId;
  final String period;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<Map<String, dynamic>> topExpenseCategories;
  final Map<String, dynamic>? debtSummary;
  final Map<String, dynamic>? budgetSummary;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'period': period,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': balance,
      'topExpenseCategories': topExpenseCategories,
      'debtSummary': debtSummary,
      'budgetSummary': budgetSummary,
    };
  }
}
