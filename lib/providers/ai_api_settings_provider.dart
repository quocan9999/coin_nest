import 'package:flutter/foundation.dart';

import '../services/ai/ai_api_config_service.dart';

class AiApiSettingsProvider extends ChangeNotifier {
  AiApiSettingsProvider({AiApiConfigService? service})
    : _service = service ?? AiApiConfigService();

  final AiApiConfigService _service;

  AiApiConfig _config = const AiApiConfig(
    provider: AiApiConfigService.defaultProviderId,
    baseUrl: AiApiConfigService.defaultBaseUrl,
    model: '',
    apiKey: '',
  );
  bool _isLoading = false;
  bool _isSaving = false;

  AiApiConfig get config => _config;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasApiKey => _config.hasApiKey;
  bool get isConfigured => _config.isConfigured && _config.hasApiKey;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _config = await _service.load();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> save({
    required String provider,
    required String baseUrl,
    required String model,
    String? apiKey,
  }) async {
    _isSaving = true;
    notifyListeners();

    await _service.save(
      provider: provider,
      baseUrl: baseUrl,
      model: model,
      apiKey: apiKey,
    );
    _config = await _service.load();

    _isSaving = false;
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    _isSaving = true;
    notifyListeners();

    await _service.clearApiKey();
    _config = await _service.load();

    _isSaving = false;
    notifyListeners();
  }
}
