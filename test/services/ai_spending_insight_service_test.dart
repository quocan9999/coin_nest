import 'dart:convert';

import 'package:coin_nest/models/ai_spending_insight.dart';
import 'package:coin_nest/services/ai_spending_insight_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetchInsight gọi đúng endpoint và parse JSON response', () async {
    late Uri capturedUri;
    late Map<String, dynamic> capturedBody;

    final service = AiSpendingInsightService(
      baseUrl: 'http://localhost:5007',
      client: MockClient((request) async {
        capturedUri = request.url;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'title': 'Chi tiêu ổn định',
              'summary': 'Tháng này chi tiêu trong mức an toàn.',
              'severity': 'low',
              'alerts': ['Không có cảnh báo lớn'],
              'savingTips': ['Giữ mức tiết kiệm hiện tại'],
              'model': 'test-model',
              'generatedAt': '2026-06-03T10:00:00Z',
            }),
          ),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      }),
    );

    final insight = await service.fetchInsight(
      const AiSpendingInsightRequest(
        userId: '1',
        period: '2026-06',
        totalIncome: 10000000,
        totalExpense: 4000000,
        balance: 6000000,
        topExpenseCategories: [
          {'name': 'Ăn uống', 'amount': 2000000, 'percent': 50},
        ],
      ),
    );

    expect(capturedUri.path, '/api/ai/spending-insight');
    expect(capturedBody['period'], '2026-06');
    expect(insight.title, 'Chi tiêu ổn định');
    expect(insight.savingTips.single, 'Giữ mức tiết kiệm hiện tại');
  });
}
