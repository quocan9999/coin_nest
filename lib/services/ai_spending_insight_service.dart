import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_spending_insight.dart';
import 'ai/ai_api_config_service.dart';

class AiSpendingInsightService {
  AiSpendingInsightService({
    http.Client? client,
    String? baseUrl,
    AiApiConfigService? configService,
  }) : _client = client ?? http.Client(),
       _baseUrlOverride = baseUrl?.trim(),
       _configService = configService ?? AiApiConfigService();

  final http.Client _client;
  final String? _baseUrlOverride;
  final AiApiConfigService _configService;

  bool get isConfigured =>
      (_baseUrlOverride ?? const String.fromEnvironment('AI_API_BASE_URL'))
          .trim()
          .isNotEmpty;

  Future<bool> isConfiguredAsync() async {
    if (isConfigured) return true;
    final config = await _configService.load();
    return config.baseUrl.trim().isNotEmpty && config.apiKey.trim().isNotEmpty;
  }

  Future<AiSpendingInsight> fetchInsight(
    AiSpendingInsightRequest request,
  ) async {
    final config = (_baseUrlOverride?.isNotEmpty ?? false)
        ? const AiApiConfig(provider: '', baseUrl: '', model: '', apiKey: '')
        : await _configService.load();
    final baseUrl = (_baseUrlOverride?.isNotEmpty ?? false)
        ? _baseUrlOverride!
        : config.baseUrl.trim();

    if (baseUrl.isEmpty) {
      throw StateError('AI_API_BASE_URL is not configured.');
    }

    final endpoint = Uri.parse(
      '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/ai/spending-insight',
    );

    final response = await _client
        .post(
          endpoint,
          headers: _headers(config),
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

  static Map<String, String> _headers(AiApiConfig config) {
    return {
      'Content-Type': 'application/json',
      if (config.provider.trim().isNotEmpty)
        'X-AI-Provider': config.provider.trim(),
      if (config.model.trim().isNotEmpty) 'X-AI-Model': config.model.trim(),
      if (config.apiKey.trim().isNotEmpty) 'X-AI-API-Key': config.apiKey.trim(),
    };
  }
}
