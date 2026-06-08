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
    required this.models,
  });

  final String id;
  final String label;
  final String defaultModel;
  final List<String> models;
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
      models: [
        'llama-3.3-70b-versatile',
        'llama-3.1-8b-instant',
        'openai/gpt-oss-120b',
        'openai/gpt-oss-20b',
      ],
    ),
    AiApiProviderOption(
      id: 'gemini',
      label: 'Gemini',
      defaultModel: 'gemini-2.5-flash',
      models: ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-1.5-flash'],
    ),
    AiApiProviderOption(
      id: 'github_models',
      label: 'GitHub Models',
      defaultModel: 'openai/gpt-4.1-mini',
      models: [
        'openai/gpt-4.1-mini',
        'openai/gpt-4o-mini',
        'meta/Meta-Llama-3.1-8B-Instruct',
      ],
    ),
    AiApiProviderOption(
      id: 'openrouter',
      label: 'OpenRouter',
      defaultModel: 'poolside/laguna-m.1:free',
      models: [
        'poolside/laguna-m.1:free',
        'poolside/laguna-xs.2:free',
        'z-ai/glm-4.5-air:free',
        'openai/gpt-oss-20b:free',
        'nvidia/nemotron-3-nano-30b-a3b:free',
        'google/gemma-4-31b-it:free',
        'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free',
        'moonshotai/kimi-k2.6:free',
        'nvidia/nemotron-nano-9b-v2:free',
        'nvidia/nemotron-nano-12b-v2-vl:free',
        'google/gemma-4-26b-a4b-it:free',
        'liquid/lfm-2.5-1.2b-thinking:free',
        'liquid/lfm-2.5-1.2b-instruct:free',
        'qwen/qwen3-next-80b-a3b-instruct:free',
        'meta-llama/llama-3.3-70b-instruct:free',
        'cognitivecomputations/dolphin-mistral-24b-venice-edition:free',
        'nousresearch/hermes-3-llama-3.1-405b:free',
        'meta-llama/llama-3.2-3b-instruct:free',
        'qwen/qwen3-coder:free',
        'openrouter/free',
        'openai/gpt-oss-120b:free',
        'nvidia/nemotron-3-super-120b-a12b:free',
      ],
    ),
  ];

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences? _preferences;

  Future<AiApiConfig> load() async {
    final prefs = await _prefs();
    final savedProvider = _normaliseProviderId(
      prefs.getString(providerPreferenceKey) ?? defaultProviderId,
    );
    final provider = providerOptions.any((option) => option.id == savedProvider)
        ? savedProvider
        : defaultProviderId;
    final savedModel = prefs.getString(modelPreferenceKey);
    final model = modelsForProvider(provider).contains(savedModel)
        ? savedModel!
        : defaultModelForProvider(provider);
    final apiKey = await _secureStorage.read(key: apiKeyStorageKey) ?? '';

    return AiApiConfig(
      provider: provider,
      baseUrl: defaultBaseUrl,
      model: model,
      apiKey: apiKey,
    );
  }

  Future<void> save({
    required String provider,
    required String model,
    String? apiKey,
  }) async {
    final prefs = await _prefs();
    final normalisedProvider = _normaliseProviderId(provider);
    await prefs.setString(providerPreferenceKey, normalisedProvider);
    await prefs.setString(
      modelPreferenceKey,
      modelsForProvider(normalisedProvider).contains(model)
          ? model
          : defaultModelForProvider(normalisedProvider),
    );

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

  static List<String> modelsForProvider(String provider) {
    return providerOptions
        .firstWhere(
          (option) => option.id == provider,
          orElse: () => providerOptions.first,
        )
        .models;
  }

  static String _normaliseProviderId(String provider) {
    return provider == 'opencode' ? 'openrouter' : provider;
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ?? SharedPreferences.getInstance();
  }
}
