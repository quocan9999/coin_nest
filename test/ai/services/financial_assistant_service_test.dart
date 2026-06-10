import 'dart:convert';

import 'package:coin_nest/models/financial_assistant.dart';
import 'package:coin_nest/services/financial_assistant_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('ask gọi đúng endpoint và parse JSON response', () async {
    late Uri capturedUri;
    late Map<String, dynamic> capturedBody;

    final service = FinancialAssistantService(
      baseUrl: 'http://localhost:5007',
      client: MockClient((request) async {
        capturedUri = request.url;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'answer': 'Bạn đang chi nhiều nhất cho ăn uống.',
              'suggestedQuestions': ['Tôi nên giảm khoản nào?'],
              'model': 'test-model',
              'generatedAt': '2026-06-04T10:00:00Z',
            }),
          ),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      }),
    );

    final response = await service.ask(
      const FinancialAssistantRequest(
        userId: '1',
        question: 'Tháng này tôi chi nhiều nhất vào đâu?',
        period: '2026-06',
        reportSummary: {
          'totalIncome': 10000000,
          'totalExpense': 4000000,
          'netBalance': 6000000,
          'accountBalance': 12000000,
        },
        topExpenseCategories: [
          {'name': 'Ăn uống', 'amount': 2000000, 'percent': 50},
        ],
        topIncomeCategories: [],
      ),
    );

    expect(capturedUri.path, '/api/ai/financial-assistant');
    expect(capturedBody['question'], 'Tháng này tôi chi nhiều nhất vào đâu?');
    expect(response.answer, 'Bạn đang chi nhiều nhất cho ăn uống.');
    expect(response.suggestedQuestions.single, 'Tôi nên giảm khoản nào?');
  });
}
