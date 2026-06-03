import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_spending_insight.dart';

class AiSpendingInsightService {
  AiSpendingInsightService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? const String.fromEnvironment('AI_API_BASE_URL'))
          .trim();

  final http.Client _client;
  final String _baseUrl;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<AiSpendingInsight> fetchInsight(
    AiSpendingInsightRequest request,
  ) async {
    if (!isConfigured) {
      throw StateError('AI_API_BASE_URL is not configured.');
    }

    final endpoint = Uri.parse(
      '${_baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/ai/spending-insight',
    );

    final response = await _client
        .post(
          endpoint,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('AI API returned ${response.statusCode}.');
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return AiSpendingInsight.fromJson(json);
  }
}
