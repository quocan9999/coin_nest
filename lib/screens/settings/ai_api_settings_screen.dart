import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ai_api_settings_provider.dart';
import '../../services/ai/ai_api_config_service.dart';
import '../../theme/app_theme.dart';

class AiApiSettingsScreen extends StatefulWidget {
  const AiApiSettingsScreen({super.key});

  @override
  State<AiApiSettingsScreen> createState() => _AiApiSettingsScreenState();
}

class _AiApiSettingsScreenState extends State<AiApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  final _apiKeyController = TextEditingController();

  String _provider = AiApiConfigService.defaultProviderId;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<AiApiSettingsProvider>();
      await provider.load();
      if (!mounted) return;
      _applyConfig(provider.config);
    });
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _applyConfig(AiApiConfig config) {
    setState(() {
      _provider = config.provider;
      _baseUrlController.text = config.baseUrl;
      _modelController.text = config.model.isEmpty
          ? AiApiConfigService.defaultModelForProvider(config.provider)
          : config.model;
      _apiKeyController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<AiApiSettingsProvider>().save(
      provider: _provider,
      baseUrl: _baseUrlController.text,
      model: _modelController.text,
      apiKey: _apiKeyController.text,
    );

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    _apiKeyController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã lưu cấu hình AI')));
  }

  Future<void> _clearKey() async {
    await context.read<AiApiSettingsProvider>().clearApiKey();
    if (!mounted) return;
    _apiKeyController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá API key khỏi thiết bị')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = AppTheme.colors(context);
    final provider = context.watch<AiApiSettingsProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: const Text('Cấu hình AI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spacing10),
              children: [
                _StatusCard(provider: provider),
                const SizedBox(height: AppTheme.spacing10),
                _surfaceCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label(context, 'NHÀ CUNG CẤP'),
                        const SizedBox(height: AppTheme.spacing4),
                        _ProviderDropdown(
                          value: _provider,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _provider = value;
                              _modelController.text =
                                  AiApiConfigService.defaultModelForProvider(
                                    value,
                                  );
                            });
                          },
                        ),
                        const SizedBox(height: AppTheme.spacing10),
                        _label(context, 'BASE URL BACKEND'),
                        const SizedBox(height: AppTheme.spacing4),
                        TextFormField(
                          controller: _baseUrlController,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'VD: https://api.example.com',
                          ),
                          validator: _validateBaseUrl,
                        ),
                        const SizedBox(height: AppTheme.spacing10),
                        _label(context, 'MODEL'),
                        const SizedBox(height: AppTheme.spacing4),
                        TextFormField(
                          controller: _modelController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'VD: llama-3.3-70b-versatile',
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: AppTheme.spacing10),
                        _label(context, 'API KEY'),
                        const SizedBox(height: AppTheme.spacing4),
                        TextFormField(
                          controller: _apiKeyController,
                          obscureText: _obscureApiKey,
                          decoration: InputDecoration(
                            hintText: provider.hasApiKey
                                ? 'Đang lưu an toàn trên thiết bị'
                                : 'Nhập API key của provider',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureApiKey
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscureApiKey = !_obscureApiKey,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (provider.hasApiKey &&
                                (value == null || value.trim().isEmpty)) {
                              return null;
                            }
                            return _required(value);
                          },
                        ),
                        const SizedBox(height: AppTheme.spacing12),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: provider.isSaving ? null : _save,
                            child: provider.isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Lưu cấu hình'),
                          ),
                        ),
                        if (provider.hasApiKey) ...[
                          const SizedBox(height: AppTheme.spacing6),
                          TextButton.icon(
                            onPressed: provider.isSaving ? null : _clearKey,
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Xoá API key đã lưu'),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing10),
                _surfaceCard(
                  color: colors.input,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: AppTheme.spacing6),
                      Expanded(
                        child: Text(
                          'API key chỉ được lưu trong kho bảo mật của thiết bị. CoinNest không ghi key vào SQLite, SharedPreferences, log hoặc bản sao lưu cloud.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _surfaceCard({required Widget child, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing10),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: child,
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập thông tin';
    }
    return null;
  }

  String? _validateBaseUrl(String? value) {
    final required = _required(value);
    if (required != null) return required;

    final uri = Uri.tryParse(value!.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Base URL không hợp lệ';
    }
    if (uri.scheme != 'https' &&
        uri.scheme != 'http' &&
        !uri.host.contains('localhost')) {
      return 'Chỉ dùng HTTPS cho API public';
    }
    return null;
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.provider});

  final AiApiSettingsProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = AppTheme.colors(context);
    final isReady =
        provider.config.baseUrl.trim().isNotEmpty && provider.hasApiKey;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing10),
      decoration: BoxDecoration(
        color: isReady ? colors.incomeBg.withAlpha(42) : colors.input,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          Icon(
            isReady ? Icons.check_circle_rounded : Icons.key_off_rounded,
            color: isReady ? colors.income : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppTheme.spacing6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReady ? 'AI đã sẵn sàng' : 'Chưa đủ cấu hình',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isReady
                      ? 'Gợi ý tiết kiệm và Trợ lý tài chính sẽ dùng cấu hình này.'
                      : 'Cần Base URL backend và API key để bật các tính năng AI.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderDropdown extends StatelessWidget {
  const _ProviderDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: colorScheme.surface,
          items: AiApiConfigService.providerOptions
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.id,
                  child: Text(option.label),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
