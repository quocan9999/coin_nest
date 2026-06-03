import 'dart:convert';

class FinancialAssistantMessage {
  const FinancialAssistantMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String role;
  final String content;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  factory FinancialAssistantMessage.fromJson(Map<String, dynamic> json) {
    return FinancialAssistantMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class FinancialAssistantResponse {
  const FinancialAssistantResponse({
    required this.answer,
    required this.suggestedQuestions,
    required this.model,
    required this.generatedAt,
  });

  final String answer;
  final List<String> suggestedQuestions;
  final String model;
  final DateTime generatedAt;

  factory FinancialAssistantResponse.fromJson(Map<String, dynamic> json) {
    return FinancialAssistantResponse(
      answer: json['answer'] as String,
      suggestedQuestions: List<String>.from(json['suggestedQuestions'] as List),
      model: json['model'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }
}

class FinancialAssistantRequest {
  const FinancialAssistantRequest({
    required this.userId,
    required this.question,
    required this.period,
    required this.reportSummary,
    required this.topExpenseCategories,
    required this.topIncomeCategories,
    this.debtSummary,
    this.budgetSummary,
    this.recentMessages = const [],
  });

  final String userId;
  final String question;
  final String period;
  final Map<String, dynamic> reportSummary;
  final List<Map<String, dynamic>> topExpenseCategories;
  final List<Map<String, dynamic>> topIncomeCategories;
  final Map<String, dynamic>? debtSummary;
  final Map<String, dynamic>? budgetSummary;
  final List<FinancialAssistantMessage> recentMessages;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'question': question,
      'period': period,
      'reportSummary': reportSummary,
      'topExpenseCategories': topExpenseCategories,
      'topIncomeCategories': topIncomeCategories,
      'debtSummary': debtSummary,
      'budgetSummary': budgetSummary,
      'recentMessages': recentMessages
          .map((message) => {'role': message.role, 'content': message.content})
          .toList(),
    };
  }
}

String encodeFinancialAssistantMessages(
  List<FinancialAssistantMessage> messages,
) {
  return jsonEncode(messages.map((message) => message.toJson()).toList());
}

List<FinancialAssistantMessage> decodeFinancialAssistantMessages(String value) {
  final decoded = jsonDecode(value) as List<dynamic>;
  return decoded
      .map(
        (item) =>
            FinancialAssistantMessage.fromJson(item as Map<String, dynamic>),
      )
      .toList();
}
