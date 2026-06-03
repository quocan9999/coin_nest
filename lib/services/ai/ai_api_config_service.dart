import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiApiConfig {
  const AiApiConfig({
    required this.provider,
    required this.baseUrl,
    required this.model,
    required this.apiKey,
  });

  final String provider;
  final String baseUrl;
  final String model;
  final String apiKey;

  bool get hasRuntimeConfig => baseUrl.trim().isNotEmpty;
  bool get hasApiKey => apiKey.trim().isNotEmpty;
  bool get isConfigured => hasRuntimeConfig || _envBaseUrl.isNotEmpty;

  static const _envBaseUrl = String.fromEnvironment('AI_API_BASE_URL');
}

class AiApiProviderOption {
  const AiApiProviderOption({
    required this.id,
    required this.label,
    required this.defaultModel,
  });

  final String id;
  final String label;
  final String defaultModel;
}

class AiApiConfigService {
  AiApiConfigService({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? preferences,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _preferences = preferences;

  static const apiKeyStorageKey = 'ai_api_key';
  static const providerPreferenceKey = 'ai_api_provider';
  static const baseUrlPreferenceKey = 'ai_api_base_url';
  static const modelPreferenceKey = 'ai_api_model';

  static const defaultProviderId = 'groq';
  static const defaultBaseUrl = String.fromEnvironment('AI_API_BASE_URL');

  static const providerOptions = [
    AiApiProviderOption(
      id: 'groq',
      label: 'Groq',
      defaultModel: 'llama-3.3-70b-versatile',
    ),
    AiApiProviderOption(
      id: 'gemini',
      label: 'Gemini',
      defaultModel: 'gemini-1.5-flash',
    ),
    AiApiProviderOption(
      id: 'github_models',
      label: 'GitHub Models',
      defaultModel: 'openai/gpt-4o-mini',
    ),
    AiApiProviderOption(
      id: 'opencode',
      label: 'OpenCode',
      defaultModel: 'opencode-default',
    ),
  ];

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences? _preferences;

  Future<AiApiConfig> load() async {
    final prefs = await _prefs();
    final savedProvider =
        prefs.getString(providerPreferenceKey) ?? defaultProviderId;
    final provider = providerOptions.any((option) => option.id == savedProvider)
        ? savedProvider
        : defaultProviderId;
    final model =
        prefs.getString(modelPreferenceKey) ??
        defaultModelForProvider(provider);
    final baseUrl = prefs.getString(baseUrlPreferenceKey) ?? defaultBaseUrl;
    final apiKey = await _secureStorage.read(key: apiKeyStorageKey) ?? '';

    return AiApiConfig(
      provider: provider,
      baseUrl: baseUrl,
      model: model,
      apiKey: apiKey,
    );
  }

  Future<void> save({
    required String provider,
    required String baseUrl,
    required String model,
    String? apiKey,
  }) async {
    final prefs = await _prefs();
    await prefs.setString(providerPreferenceKey, provider);
    await prefs.setString(baseUrlPreferenceKey, baseUrl.trim());
    await prefs.setString(modelPreferenceKey, model.trim());

    final key = apiKey?.trim();
    if (key != null && key.isNotEmpty) {
      await _secureStorage.write(key: apiKeyStorageKey, value: key);
    }
  }

  Future<void> clearApiKey() async {
    await _secureStorage.delete(key: apiKeyStorageKey);
  }

  static String defaultModelForProvider(String provider) {
    return providerOptions
        .firstWhere(
          (option) => option.id == provider,
          orElse: () => providerOptions.first,
        )
        .defaultModel;
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ?? SharedPreferences.getInstance();
  }
}
